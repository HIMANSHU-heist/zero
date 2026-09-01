// lib/screens/dashboard_screen.dart
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/firestore_service.dart';
import '../widgets/risk_tag.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _tab = 0;
  List<Map<String, dynamic>> _txns = [];
  bool _loadingTxns = true;
  String? _txnError;
  DateTime? _hiddenAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTxns();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState ls) {
    if (ls == AppLifecycleState.paused) {
      _hiddenAt = DateTime.now();
    } else if (ls == AppLifecycleState.resumed && _hiddenAt != null) {
      final diff = DateTime.now().difference(_hiddenAt!).inMilliseconds;
      final state = context.read<AppState>();
      if (diff > 15000 && (state.userDoc?['pinHash'] as String? ?? '').isNotEmpty) {
        Navigator.of(context).pushNamed('/pin-lock');
      }
      _hiddenAt = null;
    }
  }

  Future<void> _loadTxns() async {
    final state = context.read<AppState>();
    if (state.uid == null) return;
    setState(() { _loadingTxns = true; _txnError = null; });
    try {
      final all = await FirestoreService().getTransactions(state.uid!);
      if (mounted) setState(() { _txns = all.take(5).toList(); _loadingTxns = false; });
    } catch (e) {
      if (mounted) setState(() { _txnError = e.toString(); _loadingTxns = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _tab,
        children: [
          _homeTab(),
          HistoryScreen(onBack: () => setState(() => _tab = 0)),
          ProfileScreen(onLogout: () async {
            await fb_auth.FirebaseAuth.instance.signOut();
            context.read<AppState>().clear();
            if (mounted) Navigator.of(context).pushReplacementNamed('/');
          }),
        ],
      ),
      bottomNavigationBar: _navbar(),
    );
  }

  Widget _navbar() => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE4E7F0)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8)),
      ],
    ),
    child: Row(
      children: [
        _navItem(0, '🏠', 'Home'),
        _navItem(1, '📜', 'History'),
        _navItem(2, '👤', 'Profile'),
      ],
    ),
  );

  Widget _navItem(int idx, String icon, String label) => Expanded(
    child: GestureDetector(
      onTap: () { setState(() => _tab = idx); if (idx == 0) _loadTxns(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _tab == idx ? const Color(0xFF4C5FE0).withValues(alpha: 0.09) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: _tab == idx ? const Color(0xFF4C5FE0) : const Color(0xFF9599AD),
          )),
        ]),
      ),
    ),
  );

  Widget _homeTab() {
    final state = context.watch<AppState>();
    final u = state.userDoc;
    final a = state.accountDoc;
    if (u == null || a == null) return const Center(child: CircularProgressIndicator());
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTxns,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          children: [
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u['mockBankName'] ?? 'Mock Bank',
                  style: const TextStyle(color: Color(0xFF666C85), fontSize: 13)),
              const SizedBox(height: 4),
              Text('₹${_fmt((a['balance'] as num? ?? 0).toDouble())}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1E2E), letterSpacing: -1)),
              Text(u['mockUpiId'] ?? '',
                  style: const TextStyle(color: Color(0xFF666C85), fontSize: 13)),
            ])),
            Row(children: [
              _fab('💸', 'Send Money', () => Navigator.of(context).pushNamed('/send')),
              const SizedBox(width: 10),
              _fab('📷', 'Scan & Pay', () => Navigator.of(context).pushNamed('/send', arguments: 'scan')),
              const SizedBox(width: 10),
              _fab('🔗', 'My QR', () => Navigator.of(context).pushNamed('/myqr')),
            ]),
            const SizedBox(height: 4),
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Recent Transactions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
              const SizedBox(height: 12),
              if (_loadingTxns) const Center(child: CircularProgressIndicator())
              else if (_txnError != null) Text('Error: $_txnError',
                  style: const TextStyle(color: Color(0xFFD63552), fontSize: 13))
              else if (_txns.isEmpty) const Text('No transactions yet.',
                  style: TextStyle(color: Color(0xFF666C85)))
              else ..._txns.map((t) => _txnRow(t, state.uid!)),
            ])),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _txnRow(Map<String, dynamic> t, String uid) {
    final outgoing = t['senderUid'] == uid;
    final b = (t['fraudBreakdown'] as Map?)?.cast<String, dynamic>() ?? {};
    final fused = (b['fused'] as num?)?.toDouble();
    final fusedPct = fused != null ? '${(fused * 100).toStringAsFixed(0)}%' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${outgoing ? "To" : "From"} ${outgoing ? (t['receiverUpiId'] ?? t['receiverName'] ?? 'Unknown') : (t['senderUpiId'] ?? t['senderName'] ?? 'Unknown')}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Row(children: [
            if ((t['category'] ?? '').isNotEmpty) ...[
              Text(t['category'], style: const TextStyle(color: Color(0xFF666C85), fontSize: 12)),
              const Text(' · ', style: TextStyle(color: Color(0xFF666C85), fontSize: 12)),
            ],
            RiskTag(t['riskTier'] ?? 'low', extra: fusedPct),
          ]),
        ])),
        Text('${outgoing ? "-" : "+"}₹${(t['amount'] as num? ?? 0).toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                color: outgoing ? const Color(0xFF1B1E2E) : const Color(0xFF1A9B6C))),
      ]),
    );
  }

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4E7F0)),
      boxShadow: [BoxShadow(color: const Color(0x0A000000), blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _fab(String icon, String label, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E7F0)),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1B1E2E))),
        ]),
      ),
    ),
  );

  String _fmt(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}
