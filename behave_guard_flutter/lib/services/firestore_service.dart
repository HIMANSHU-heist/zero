// lib/services/firestore_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── User ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists ? snap.data() : null;
  }

  Future<void> setUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).set(data);

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  // ── Account ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getAccount(
      String bankId, String uid) async {
    final snap =
        await _db.collection('mock_banks').doc(bankId).collection('accounts').doc(uid).get();
    return snap.exists ? snap.data() : null;
  }

  Future<void> setAccount(
      String bankId, String uid, Map<String, dynamic> data) =>
      _db
          .collection('mock_banks')
          .doc(bankId)
          .collection('accounts')
          .doc(uid)
          .set(data);

  // ── Provisioning helpers ──────────────────────────────────────────────────
  Future<int> nextUserSequence() async {
    final ref = _db.collection('counters').doc('userSequence');
    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final current = snap.exists ? (snap.data()!['value'] as int? ?? 0) : 0;
      final next = current + 1;
      tx.set(ref, {'value': next}, SetOptions(merge: true));
      return next;
    });
  }

  Future<String> uniqueAccountNumber() async {
    final rng = Random();
    for (int i = 0; i < 20; i++) {
      final candidate =
          (100000000000 + (rng.nextDouble() * 899999999999).toInt()).toString();
      final q = await _db
          .collection('users')
          .where('mockAccountNumber', isEqualTo: candidate)
          .get();
      if (q.docs.isEmpty) return candidate;
    }
    throw Exception('Could not generate a unique account number');
  }

  Future<String> uniqueUpiId(String paddedId) async {
    final candidate = 'user$paddedId@mock';
    final q = await _db
        .collection('users')
        .where('mockUpiId', isEqualTo: candidate)
        .get();
    if (q.docs.isEmpty) return candidate;
    return 'user$paddedId${Random().nextInt(99)}@mock';
  }

  // ── User search ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> findUser(String query) async {
    for (final field in ['mockUpiId', 'phone', 'uid']) {
      final q = await _db
          .collection('users')
          .where(field, isEqualTo: query)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) return q.docs.first.data();
    }
    return null;
  }

  Future<Map<String, dynamic>?> findUserByUpi(String upi) async {
    final q = await _db
        .collection('users')
        .where('mockUpiId', isEqualTo: upi)
        .limit(1)
        .get();
    return q.docs.isNotEmpty ? q.docs.first.data() : null;
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTransactions(String uid) async {
    final qSend = _db
        .collection('transactions')
        .where('senderUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(30);
    final qRecv = _db
        .collection('transactions')
        .where('receiverUid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(30);

    final results = await Future.wait([qSend.get(), qRecv.get()]);
    final all = [
      ...results[0].docs.map((d) => {'id': d.id, ...d.data()}),
      ...results[1].docs.map((d) => {'id': d.id, ...d.data()}),
    ];
    all.sort((a, b) {
      final at = (a['timestamp'] as Timestamp?)?.seconds ?? 0;
      final bt = (b['timestamp'] as Timestamp?)?.seconds ?? 0;
      return bt.compareTo(at);
    });
    return all;
  }

  Future<void> logBlockedTransaction(Map<String, dynamic> txData) async {
    await _db.collection('transactions').add(txData);
  }

  /// Atomic payment: debit sender, credit receiver, write txn doc
  Future<void> completePayment({
    required String requestId,
    required String senderUid,
    required String senderUpiId,
    required String senderBankId,
    required String receiverUid,
    required String receiverUpiId,
    required String receiverBankId,
    required double amount,
    required String category,
    required String riskTier,
    required Map<String, dynamic> fraudBreakdown,
    required Map<String, dynamic>? gps,
  }) async {
    final senderRef = _db
        .collection('mock_banks')
        .doc(senderBankId)
        .collection('accounts')
        .doc(senderUid);
    final receiverRef = _db
        .collection('mock_banks')
        .doc(receiverBankId)
        .collection('accounts')
        .doc(receiverUid);
    final txnRef = _db.collection('transactions').doc(requestId);

    await _db.runTransaction((tx) async {
      final existing = await tx.get(txnRef);
      if (existing.exists) return; // idempotency guard

      final senderSnap = await tx.get(senderRef);
      final receiverSnap = await tx.get(receiverRef);
      final senderData = senderSnap.data()!;
      final receiverData = receiverSnap.data()!;
      final senderBalance = (senderData['balance'] as num).toDouble();
      final receiverBalance =
          (receiverData['balance'] as num?)?.toDouble() ?? 0.0;

      if (senderBalance < amount) throw Exception('Insufficient balance');

      final n = ((senderData['total_transactions_user'] as int?) ?? 0) + 1;
      final prevAvg = (senderData['avg_amount_30d'] as num?)?.toDouble() ?? 0.0;
      final newAvg = prevAvg + (amount - prevAvg) / n;

      final unknownGps = gps == null || (gps['unknown'] as bool? ?? true);

      tx.update(senderRef, {
        'balance': senderBalance - amount,
        'total_transactions_user': n,
        'avg_amount_30d': newAvg,
        'usual_gps_lat': unknownGps
            ? senderData['usual_gps_lat']
            : gps!['lat'],
        'usual_gps_long': unknownGps
            ? senderData['usual_gps_long']
            : gps!['long'],
      });
      tx.update(receiverRef, {'balance': receiverBalance + amount});
      tx.set(txnRef, {
        'requestId': requestId,
        'senderUid': senderUid,
        'senderUpiId': senderUpiId,
        'receiverUid': receiverUid,
        'receiverUpiId': receiverUpiId,
        'amount': amount,
        'category': category,
        'status': 'Completed',
        'riskTier': riskTier,
        'fraudBreakdown': fraudBreakdown,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
