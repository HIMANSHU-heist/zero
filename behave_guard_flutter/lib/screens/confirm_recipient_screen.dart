// lib/screens/confirm_recipient_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class ConfirmRecipientScreen extends StatelessWidget {
  const ConfirmRecipientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final r = state.pendingRecipient ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text('Confirm Recipient',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1E2E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E7F0)),
            ),
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C5FE0).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('👤', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(height: 16),
              Text(r['name'] ?? '-',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
              const SizedBox(height: 4),
              Text(r['upiId'] ?? '-',
                  style: const TextStyle(color: Color(0xFF666C85), fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 16),
          _primaryBtn('Proceed', () => Navigator.of(context).pushNamed('/amount')),
          const SizedBox(height: 10),
          _outlineBtn('Back', () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF4C5FE0),
        elevation: 0,
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
    ),
  );

  Widget _outlineBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: Color(0xFFE4E7F0)),
      ),
      child: Text(label,
          style: const TextStyle(color: Color(0xFF666C85), fontWeight: FontWeight.w600, fontSize: 15)),
    ),
  );
}
