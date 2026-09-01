// lib/screens/processing_screen.dart
// Mirrors Payment._proceedToFraudCheck(), FraudEngine.runCheck(), Payment.complete()
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_state.dart';
import '../services/fraud_service.dart';
import '../services/firestore_service.dart';
import '../services/device_service.dart';
import '../config/constants.dart';
import '../widgets/risk_tag.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String _title = 'Checking transaction…';
  String _sub = 'Running fraud-detection models';
  bool _showSpinner = true;
  bool _showScores = false;
  Map<String, dynamic>? _breakdown;
  String? _riskTier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final state = context.read<AppState>();
    final fraudSvc = context.read<FraudService>();

    // Populate device IDs on pending txn
    final deviceId = await DeviceService.getOrCreate();
    final overrides = state.debugOverrides;
    final effectiveDeviceId = (kDebugMode && overrides['deviceId'] != null)
        ? overrides['deviceId'] as String
        : deviceId;

    state.pendingTxn['deviceIdInitiated'] = effectiveDeviceId;
    state.pendingTxn['deviceIdOtpVerified'] = (kDebugMode && overrides['otpMismatch'] == true)
        ? '${effectiveDeviceId}_other'
        : effectiveDeviceId;
    state.pendingTxn['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    state.pendingTxn['requestId'] = const Uuid().v4();

    // Apply debug GPS override
    if (kDebugMode && overrides['gps'] != null) {
      final parts = (overrides['gps'] as String).split(',');
      if (parts.length == 2) {
        state.pendingTxn['gps'] = {
          'lat': double.tryParse(parts[0].trim()),
          'long': double.tryParse(parts[1].trim()),
          'unknown': false,
        };
      }
    }

    final started = DateTime.now();
    FraudResult? outcome;

    try {
      outcome = await fraudSvc.runCheck(
        state.pendingTxn,
        state.userDoc!,
        state.accountDoc!,
        state.lastTxnTs,
        debugSimAnomaly: kDebugMode && overrides['simAnomaly'] == true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fraud check failed: $e — blocked for safety.')),
        );
        Navigator.of(context).pushReplacementNamed('/blocked');
      }
      return;
    }

    // Enforce minimum 1.2s animation
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    if (elapsed < 1200) {
      await Future.delayed(Duration(milliseconds: 1200 - elapsed));
    }

    if (outcome == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/blocked');
      return;
    }

    state.lastRawModelOutputs = outcome.raw;
    state.pendingTxn['fraudResult'] = outcome;

    if (mounted) {
      setState(() {
        _showSpinner = false;
        _title = 'Result';
        _sub = '';
        _breakdown = outcome!.breakdown;
        _riskTier = outcome.riskTier;
        _showScores = true;
      });
    }

    // Let user read the score for 1.4s
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    if (outcome.riskTier == 'high') {
      await _logBlocked(state, outcome);
      if (mounted) Navigator.of(context).pushReplacementNamed('/blocked');
    } else {
      await _complete(state, outcome);
    }
  }

  Future<void> _logBlocked(AppState state, FraudResult outcome) async {
    final uid = state.uid!;
    await FirebaseFirestore.instance.collection('transactions').add({
      'requestId': state.pendingTxn['requestId'],
      'senderUid': uid,
      'senderUpiId': state.userDoc!['mockUpiId'],
      'receiverUid': state.pendingRecipient!['uid'],
      'receiverUpiId': state.pendingRecipient!['upiId'],
      'amount': state.pendingTxn['amount'],
      'category': state.pendingTxn['category'],
      'status': 'Blocked',
      'riskTier': 'high',
      'fraudBreakdown': outcome.breakdown,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _complete(AppState state, FraudResult outcome) async {
    final uid = state.uid!;
    final recv = state.pendingRecipient!;
    try {
      await FirestoreService().completePayment(
        requestId: state.pendingTxn['requestId'],
        senderUid: uid,
        senderUpiId: state.userDoc!['mockUpiId'],
        senderBankId: state.userDoc!['mockBankId'],
        receiverUid: recv['uid'],
        receiverUpiId: recv['upiId'],
        receiverBankId: recv['bankId'],
        amount: (state.pendingTxn['amount'] as num).toDouble(),
        category: state.pendingTxn['category'] ?? 'general',
        riskTier: outcome.riskTier,
        fraudBreakdown: outcome.breakdown,
        gps: state.pendingTxn['gps'] as Map<String, dynamic>?,
      );
      final currentBal = state.balance;
      final amount = (state.pendingTxn['amount'] as num? ?? 0).toDouble();
      final newBal = currentBal - amount;
      state.updateBalance(newBal);
      state.lastTxnTs = DateTime.now().millisecondsSinceEpoch;
      if (mounted) Navigator.of(context).pushReplacementNamed('/success');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Transaction failed: $e')));
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    }
  }

  String _pct(dynamic v) => v == null ? '-' : '${((v as num).toDouble() * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final b = _breakdown ?? {};
    final ctx = (b['ctx'] as Map?)?.cast<String, dynamic>() ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Spacer(),
            if (_showSpinner)
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF4C5FE0))),
            const SizedBox(height: 24),
            Text(_title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
            if (_sub.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_sub, style: const TextStyle(color: Color(0xFF666C85))),
            ],
            if (_showScores && _breakdown != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE4E7F0)),
                ),
                child: Column(children: [
                  _scoreRow('Transaction Pattern (Model A)', _pct(b['pA'])),
                  _scoreRow('Device/Verification (Model B)', _pct(b['pB'])),
                  _scoreRow('Behavioral Deviation (Model C)', _pct(b['pC'])),
                  _scoreRow('Context signals', '${ctx['score'] ?? 0}/4'),
                  const Divider(color: Color(0xFFE4E7F0)),
                  _scoreRow('Fraud Risk Score', _pct(b['fused']), bold: true),
                  const SizedBox(height: 8),
                  if (_riskTier != null) RiskTag(_riskTier!),
                ]),
              ),
            ],
            const Spacer(),
          ]),
        ),
      ),
    );
  }

  Widget _scoreRow(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: Text(label,
          style: TextStyle(
              color: bold ? const Color(0xFF1B1E2E) : const Color(0xFF666C85),
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal))),
      Text(value,
          style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 13)),
    ]),
  );
}
