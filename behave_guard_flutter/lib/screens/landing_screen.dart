// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C5FE0), Color(0xFF6C4FD6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4C5FE0).withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 24),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1E2E),
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
                'A mock UPI payment simulator with real,\non-device fraud detection running\non every transaction.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF666C85),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ).copyWith(
                    backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4C5FE0), Color(0xFF6C4FD6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      height: 52,
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Demo build', style: TextStyle(color: Color(0xFF9599AD), fontSize: 11, fontWeight: FontWeight.w600)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('·', style: TextStyle(color: Color(0xFF9599AD))),
                  ),
                  Text('Not a real bank', style: TextStyle(color: Color(0xFF9599AD), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
