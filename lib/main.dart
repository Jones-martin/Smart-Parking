import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'notification_service.dart';

import 'home_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'booking_page.dart';
import 'settings.dart';
import 'wallet_page.dart';
import 'my_vehicles_page.dart';
import 'help_support_page.dart';
import 'privacy_policy_page.dart';
import 'app_settings_page.dart';
import 'map_page.dart';
import 'my_bookings_page.dart';
import 'qr_page.dart';
import 'ratings_page.dart';
import 'admin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  print("🔥 Firebase initialized: ${Firebase.app().options.projectId}");
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Parking',
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
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
        '/map': (context) => const MapPage(),
        '/privacy': (context) => const PrivacyPolicyPage(),
        '/app_settings': (context) => const AppSettingsPage(),
        '/my_bookings': (context) => const MyBookingsPage(),
        '/admin': (context) => const AdminPage(),
      },
      // Named routes with arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/rate') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => RatingsPage(
              bookingId: args['bookingId'] as String,
              slot: args['slot'] as String,
            ),
          );
        }
        if (settings.name == '/qr') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => QrPage(
              bookingId: args['bookingId'] as String,
              name: args['name'] as String,
              slot: args['slot'] as String,
              date: args['date'] as String,
              time: args['time'] as String,
            ),
          );
        }
        return null;
      },
    );
  }
}
