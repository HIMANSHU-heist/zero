// lib/screens/login_screen.dart
// Google Sign-In + Phone OTP (linked to Google user, same fix as web app).

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _googleDone = false;
  bool _phoneDone = false;
  bool _otpSent = false;
  bool _loading = false;
  String _error = '';

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInGoogle() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final gs = GoogleSignIn();
      final account = await gs.signIn();
      if (account == null) {
        setState(() { _loading = false; _error = 'Sign-in cancelled.'; });
        return;
      }
      final gAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // If already signed in via redirect/phone, link; otherwise sign in fresh
      UserCredential cred;
      if (FirebaseAuth.instance.currentUser != null) {
        cred = await FirebaseAuth.instance.currentUser!
            .linkWithCredential(credential);
      } else {
        cred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final state = context.read<AppState>();
      state.uid = cred.user!.uid;
      state.userEmail = cred.user!.email;
      setState(() { _googleDone = true; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = 'Google sign-in failed: $e'; });
    }
  }

  Future<void> _sendOtp() async {
    if (!_googleDone) {
      setState(() => _error = 'Complete Google sign-in first.');
      return;
    }
    final phone = _phoneCtrl.text.trim();
    if (!phone.startsWith('+')) {
      setState(() => _error = 'Include country code, e.g. +91XXXXXXXXXX');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        await _linkPhone(cred);
      },
      verificationFailed: (e) {
        setState(() {
          _loading = false;
          _error = 'OTP failed: ${e.message}';
        });
      },
      codeSent: (vId, token) {
        setState(() {
          _verificationId = vId;
          _resendToken = token;
          _otpSent = true;
          _loading = false;
        });
        _showToast('OTP sent');
      },
      codeAutoRetrievalTimeout: (_) {},
      forceResendingToken: _resendToken,
    );
  }

  Future<void> _confirmOtp() async {
    if (_verificationId == null) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await _linkPhone(credential);
    } catch (e) {
      setState(() { _loading = false; _error = 'Invalid OTP: $e'; });
    }
  }

  Future<void> _linkPhone(PhoneAuthCredential credential) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Already linked / credential-already-in-use → treat as success
      const okCodes = [
        'credential-already-in-use',
        'provider-already-linked',
        'account-exists-with-different-credential',
      ];
      if (!okCodes.contains(e.code)) rethrow;
    }
    final state = context.read<AppState>();
    state.uid ??= FirebaseAuth.instance.currentUser!.uid;
    setState(() { _phoneDone = true; _loading = false; });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  Future<void> _continue() async {
    Navigator.of(context).pushReplacementNamed('/provisioning');
  }

  Widget _sectionCard(String number, String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. $title',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Sign in',
                  style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1E2E),
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text(
                'Both Google sign-in and phone verification are required.',
                style: TextStyle(color: Color(0xFF666C85), fontSize: 14),
              ),
              const SizedBox(height: 18),

              // Google
              _sectionCard('1', 'Google Sign-In', Column(children: [
                if (_googleDone)
                  Row(children: [
                    const Icon(Icons.check_circle, color: Color(0xFF1A9B6C), size: 18),
                    const SizedBox(width: 6),
                    Text(context.read<AppState>().userEmail ?? 'Signed in',
                        style: const TextStyle(color: Color(0xFF1A9B6C), fontWeight: FontWeight.w600)),
                  ])
                else
                  _primaryBtn('Continue with Google', _loading ? null : _signInGoogle),
              ])),

              // Phone
              _sectionCard('2', 'Phone Verification', Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_phoneDone) ...[
                    const Row(children: [
                      Icon(Icons.check_circle, color: Color(0xFF1A9B6C), size: 18),
                      SizedBox(width: 6),
                      Text('Verified', style: TextStyle(color: Color(0xFF1A9B6C), fontWeight: FontWeight.w600)),
                    ]),
                  ] else if (!_otpSent) ...[
                    _buildLabel('Phone number (with country code)'),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDeco('+91 9XXXXXXXXX'),
                    ),
                    const SizedBox(height: 10),
                    _secondaryBtn('Send OTP', _loading ? null : _sendOtp),
                  ] else ...[
                    _buildLabel('Enter the 6-digit code'),
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: _inputDeco('123456'),
                    ),
                    const SizedBox(height: 10),
                    _secondaryBtn('Verify OTP', _loading ? null : _confirmOtp),
                  ],
                ],
              )),

              if (_error.isNotEmpty) ...[
                Text(_error,
                    style: const TextStyle(color: Color(0xFFD63552), fontSize: 13)),
                const SizedBox(height: 10),
              ],

              _primaryBtn(
                'Continue',
                (_googleDone && _phoneDone && !_loading) ? _continue : null,
              ),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: Color(0xFF666C85), letterSpacing: 0.5)),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9599AD)),
    filled: true,
    fillColor: const Color(0xFFF2F4F9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE4E7F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE4E7F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF4C5FE0), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    counterText: '',
  );

  Widget _primaryBtn(String label, VoidCallback? onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF4C5FE0),
        disabledBackgroundColor: const Color(0xFF4C5FE0).withOpacity(0.4),
        elevation: 0,
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
    ),
  );

  Widget _secondaryBtn(String label, VoidCallback? onTap) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFE4E7F0)),
        backgroundColor: const Color(0xFFF2F4F9),
      ),
      child: Text(label,
          style: const TextStyle(color: Color(0xFF1B1E2E), fontWeight: FontWeight.w600, fontSize: 15)),
    ),
  );
}
