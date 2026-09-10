import 'package:flutter/material.dart';
import 'package:medication_reminder_app/firebase_options.dart';
import 'package:medication_reminder_app/providers/adherence_provider.dart';
import 'package:medication_reminder_app/providers/alert_provider.dart';
import 'package:medication_reminder_app/providers/analytics_provider.dart';
import 'package:medication_reminder_app/providers/caregiver_provider.dart';
import 'package:medication_reminder_app/providers/patient_overview_provider.dart';
import 'package:medication_reminder_app/providers/streak_provider.dart';
import 'package:medication_reminder_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/reminder_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

// Global navigator key for notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => AdherenceProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
        ChangeNotifierProvider(create: (_) => CaregiverProvider()),
        ChangeNotifierProvider(create: (_) => PatientOverviewProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: MaterialApp(
        title: 'MediRemind',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      default:
        return const LoginScreen();
    }
  }
}
