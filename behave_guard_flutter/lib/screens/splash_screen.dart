// lib/screens/splash_screen.dart
// First screen on every cold start. Decides where to route:
//  • Not logged in (first time)  → /landing → /login (Google + Phone)
//  • Logged in, has PIN          → /pin-lock (full-screen PIN entry)
//  • Logged in, no PIN yet       → /dashboard (PIN setup prompt inside dashboard)
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';
import '../services/firestore_service.dart';
import '../services/device_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _anim.forward();
    _decide();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _decide() async {
    // Show splash for at least 1.5s
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final fbUser = fb.FirebaseAuth.instance.currentUser;

    if (fbUser == null) {
      // Not signed in — go to landing (first-time full login)
      Navigator.of(context).pushReplacementNamed('/landing');
      return;
    }

    // Already signed in — restore session
    final state = context.read<AppState>();
    state.uid = fbUser.uid;
    state.userEmail = fbUser.email;

    final prefs = await SharedPreferences.getInstance();
    state.deviceId = await DeviceService.getOrCreate();

    final fs = FirestoreService();
    final userDoc = await fs.getUser(fbUser.uid);

    if (userDoc == null || userDoc['provisioned'] != true) {
      // Account not provisioned yet
      Navigator.of(context).pushReplacementNamed('/provisioning');
      return;
    }

    state.setUserDoc(userDoc);

    final bankId = userDoc['mockBankId'] as String?;
    if (bankId != null) {
      final accountDoc = await fs.getAccount(bankId, fbUser.uid);
      if (accountDoc != null) state.setAccountDoc(accountDoc);
    }

    // Load last txn timestamp for model C
    try {
      final txns = await fs.getTransactions(fbUser.uid);
      if (txns.isNotEmpty) {
        final lastTs = txns.first['timestamp'];
        if (lastTs != null) {
          state.lastTxnTs =
              (lastTs.millisecondsSinceEpoch as int?) ?? lastTs as int?;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    final pinHash = userDoc['pinHash'] as String?;
    if (pinHash != null && pinHash.isNotEmpty) {
      // Has PIN — show PIN lock screen
      Navigator.of(context).pushReplacementNamed('/pin-lock');
    } else {
      // No PIN yet — go to dashboard (will prompt PIN setup)
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1E2E),
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C5FE0), Color(0xFF6C4FD6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4C5FE0).withValues(alpha: 0.45),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Center(
                    child: Text('🛡️', style: TextStyle(fontSize: 44))),
              ),
              const SizedBox(height: 28),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(text: 'BehaveGuard'),
                    TextSpan(
                      text: '·',
                      style: TextStyle(color: Color(0xFF4C5FE0)),
                    ),
                    TextSpan(text: 'UPI'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Fraud detection on every transaction',
                style: TextStyle(color: Color(0xFF9599AD), fontSize: 13),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF4C5FE0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
