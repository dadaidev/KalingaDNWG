import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/set_new_password_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Global key so we can navigate from outside the widget tree
// (needed when Supabase fires the password-recovery event).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dtivhpgswchkjvwvjujd.supabase.co', // TODO: replace with your actual Supabase project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR0aXZocGdzd2Noa2p2d3ZqdWpkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5OTg0NTYsImV4cCI6MjA5ODU3NDQ1Nn0.B1SZHL8Du5QNh8VaKDsEXxK104wswSiuH6mGInrBqog', // TODO: replace with your actual anon/public key
  );

  runApp(const KalingaApp());
}

class KalingaApp extends StatefulWidget {
  const KalingaApp({super.key});

  @override
  State<KalingaApp> createState() => _KalingaAppState();
}

class _KalingaAppState extends State<KalingaApp> {
  @override
  void initState() {
    super.initState();
    _listenForPasswordRecovery();
  }

  void _listenForPasswordRecovery() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const SetNewPasswordScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Kalinga DNWG',
      home: const SplashScreen(),
    );
  }
}