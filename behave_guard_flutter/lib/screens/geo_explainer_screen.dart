// lib/screens/geo_explainer_screen.dart
// Mirrors Payment.requestGeoAndProceed() / skipGeoAndProceed()
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class GeoExplainerScreen extends StatefulWidget {
  const GeoExplainerScreen({super.key});
  @override
  State<GeoExplainerScreen> createState() => _GeoExplainerScreenState();
}

class _GeoExplainerScreenState extends State<GeoExplainerScreen> {
  bool _loading = false;

  Future<void> _allowAndContinue() async {
    setState(() => _loading = true);
    final state = context.read<AppState>();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ));
      state.pendingTxn['gps'] = {'lat': pos.latitude, 'long': pos.longitude, 'unknown': false};
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Location unavailable — elevated risk')));
      }
      state.pendingTxn['gps'] = {'lat': null, 'long': null, 'unknown': true};
    }
    if (mounted) {
      setState(() => _loading = false);
      Navigator.of(context).pushNamed('/processing');
    }
  }

  void _skip() {
    context.read<AppState>().pendingTxn['gps'] = {'lat': null, 'long': null, 'unknown': true};
    Navigator.of(context).pushNamed('/processing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4E7F0)),
              ),
              child: Column(children: [
                const Text('📍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text('Location helps us protect you',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
                const SizedBox(height: 10),
                const Text(
                  'We check your approximate location at the moment of payment as one fraud signal. It is never shared with the recipient.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF666C85), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const CircularProgressIndicator()
                else ...[
                  _primaryBtn('Allow & Continue', _allowAndContinue),
                  const SizedBox(height: 10),
                  _outlineBtn('Skip (marks as elevated risk)', _skip),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
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
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFE4E7F0)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF666C85), fontWeight: FontWeight.w600, fontSize: 13)),
    ),
  );
}
