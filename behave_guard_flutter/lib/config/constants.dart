// lib/config/constants.dart
// Single source of truth for all tuning constants — mirrors the web app exactly.

const String kAppTitle = 'BehaveGuard·UPI';
const double kStartingBalance = 5000.0; // ₹
const double kLocationThresholdKm = 25.0;
const bool kDebugMode = true;

// Fusion weights (same as fusionWeights.js)
const double kAlpha = 0.30;
const double kBeta = 0.30;
const double kGamma = 0.20;
const double kDelta = 0.20;
const double kCtxMax = 4.0;
const double kLowRiskThreshold = 0.30;
const double kHighRiskThreshold = 0.70;

// Aliases used by fraud_service.dart
const double kHighThreshold = kHighRiskThreshold;   // >= 0.70 → blocked
const double kMediumThreshold = kLowRiskThreshold;  // >= 0.30 → medium
const double kHighValueThreshold = 2000.0; // ₹ — same as web app
const double kCtxBoostMax = 0.30; // max CTX additive boost (30%)

const int kPinInactivityMs = 15000;

// Firebase config (same project as web app)
const Map<String, String> kFirebaseConfig = {
  'apiKey': 'AIzaSyDdtK6VuhaTq7yzARgtedPI8eVFQdvCm_0',
  'authDomain': 'bejaveguardctx.firebaseapp.com',
  'projectId': 'bejaveguardctx',
  'storageBucket': 'bejaveguardctx.firebasestorage.app',
  'messagingSenderId': '119017141733',
  'appId': '1:119017141733:web:d1725da1f359b8ada72b0c',
};

// Fallback feature orders when config JSON is absent
const List<String> kFallbackOrderA = [
  'amount', 'oldbalanceOrig', 'newbalanceOrig',
  'oldbalanceDest', 'newbalanceDest', 'balance_ratio',
];

const List<String> kFallbackOrderB = [
  'account_age_days', 'total_transactions_user', 'avg_amount_user', 'amount',
  'avs_match', 'cvv_result', 'three_ds_flag', 'country_mismatch', 'shipping_distance_km',
];

const List<String> kFallbackOrderC = [
  'Amount', 'time_since_last_txn', 'amount_scaled', 'amount_log1p',
  'V1','V2','V3','V4','V5','V6','V7','V8','V9','V10','V11','V12','V13','V14',
  'V15','V16','V17','V18','V19','V20','V21','V22','V23','V24','V25','V26','V27','V28',
];
