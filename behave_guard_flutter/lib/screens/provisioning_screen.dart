// lib/screens/provisioning_screen.dart
// Mirrors App._provisionNewUser() and App._loadAccount() from the web app.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/app_state.dart';
import '../services/device_service.dart';
import '../services/firestore_service.dart';
import '../services/fraud_service.dart';

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({super.key});
  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  String _msg = 'Assigning bank & generating your UPI ID';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _provision());
  }

  Future<void> _provision() async {
    setState(() { _error = null; _msg = 'Setting up your account…'; });
    final state = context.read<AppState>();
    final fs = FirestoreService();
    final fraudService = context.read<FraudService>();

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;
      state.uid = uid;
      state.userEmail = user.email;

      // Device ID
      final deviceId = await DeviceService.getOrCreate();
      state.deviceId = deviceId;

      // Check existing user
      setState(() => _msg = 'Checking account…');
      final existing = await fs.getUser(uid);
      if (existing != null && existing['provisioned'] == true) {
        state.setUserDoc(existing);
        setState(() => _msg = 'Loading your account…');
        final acc = await fs.getAccount(existing['mockBankId'] as String, uid);
        if (acc != null) state.setAccountDoc(acc);
        // Ensure device is known
        final knownDevices =
            List<String>.from((existing['knownDevices'] as List<dynamic>?) ?? []);
        if (!knownDevices.contains(deviceId)) {
          knownDevices.add(deviceId);
          await fs.updateUser(uid, {'knownDevices': knownDevices});
          state.userDoc!['knownDevices'] = knownDevices;
        }
        await _loadModels(fraudService);
        if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
        return;
      }

      // New user provisioning
      setState(() => _msg = 'Assigning your mock bank…');
      final seq = await fs.nextUserSequence();
      final bankIndex = ((seq - 1) % 10) + 1;
      final bankId = 'mock_bank_$bankIndex';
      final bankName = 'Mock Bank $bankIndex';

      setState(() => _msg = 'Generating account & UPI ID…');
      final accountNumber = await fs.uniqueAccountNumber();
      final paddedId = seq.toString().padLeft(6, '0');
      final upiId = await fs.uniqueUpiId(paddedId);
      final qrPayload = 'mockpay://pay?upi=$upiId';

      final now = FieldValue.serverTimestamp();
      final userData = {
        'uid': uid,
        'email': user.email,
        'phone': user.phoneNumber,
        'displayName': user.displayName ?? 'User $paddedId',
        'mockUpiId': upiId,
        'mockBankId': bankId,
        'mockBankName': bankName,
        'mockAccountNumber': accountNumber,
        'knownDevices': [deviceId],
        'pinHash': null,
        'pinSalt': null,
        'faceEmbedding': null,
        'qrPayload': qrPayload,
        'createdAt': now,
      };
      await fs.setUser(uid, userData);
      // Mark user as provisioned
      await fs.updateUser(uid, {'provisioned': true});

      final accountData = {
        'uid': uid,
        'balance': kStartingBalance,
        'avg_amount_30d': 0.0,
        'std_amount_30d': 0.0,
        'total_transactions_user': 0,
        'account_age_days': 0,
        'usual_gps_lat': null,
        'usual_gps_long': null,
        'createdAt': now,
      };
      await fs.setAccount(bankId, uid, accountData);

      final userDocCopy = Map<String, dynamic>.from(userData);
      state.setUserDoc(userDocCopy);
      state.setAccountDoc(accountData);

      await _loadModels(fraudService);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome! Linked to $bankName.')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadModels(FraudService fs) async {
    setState(() => _msg = 'Loading fraud detection models…');
    if (!fs.ready) {
      try {
        await fs.init();
      } catch (e) {
        // Non-fatal: show warning but still proceed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Fraud models failed to load. $e'),
              duration: const Duration(seconds: 5),
              backgroundColor: const Color(0xFFD63552),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              if (_error == null) ...[
                const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF4C5FE0))),
                const SizedBox(height: 28),
                const Text('Setting up your mock bank account…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1E2E))),
                const SizedBox(height: 10),
                Text(_msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF666C85))),
              ] else ...[
                const Text('⚠️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text('Setup failed',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1E2E))),
                const SizedBox(height: 10),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFD63552), fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _provision,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C5FE0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
