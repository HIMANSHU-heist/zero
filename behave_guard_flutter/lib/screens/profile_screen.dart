// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/pin_modal.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final u = state.userDoc;
    final a = state.accountDoc;
    if (u == null || a == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 80),
        children: [
          const Text('Profile',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B1E2E))),
          const SizedBox(height: 14),

          // Account info card
          _card(Column(children: [
            _row('Name', u['displayName'] as String? ?? '-'),
            _row('UPI ID', u['mockUpiId'] as String? ?? '-'),
            _row('Phone', u['phone'] as String? ?? '-'),
            _row('Email', u['email'] as String? ?? '-'),
            _row('Bank', u['mockBankName'] as String? ?? '-'),
            _row('Account No.', u['mockAccountNumber'] as String? ?? '-'),
            _row('Balance',
                '₹${(a['balance'] as num? ?? 0).toStringAsFixed(2)}'),
            _row('Known Devices',
                '${(u['knownDevices'] as List<dynamic>?)?.length ?? 1}'),
          ])),

          // PIN lock card
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('PIN Lock',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1E2E))),
              const SizedBox(width: 8),
              if (state.hasPin)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x1A1A9B6C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Set',
                      style: TextStyle(
                          color: Color(0xFF1A9B6C),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 6),
            const Text(
                'Protects your account when the app is backgrounded for 15+ seconds.',
                style: TextStyle(color: Color(0xFF666C85), fontSize: 13)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await PinModal.show(context, PinMode.setup);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFE4E7F0)),
                  backgroundColor: const Color(0xFFF2F4F9),
                ),
                child: Text(
                  state.hasPin ? 'Change PIN' : 'Set PIN',
                  style: const TextStyle(
                      color: Color(0xFF1B1E2E), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ])),

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0x1AD63552),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                side: const BorderSide(color: Color(0x3FD63552)),
              ),
              child: const Text('Log Out',
                  style: TextStyle(
                      color: Color(0xFFD63552),
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF666C85), fontSize: 13)),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ]),
      );

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E7F0)),
          boxShadow: [
            BoxShadow(
                color: const Color(0x0A000000),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );
}
