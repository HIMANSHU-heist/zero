// lib/screens/result_screens.dart
// Success and Blocked screens
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final recv = state.pendingRecipient;
    final amount = state.pendingTxn['amount'];
    final detail = recv != null && amount != null
        ? '₹$amount sent to ${recv['name']} (${recv['upiId']})'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('✅', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              const Text('Payment Successful',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
              const SizedBox(height: 10),
              Text(detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF666C85), fontSize: 15)),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: const Color(0xFF4C5FE0), elevation: 0,
                  ),
                  child: const Text('Done',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🚫', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              const Text('Transaction Blocked',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
              const SizedBox(height: 10),
              const Text(
                'This transaction was flagged as high risk and has been blocked for your protection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF666C85), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFFE4E7F0)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(color: Color(0xFF666C85), fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
