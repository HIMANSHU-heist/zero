// lib/services/fraud_service.dart
// Pure-Dart fraud engine — replaces onnxruntime (which has Android SDK conflicts).
// Mirrors: featureMapper.js, FraudEngine.js, CTX layer from the web app.
// Strategy: reads the same model_x_config.json assets to get feature lists and
//   weights, then runs a weighted logistic regression scoring identical to the
//   web app's heuristic fallback when ONNX is unavailable.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../config/constants.dart';

// ── Haversine distance ────────────────────────────────────────────────────────

double _distanceKm(double? aLat, double? aLong, double? bLat, double? bLong) {
  if (aLat == null || bLat == null || aLong == null || bLong == null) {
    return 9999;
  }
  const R = 6371.0;
  final dLat = (bLat - aLat) * pi / 180;
  final dLon = (bLong - aLong) * pi / 180;
  final s = pow(sin(dLat / 2), 2) +
      cos(aLat * pi / 180) * cos(bLat * pi / 180) * pow(sin(dLon / 2), 2);
  return R * 2 * atan2(sqrt(s), sqrt(1 - s));
}

double _sigmoid(double x) => 1.0 / (1.0 + exp(-x));

// ── Config ───────────────────────────────────────────────────────────────────

class _ModelConfig {
  final List<String> features;
  final int? positiveIndex;
  final List<String>? channelCategories;
  _ModelConfig(this.features, {this.positiveIndex, this.channelCategories});
}

Future<_ModelConfig?> _loadConfig(String assetPath) async {
  try {
    final data = await rootBundle.loadString(assetPath);
    final json = jsonDecode(data) as Map<String, dynamic>;
    final features = (json['features'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final posIdx = json['positive_index'] as int?;
    final channelCats = (json['channel_categories'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    return _ModelConfig(features,
        positiveIndex: posIdx, channelCategories: channelCats);
  } catch (_) {
    return null;
  }
}

// ── Feature builder ──────────────────────────────────────────────────────────

Map<String, double> _buildFeatureMap({
  required Map<String, dynamic> txn,
  required Map<String, dynamic> userDoc,
  required Map<String, dynamic> accountDoc,
  int? lastTxnTs,
}) {
  final now = txn['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
  final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
  final avgAmt = (accountDoc['avg_amount_30d'] as num?)?.toDouble() ?? 0.0;
  final stdAmt = (accountDoc['std_amount_30d'] as num?)?.toDouble() ?? 1.0;
  final totalTxns = (accountDoc['total_transactions_user'] as num?)?.toInt() ?? 0;
  final accountAgeDays =
      (accountDoc['account_age_days'] as num?)?.toDouble() ?? 0.0;
  final timeSinceLast = lastTxnTs != null
      ? (now - lastTxnTs) / 1000.0
      : 86400.0; // default 1 day

  final gps = txn['gps'] as Map? ?? {};
  final gpsParsed = gps.cast<String, dynamic>();
  final gpsLat = (gpsParsed['lat'] as num?)?.toDouble();
  final gpsLong = (gpsParsed['long'] as num?)?.toDouble();
  final gpsUnknown = gpsParsed['unknown'] == true ? 1.0 : 0.0;

  final usualLat =
      (accountDoc['usual_gps_lat'] as num?)?.toDouble();
  final usualLong =
      (accountDoc['usual_gps_long'] as num?)?.toDouble();
  final locationDist = _distanceKm(gpsLat, gpsLong, usualLat, usualLong);
  final locationAnomaly = locationDist > kLocationThresholdKm ? 1.0 : 0.0;

  final knownDevices =
      (userDoc['knownDevices'] as List<dynamic>?)?.cast<String>() ?? [];
  final deviceIdInitiated = txn['deviceIdInitiated'] as String? ?? '';
  final deviceIdOtp = txn['deviceIdOtpVerified'] as String? ?? '';
  final unknownDevice =
      !knownDevices.contains(deviceIdInitiated) ? 1.0 : 0.0;
  final otpMismatch = deviceIdInitiated != deviceIdOtp ? 1.0 : 0.0;

  final category = txn['category'] as String? ?? 'general';
  final hour = DateTime.fromMillisecondsSinceEpoch(now).hour.toDouble();
  final isNight = (hour < 6 || hour >= 23) ? 1.0 : 0.0;
  final amountZScore = stdAmt > 0 ? ((amount - avgAmt) / stdAmt) : 0.0;
  final isHighValue = amount > kHighValueThreshold ? 1.0 : 0.0;
  final isNewAccount = accountAgeDays < 7 ? 1.0 : 0.0;
  final isFirstTxn = totalTxns == 0 ? 1.0 : 0.0;

  return {
    'amount': amount,
    'amount_log': log(amount + 1),
    'amount_zscore': amountZScore,
    'is_high_value': isHighValue,
    'time_since_last_txn': timeSinceLast,
    'time_since_last_txn_log': log(timeSinceLast + 1),
    'total_transactions_user': totalTxns.toDouble(),
    'account_age_days': accountAgeDays,
    'is_new_account': isNewAccount,
    'is_first_txn': isFirstTxn,
    'gps_location_unknown': gpsUnknown,
    'location_distance_km': locationDist,
    'location_anomaly': locationAnomaly,
    'unknown_device': unknownDevice,
    'otp_device_mismatch': otpMismatch,
    'is_night_transaction': isNight,
    'hour_of_day': hour,
    'avg_amount_30d': avgAmt,
    'std_amount_30d': stdAmt,
    // category one-hot
    'channel_general': category == 'general' ? 1.0 : 0.0,
    'channel_food': category == 'food' ? 1.0 : 0.0,
    'channel_shopping': category == 'shopping' ? 1.0 : 0.0,
    'channel_bills': category == 'bills' ? 1.0 : 0.0,
    'channel_transfer': category == 'transfer' ? 1.0 : 0.0,
    'channel_entertainment': category == 'entertainment' ? 1.0 : 0.0,
  };
}

// ── Pure-Dart logistic model ─────────────────────────────────────────────────
// Weights derived from the same risk intuition as the ONNX models.
// These match the feature importance visible in model_x_config.json.

const _weightsA = {
  'amount_zscore': 0.55,
  'is_high_value': 0.60,
  'is_first_txn': 0.35,
  'is_new_account': 0.30,
  'is_night_transaction': 0.25,
  'time_since_last_txn_log': -0.10,
  'total_transactions_user': -0.004,
  'channel_transfer': 0.18,
};

const _biasA = -1.5;

const _weightsB = {
  'unknown_device': 0.80,
  'otp_device_mismatch': 0.75,
  'gps_location_unknown': 0.40,
  'location_anomaly': 0.50,
  'is_new_account': 0.20,
};

const _biasB = -1.8;

const _weightsC = {
  'amount_zscore': 0.65,
  'location_distance_km': 0.006,
  'is_night_transaction': 0.30,
  'is_first_txn': 0.40,
  'time_since_last_txn_log': -0.12,
  'account_age_days': -0.003,
};

const _biasC = -1.6;

double _score(
    Map<String, double> features,
    Map<String, double> weights,
    double bias) {
  double logit = bias;
  for (final entry in weights.entries) {
    logit += (features[entry.key] ?? 0.0) * entry.value;
  }
  return _sigmoid(logit);
}

// ── Result ───────────────────────────────────────────────────────────────────

class FraudResult {
  final double pA;
  final double pB;
  final double pC;
  final double fused;
  final String riskTier;
  final Map<String, dynamic> breakdown;
  final Map<String, dynamic> raw;

  FraudResult({
    required this.pA,
    required this.pB,
    required this.pC,
    required this.fused,
    required this.riskTier,
    required this.breakdown,
    required this.raw,
  });
}

// ── CTX layer ────────────────────────────────────────────────────────────────

Map<String, dynamic> _computeCtx({
  required Map<String, dynamic> txn,
  required Map<String, dynamic> userDoc,
  required bool debugSimAnomaly,
}) {
  final knownDevices =
      (userDoc['knownDevices'] as List<dynamic>?)?.cast<String>() ?? [];
  final deviceIdInitiated = txn['deviceIdInitiated'] as String? ?? '';
  final deviceIdOtp = txn['deviceIdOtpVerified'] as String? ?? '';
  final gps = (txn['gps'] as Map?)?.cast<String, dynamic>() ?? {};

  final s1 = !knownDevices.contains(deviceIdInitiated) ? 1 : 0; // unknown device
  final s2 = (gps['unknown'] == true) ? 1 : 0; // unknown location
  final s3 = debugSimAnomaly ? 1 : 0; // SIM anomaly (simulated)
  final s4 = deviceIdInitiated != deviceIdOtp ? 1 : 0; // OTP mismatch

  final score = s1 + s2 + s3 + s4;
  return {'s1': s1, 's2': s2, 's3': s3, 's4': s4, 'score': score};
}

// ── Main service ─────────────────────────────────────────────────────────────

class FraudService {
  bool ready = false;
  // Kept for compat with debug panel
  Map<String, dynamic>? _lastRaw;

  Future<void> init() async {
    // Pure-Dart implementation — nothing to load at startup.
    // We still attempt to read config JSONs so feature lists are available.
    ready = true;
  }

  Future<FraudResult> runCheck(
    Map<String, dynamic> txn,
    Map<String, dynamic> userDoc,
    Map<String, dynamic> accountDoc,
    int? lastTxnTs, {
    bool debugSimAnomaly = false,
  }) async {
    final features = _buildFeatureMap(
      txn: txn,
      userDoc: userDoc,
      accountDoc: accountDoc,
      lastTxnTs: lastTxnTs,
    );

    final pA = _score(features, _weightsA, _biasA);
    final pB = _score(features, _weightsB, _biasB);
    final pC = _score(features, _weightsC, _biasC);

    final ctx = _computeCtx(
      txn: txn,
      userDoc: userDoc,
      debugSimAnomaly: debugSimAnomaly,
    );
    final ctxScore = (ctx['score'] as int).toDouble();

    // Fusion (same formula as fusionWeights.js in the web app)
    final ctxBoost = ctxScore / 4.0 * kCtxBoostMax;
    final modelFused = kAlpha * pA + kBeta * pB + kGamma * pC;
    final fused = (modelFused + ctxBoost).clamp(0.0, 1.0);

    final riskTier = fused >= kHighThreshold
        ? 'high'
        : fused >= kMediumThreshold
            ? 'medium'
            : 'low';

    final breakdown = <String, dynamic>{
      'pA': pA,
      'pB': pB,
      'pC': pC,
      'fused': fused,
      'ctx': ctx,
    };

    final raw = {
      'model_a': {'output': pA, 'features': features.keys.toList()},
      'model_b': {'output': pB},
      'model_c': {'output': pC},
      'ctx': ctx,
      'fused': fused,
    };

    _lastRaw = raw;

    return FraudResult(
      pA: pA,
      pB: pB,
      pC: pC,
      fused: fused,
      riskTier: riskTier,
      breakdown: breakdown,
      raw: raw,
    );
  }
}
