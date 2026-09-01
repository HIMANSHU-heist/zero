// lib/screens/debug_screen.dart
// Mirrors the web app's Debug panel — gated behind kDebugMode.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/app_state.dart';
import '../config/constants.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});
  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _deviceIdCtrl = TextEditingController();
  final _gpsCtrl = TextEditingController();
  bool _simAnomaly = false;
  bool _otpMismatch = false;

  @override
  void initState() {
    super.initState();
    final o = context.read<AppState>().debugOverrides;
    _deviceIdCtrl.text = o['deviceId'] ?? '';
    _gpsCtrl.text = o['gps'] ?? '';
    _simAnomaly = o['simAnomaly'] == true;
    _otpMismatch = o['otpMismatch'] == true;
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _gpsCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final overrides = {
      'deviceId': _deviceIdCtrl.text.trim().isEmpty ? null : _deviceIdCtrl.text.trim(),
      'gps': _gpsCtrl.text.trim().isEmpty ? null : _gpsCtrl.text.trim(),
      'simAnomaly': _simAnomaly,
      'otpMismatch': _otpMismatch,
    };
    final state = context.read<AppState>();
    state.debugOverrides = overrides;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bguard_debug_overrides', jsonEncode(overrides));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debug overrides applied')),
      );
    }
  }

  Future<void> _clear() async {
    setState(() {
      _deviceIdCtrl.clear();
      _gpsCtrl.clear();
      _simAnomaly = false;
      _otpMismatch = false;
    });
    final state = context.read<AppState>();
    state.debugOverrides = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bguard_debug_overrides');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debug overrides cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Debug mode disabled'),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ]),
        ),
      );
    }

    final state = context.watch<AppState>();
    final rawOutputs = state.lastRawModelOutputs;
    final o = state.debugOverrides;
    final active = o['deviceId'] != null || o['gps'] != null ||
        o['simAnomaly'] == true || o['otpMismatch'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text('🐞 Debug / Test Mode',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1E2E),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (active)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0x1AD63552),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x3FD63552)),
              ),
              child: const Text(
                '⚠ Overrides ACTIVE — every transaction uses these signals until cleared.',
                style: TextStyle(color: Color(0xFFD63552), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Override device_id (S1)'),
            TextField(controller: _deviceIdCtrl, decoration: _inputDeco('leave blank to use real device_id')),
            const SizedBox(height: 10),
            _label('Override GPS lat,long (S2)'),
            TextField(controller: _gpsCtrl, decoration: _inputDeco('e.g. 19.0760,72.8777')),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Simulate SIM anomaly (S3)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              value: _simAnomaly,
              onChanged: (v) => setState(() => _simAnomaly = v),
              activeColor: const Color(0xFF4C5FE0),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Force OTP-device mismatch (S4)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              value: _otpMismatch,
              onChanged: (v) => setState(() => _otpMismatch = v),
              activeColor: const Color(0xFF4C5FE0),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            _primaryBtn('Apply Overrides', _apply),
            const SizedBox(height: 8),
            _outlineBtn('Clear Overrides', _clear),
          ])),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Last Raw Model Outputs',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
            const SizedBox(height: 10),
            Text(
              rawOutputs != null
                  ? const JsonEncoder.withIndent('  ').convert(rawOutputs)
                  : 'No inference run yet.',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF666C85)),
            ),
          ])),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: Color(0xFF666C85), letterSpacing: 0.5)),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9599AD), fontSize: 13),
    filled: true, fillColor: const Color(0xFFF2F4F9),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE4E7F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE4E7F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4C5FE0))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4E7F0)),
    ),
    child: child,
  );

  Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF4C5FE0), elevation: 0,
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    ),
  );

  Widget _outlineBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFE4E7F0)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF666C85), fontWeight: FontWeight.w600)),
    ),
  );
}
