// lib/screens/myqr_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/app_state.dart';

class MyQrScreen extends StatelessWidget {
  const MyQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final upiId = state.userDoc?['mockUpiId'] ?? '';
    final payload = state.userDoc?['qrPayload'] ?? 'mockpay://pay?upi=$upiId';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text('My QR Code',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1E2E),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE4E7F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(children: [
                  QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 260,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(upiId,
                      style: const TextStyle(
                          color: Color(0xFF666C85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
