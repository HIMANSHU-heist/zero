// lib/screens/amount_screen.dart
// Mirrors Payment.confirmAmount() and _requirePinThenProceed() from web app.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/pin_modal.dart';

class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key});
  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final _amountCtrl = TextEditingController();
  String _category = 'general';

  final _categories = ['general', 'food', 'shopping', 'bills', 'transfer', 'entertainment'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final state = context.read<AppState>();
    state.pendingTxn['amount'] = amount;
    state.pendingTxn['category'] = _category;

    // Require PIN before proceeding
    if (state.userDoc?['pinHash'] == null) {
      // Setup PIN first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set a PIN to authorize this payment')),
      );
      final ok = await PinModal.show(context, PinMode.setup);
      if (!ok || !mounted) return;
    } else {
      final ok = await PinModal.show(context, PinMode.payment);
      if (!ok || !mounted) return;
    }
    Navigator.of(context).pushNamed('/geo-explainer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text('Enter Amount',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1E2E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4E7F0)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Amount (₹)'),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                decoration: _inputDeco('0'),
              ),
              const SizedBox(height: 12),
              _label('Category (optional)'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDeco(''),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c[0].toUpperCase() + c.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'general'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _primaryBtn('Continue', _continue),
          const SizedBox(height: 10),
          _outlineBtn('Cancel', () => Navigator.of(context).pushReplacementNamed('/dashboard')),
        ]),
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
    filled: true, fillColor: const Color(0xFFF2F4F9),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE4E7F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE4E7F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4C5FE0), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );

  Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF4C5FE0), elevation: 0,
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
