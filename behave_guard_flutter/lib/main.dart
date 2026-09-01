// lib/main.dart — BehaveGuard-UPI Flutter App
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_state.dart';
import 'services/fraud_service.dart';
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'screens/provisioning_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/send_screen.dart';
import 'screens/myqr_screen.dart';
import 'screens/confirm_recipient_screen.dart';
import 'screens/amount_screen.dart';
import 'screens/geo_explainer_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/result_screens.dart';
import 'screens/debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDdtK6VuhaTq7yzARgtedPI8eVFQdvCm_0',
      appId: '1:119017141733:android:868af6c43c8c3cafa72b0c',
      messagingSenderId: '119017141733',
      projectId: 'bejaveguardctx',
      storageBucket: 'bejaveguardctx.firebasestorage.app',
    ),
  );

  // Load persisted debug overrides
  final prefs = await SharedPreferences.getInstance();
  final overridesJson = prefs.getString('bguard_debug_overrides');
  final overrides = overridesJson != null
      ? (jsonDecode(overridesJson) as Map<String, dynamic>)
      : <String, dynamic>{};

  final appState = AppState()..debugOverrides = overrides;
  final fraudService = FraudService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appState),
        Provider(create: (_) => fraudService),
      ],
      child: const BehaveGuardApp(),
    ),
  );
}

class BehaveGuardApp extends StatelessWidget {
  const BehaveGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BehaveGuard·UPI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4C5FE0),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1B1E2E),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B1E2E),
          ),
        ),
      ),
      builder: (context, child) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4F5F9)],
          ),
        ),
        child: child!,
      ),
      // '/' now points to SplashScreen which decides the flow
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const SplashScreen();
            break;
          case '/landing':
            page = const LandingScreen();
            break;
          case '/login':
            page = const LoginScreen();
            break;
          case '/pin-lock':
            page = const PinLockScreen();
            break;
          case '/provisioning':
            page = const ProvisioningScreen();
            break;
          case '/dashboard':
            page = const DashboardScreen();
            break;
          case '/send':
            page = const SendScreen();
            break;
          case '/myqr':
            page = const MyQrScreen();
            break;
          case '/confirm-recipient':
            page = const ConfirmRecipientScreen();
            break;
          case '/amount':
            page = const AmountScreen();
            break;
          case '/geo-explainer':
            page = const GeoExplainerScreen();
            break;
          case '/processing':
            page = const ProcessingScreen();
            break;
          case '/success':
            page = const SuccessScreen();
            break;
          case '/blocked':
            page = const BlockedScreen();
            break;
          case '/debug':
            page = const DebugScreen();
            break;
          default:
            page = const SplashScreen();
        }
        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }
}
