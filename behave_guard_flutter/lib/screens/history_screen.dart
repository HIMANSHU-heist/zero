// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/firestore_service.dart';
import '../widgets/risk_tag.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const HistoryScreen({super.key, this.onBack});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    if (state.uid == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final all = await FirestoreService().getTransactions(state.uid!);
      // Filter only maps that have an 'id' field
      final valid = all.where((t) => t['id'] != null).toList();
      if (mounted) setState(() { _txns = valid; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openDetail(Map<String, dynamic> t) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TxnDetailScreen(txn: t),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppState>().uid ?? '';
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 80),
          children: [
            const Text('Transaction History',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1B1E2E))),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4E7F0)),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Text('Error: $_error', style: const TextStyle(color: Color(0xFFD63552)))
                  : _txns.isEmpty
                  ? const Text('No transactions yet.', style: TextStyle(color: Color(0xFF666C85)))
                  : Column(children: _txns.map((t) => _item(t, uid)).toList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(Map<String, dynamic> t, String uid) {
    final outgoing = t['senderUid'] == uid;
    final b = (t['fraudBreakdown'] as Map?)?.cast<String, dynamic>() ?? {};
    final fused = (b['fused'] as num?)?.toDouble();
    final fusedPct = fused != null ? '${(fused * 100).toStringAsFixed(0)}%' : '';

    // Safe timestamp parsing — supports Firestore Timestamp and int ms
    String date = '';
    try {
      final ts = t['timestamp'];
      if (ts != null) {
        DateTime dt;
        if (ts is int) {
          dt = DateTime.fromMillisecondsSinceEpoch(ts);
        } else {
          dt = (ts as dynamic).toDate() as DateTime;
        }
        date = '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}

    final peer = outgoing
        ? (t['receiverUpiId'] ?? t['receiverName'] ?? 'Unknown')
        : (t['senderUpiId'] ?? t['senderName'] ?? 'Unknown');
    final amountStr = '${outgoing ? "-" : "+"}₹${(t['amount'] as num? ?? 0).toStringAsFixed(0)}';

    return InkWell(
      onTap: () => _openDetail(t),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${outgoing ? "To " : "From "}$peer',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${t['status'] ?? 'completed'} · ', style: const TextStyle(color: Color(0xFF666C85), fontSize: 12)),
              RiskTag(t['riskTier'] ?? 'low', extra: fusedPct),
              if (date.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(date, style: const TextStyle(color: Color(0xFF9599AD), fontSize: 11)),
              ],
            ]),
          ])),
          Text(amountStr,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                  color: outgoing ? const Color(0xFF1B1E2E) : const Color(0xFF1A9B6C))),
        ]),
      ),
    );
  }
}

// ── Transaction detail ────────────────────────────────────────────────────

class TxnDetailScreen extends StatelessWidget {
  final Map<String, dynamic> txn;
  const TxnDetailScreen({super.key, required this.txn});

  String _pct(dynamic v) => v == null ? '-' : '${((v as num).toDouble() * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final b = (txn['fraudBreakdown'] as Map?)?.cast<String, dynamic>() ?? {};
    final ctx = (b['ctx'] as Map?)?.cast<String, dynamic>() ?? {};
    final ctxTotal = (ctx['score'] as num?)?.toInt() ??
        ((ctx['s1'] as num? ?? 0) + (ctx['s2'] as num? ?? 0) +
            (ctx['s3'] as num? ?? 0) + (ctx['s4'] as num? ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text('Transaction Detail',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1E2E),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE4E7F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(txn['status'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(width: 8),
              RiskTag(txn['riskTier'] ?? 'low'),
            ]),
            const SizedBox(height: 6),
            Text('₹${txn['amount']} · ${txn['category'] ?? ''}',
                style: const TextStyle(color: Color(0xFF666C85))),
          ])),
          _sectionTitle('Model Scores'),
          _card(Column(children: [
            _scoreRow('P(A) Transaction Pattern', _pct(b['pA']), '(${(b['pA'] as num?)?.toStringAsFixed(3) ?? '-'})'),
            _scoreRow('P(B) Verification/Device', _pct(b['pB']), '(${(b['pB'] as num?)?.toStringAsFixed(3) ?? '-'})'),
            _scoreRow('P(C) Behavioral Deviation', _pct(b['pC']), '(${(b['pC'] as num?)?.toStringAsFixed(3) ?? '-'})'),
          ])),
          _sectionTitle('Context (CTX) Layers'),
          _card(Column(children: [
            _scoreRow('S1 — Unknown device', '${ctx['s1'] ?? '-'}', ''),
            _scoreRow('S2 — Unusual location', '${ctx['s2'] ?? '-'}', ''),
            _scoreRow('S3 — SIM anomaly', '${ctx['s3'] ?? '-'}', ''),
            _scoreRow('S4 — OTP device mismatch', '${ctx['s4'] ?? '-'}', ''),
            const Divider(color: Color(0xFFE4E7F0)),
            _scoreRow('CTX total', '$ctxTotal/4', ''),
          ])),
          _sectionTitle('Fused Risk Score'),
          _card(Column(children: [
            _scoreRow('Fraud Risk Score (fused)', _pct(b['fused']), '(${(b['fused'] as num?)?.toStringAsFixed(3) ?? '-'})'),
          ])),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
    child: Text(t, style: const TextStyle(fontSize: 13, color: Color(0xFF666C85), fontWeight: FontWeight.w700)),
  );

  Widget _scoreRow(String label, String value, String sub) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: Text(label, style: const TextStyle(color: Color(0xFF666C85), fontSize: 13))),
      Row(children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'monospace')),
        if (sub.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(sub, style: const TextStyle(color: Color(0xFF9599AD), fontSize: 11)),
        ],
      ]),
    ]),
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
}
