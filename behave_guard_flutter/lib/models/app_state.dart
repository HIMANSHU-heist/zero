// lib/models/app_state.dart
import 'package:flutter/foundation.dart';

/// Global app state — equivalent to the `State` object in the web app.
class AppState extends ChangeNotifier {
  // Auth
  String? uid;
  String? userEmail;
  bool phoneVerified = false;

  // User & account documents from Firestore
  Map<String, dynamic>? userDoc;
  Map<String, dynamic>? accountDoc;

  // Device
  String? deviceId;

  // Payment flow
  Map<String, dynamic>? pendingRecipient; // {uid, upiId, name, bankId}
  Map<String, dynamic> pendingTxn = {};

  // Last model outputs for debug panel
  Map<String, dynamic>? lastRawModelOutputs;

  // Debug overrides (persisted via SharedPreferences)
  Map<String, dynamic> debugOverrides = {};

  // Timestamp of last transaction (for time_since_last_txn in model C)
  int? lastTxnTs;

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Safe balance getter — never throws
  double get balance =>
      (accountDoc?['balance'] as num? ?? 0).toDouble();

  /// Safe UPI ID getter
  String get upiId => userDoc?['mockUpiId'] as String? ?? '';

  /// Safe display name
  String get displayName => userDoc?['displayName'] as String? ?? 'User';

  /// PIN set?
  bool get hasPin => (userDoc?['pinHash'] as String? ?? '').isNotEmpty;

  void clear() {
    uid = null;
    userEmail = null;
    phoneVerified = false;
    userDoc = null;
    accountDoc = null;
    pendingRecipient = null;
    pendingTxn = {};
    lastRawModelOutputs = null;
    lastTxnTs = null;
    notifyListeners();
  }

  void setUserDoc(Map<String, dynamic> doc) {
    userDoc = Map<String, dynamic>.from(doc); // defensive copy
    notifyListeners();
  }

  void setAccountDoc(Map<String, dynamic> doc) {
    accountDoc = Map<String, dynamic>.from(doc); // defensive copy
    notifyListeners();
  }

  void updateBalance(double newBalance) {
    if (accountDoc != null) {
      accountDoc!['balance'] = newBalance;
      notifyListeners();
    }
  }

  void notify() => notifyListeners();
}
