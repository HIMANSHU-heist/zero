// lib/screens/send_screen.dart
// Handles UPI ID search and QR scanning, mirrors Send module from web app.
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/firestore_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});
  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  String? _searchError;
  bool _scanning = false;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'scan') setState(() => _scanning = true);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final val = _searchCtrl.text.trim();
    if (val.isEmpty) return;
    setState(() { _searching = true; _searchError = null; });
    try {
      final found = await FirestoreService().findUser(val);
      final uid = context.read<AppState>().uid;
      if (!mounted) return;
      if (found == null) {
        setState(() { _searching = false; _searchError = 'No user found.'; });
        return;
      }
      if (found['uid'] == uid) {
        setState(() { _searching = false; _searchError = "You can't pay yourself."; });
        return;
      }
      setState(() => _searching = false);
      _goConfirm(found);
    } catch (e) {
      setState(() { _searching = false; _searchError = e.toString(); });
    }
  }

  void _goConfirm(Map<String, dynamic> found) {
    context.read<AppState>().pendingRecipient = {
      'uid': found['uid'],
      'upiId': found['mockUpiId'],
      'name': found['displayName'],
      'bankId': found['mockBankId'],
    };
    Navigator.of(context).pushNamed('/confirm-recipient');
  }

  Future<void> _handleQrPayload(String payload) async {
    if (_scanned) return;
    if (!payload.startsWith('mockpay://')) return;
    setState(() => _scanned = true);
    try {
      final uri = Uri.parse(payload.replaceFirst('mockpay://pay', 'https://x'));
      final upi = uri.queryParameters['upi'];
      if (upi == null) { _toast('Invalid QR'); return; }
      final found = await FirestoreService().findUserByUpi(upi);
      if (!mounted) return;
      if (found == null) { _toast('QR user not found'); setState(() => _scanned = false); return; }
      if (found['uid'] == context.read<AppState>().uid) {
        _toast("You can't pay yourself"); setState(() => _scanned = false); return;
      }
      setState(() => _scanning = false);
      _goConfirm(found);
    } catch (e) {
      _toast('Could not parse QR');
      setState(() => _scanned = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text('Send Money',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1E2E),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE4E7F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          // Search card
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Search by UPI ID / phone / user ID',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFF666C85), letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: _inputDeco('e.g. user000004@mock'),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 10),
            _outlineBtn('Search', _searching ? null : _search),
            if (_searching) const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            if (_searchError != null) Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_searchError!, style: const TextStyle(color: Color(0xFFD63552), fontSize: 13)),
            ),
          ])),

          // QR Scan card
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Scan QR Code',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
            const SizedBox(height: 12),
            if (_scanning) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 240,
                  child: MobileScanner(
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) {
                        _handleQrPayload(barcode!.rawValue!);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _outlineBtn('Stop Scanning', () => setState(() => _scanning = false)),
            ] else ...[
              _outlineBtn('Open Camera to Scan', () => setState(() { _scanning = true; _scanned = false; })),
            ],
          ])),
        ]),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4E7F0)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9599AD)),
    filled: true, fillColor: const Color(0xFFF2F4F9),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE4E7F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE4E7F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4C5FE0), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _outlineBtn(String label, VoidCallback? onTap) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFE4E7F0)),
        backgroundColor: const Color(0xFFF2F4F9),
      ),
      child: Text(label,
          style: const TextStyle(color: Color(0xFF1B1E2E), fontWeight: FontWeight.w600)),
    ),
  );
}
