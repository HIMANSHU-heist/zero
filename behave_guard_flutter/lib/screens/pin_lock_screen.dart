// lib/screens/pin_lock_screen.dart
// Full-screen PIN entry shown when the app resumes from background
// or on cold-start for an already-logged-in user.
// Cannot be dismissed without correct PIN.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/app_state.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});
  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  final List<int> _digits = [];
  bool _error = false;
  late AnimationController _shake;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(_shake);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _tap(int d) {
    if (_digits.length >= 6) return;
    setState(() { _digits.add(d); _error = false; });
    if (_digits.length == 6) _verify();
  }

  void _del() {
    if (_digits.isEmpty) return;
    setState(() { _digits.removeLast(); _error = false; });
  }

  Future<void> _verify() async {
    final state = context.read<AppState>();
    final pinHash = state.userDoc?['pinHash'] as String?;
    if (pinHash == null) {
      // No PIN set — go straight to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
      return;
    }
    final salt = state.userDoc?['pinSalt'] as String? ?? '';
    final input = _digits.join();
    final hash = sha256.convert(utf8.encode(salt + input)).toString();
    if (hash == pinHash) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      await _shake.forward(from: 0);
      setState(() { _digits.clear(); _error = true; });
    }
  }

  Future<void> _signOut() async {
    await fb.FirebaseAuth.instance.signOut();
    if (mounted) {
      context.read<AppState>().clear();
      Navigator.of(context).pushReplacementNamed('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1E2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C5FE0), Color(0xFF6C4FD6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4C5FE0).withValues(alpha: 0.35),
                      blurRadius: 20, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 34))),
              ),
              const SizedBox(height: 20),
              const Text('Welcome back',
                  style: TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Enter your PIN to continue',
                  style: TextStyle(color: Color(0xFF9599AD), fontSize: 14)),
              const SizedBox(height: 40),

              // Dots
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final filled = i < _digits.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error
                            ? const Color(0xFFD63552)
                            : filled
                                ? const Color(0xFF4C5FE0)
                                : Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: _error
                              ? const Color(0xFFD63552)
                              : filled
                                  ? const Color(0xFF4C5FE0)
                                  : Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_error) ...[
                const SizedBox(height: 12),
                const Text('Incorrect PIN',
                    style: TextStyle(color: Color(0xFFD63552), fontSize: 13)),
              ],

              const Spacer(),

              // Numpad
              _numpad(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _signOut,
                child: const Text('Sign out & switch account',
                    style: TextStyle(color: Color(0xFF666C85), fontSize: 13)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numpad() {
    return Column(
      children: [
        _row([1, 2, 3]),
        const SizedBox(height: 12),
        _row([4, 5, 6]),
        const SizedBox(height: 12),
        _row([7, 8, 9]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _emptyKey(),
            const SizedBox(width: 12),
            _numKey(0),
            const SizedBox(width: 12),
            _delKey(),
          ],
        ),
      ],
    );
  }

  Widget _row(List<int> nums) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _numKey(nums[0]),
      const SizedBox(width: 12),
      _numKey(nums[1]),
      const SizedBox(width: 12),
      _numKey(nums[2]),
    ],
  );

  Widget _numKey(int d) => GestureDetector(
    onTap: () => _tap(d),
    child: Container(
      width: 76, height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Text('$d',
            style: const TextStyle(color: Colors.white, fontSize: 24,
                fontWeight: FontWeight.w500)),
      ),
    ),
  );

  Widget _delKey() => GestureDetector(
    onTap: _del,
    child: Container(
      width: 76, height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
      child: const Center(
        child: Icon(Icons.backspace_outlined, color: Colors.white70, size: 22),
      ),
    ),
  );

  Widget _emptyKey() => const SizedBox(width: 76, height: 76);
}
