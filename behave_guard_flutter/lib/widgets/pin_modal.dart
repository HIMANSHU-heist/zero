// lib/widgets/pin_modal.dart
// Bottom-sheet PIN entry for setup & payment authorization.
// Uses 6-digit PIN with SHA-256(salt + pin) — same as PinLockScreen.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

enum PinMode { setup, verify, payment }

class PinModal extends StatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const PinModal({
    super.key,
    required this.mode,
    this.onSuccess,
    this.onCancel,
  });

  static Future<bool> show(BuildContext context, PinMode mode,
      {VoidCallback? onSuccess}) {
    return showModalBottomSheet<bool>(
      context: context,
      isDismissible: mode != PinMode.verify,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PinModal(
        mode: mode,
        onSuccess: onSuccess,
        onCancel: () => Navigator.of(context).pop(false),
      ),
    ).then((v) => v ?? false);
  }

  @override
  State<PinModal> createState() => _PinModalState();
}

class _PinModalState extends State<PinModal>
    with SingleTickerProviderStateMixin {
  final List<int> _digits = [];
  String _error = '';
  bool _saving = false;
  late AnimationController _shake;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shake);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case PinMode.setup:
        return 'Set a 6-digit PIN';
      case PinMode.payment:
        return 'Enter PIN to authorize';
      case PinMode.verify:
        return 'Enter PIN to unlock';
    }
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode(salt + pin)).toString();

  void _tap(int d) {
    if (_digits.length >= 6 || _saving) return;
    setState(() { _digits.add(d); _error = ''; });
    if (_digits.length == 6) _submit();
  }

  void _del() {
    if (_digits.isEmpty || _saving) return;
    setState(() { _digits.removeLast(); _error = ''; });
  }

  Future<void> _submit() async {
    if (_saving) return;
    final pin = _digits.join();
    final state = context.read<AppState>();
    final uid = state.uid;
    if (uid == null) return;

    setState(() => _saving = true);

    if (widget.mode == PinMode.setup) {
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final hash = _hash(salt, pin);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'pinHash': hash, 'pinSalt': salt});
        state.userDoc!['pinHash'] = hash;
        state.userDoc!['pinSalt'] = salt;
        state.notify();
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN saved!')),
          );
        }
        widget.onSuccess?.call();
      } catch (e) {
        if (mounted) setState(() { _saving = false; _error = 'Failed to save PIN'; _digits.clear(); });
      }
    } else {
      final salt = state.userDoc?['pinSalt'] as String? ?? '';
      final stored = state.userDoc?['pinHash'] as String? ?? '';
      final hash = _hash(salt, pin);
      if (hash == stored) {
        if (mounted) Navigator.of(context).pop(true);
        widget.onSuccess?.call();
      } else {
        await _shake.forward(from: 0);
        if (mounted) {
          setState(() {
            _saving = false;
            _digits.clear();
            _error = 'Incorrect PIN';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Push up when keyboard shows (not needed for numpad, but safe)
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E7F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(_title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1E2E))),
            const SizedBox(height: 22),

            // Dots (6)
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0), child: child),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _digits.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 13, height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error.isNotEmpty
                          ? const Color(0xFFD63552)
                          : filled
                              ? const Color(0xFF4C5FE0)
                              : const Color(0xFFE4E7F0),
                    ),
                  );
                }),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error,
                  style: const TextStyle(
                      color: Color(0xFFD63552), fontSize: 13)),
            ],

            const SizedBox(height: 20),

            // Numpad
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                '1','2','3','4','5','6','7','8','9','','0','⌫',
              ].map((k) {
                if (k.isEmpty) return const SizedBox();
                return Material(
                  color: k == '⌫'
                      ? const Color(0xFFF2F4F9)
                      : const Color(0xFFF2F4F9),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: k == '⌫'
                        ? _del
                        : () => _tap(int.parse(k)),
                    child: Center(
                      child: k == '⌫'
                          ? const Icon(Icons.backspace_outlined,
                              color: Color(0xFF1B1E2E), size: 20)
                          : Text(k,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B1E2E))),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (widget.mode != PinMode.verify)
              TextButton(
                onPressed: _saving
                    ? null
                    : widget.onCancel ??
                        () => Navigator.of(context).pop(false),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF666C85))),
              ),
          ],
        ),
      ),
    );
  }
}
