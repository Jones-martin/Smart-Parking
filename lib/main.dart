import 'package:email_info_sender/offline_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'home_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'booking_page.dart';
import 'settings.dart';
import 'wallet_page.dart';
import 'my_vehicles_page.dart';
import 'help_support_page.dart';
import 'privacy_policy_page.dart';
import 'terms_page.dart';
import 'app_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔥 Firebase initialized: ${Firebase.app().options.projectId}");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Parking',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/booking': (context) => const BookingPage(),
        '/profile': (context) => const Settings(),
        '/wallet': (context) => const WalletPage(),
        '/my_vehicles': (context) => const MyVehiclesPage(),
        '/help': (context) => const HelpSupportPage(),
        '/privacy': (context) => const OfflineMapScreen(),
        '/terms': (context) => const TermsPage(),
        '/app_settings': (context) => const AppSettingsPage(),
      },
    );
  }
}
