import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/set_new_password_screen.dart';

// Global key so we can navigate from outside the widget tree
// (needed when Supabase fires the password-recovery event).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env. '
      'Check that the .env file exists at the project root and is '
      'listed under assets in pubspec.yaml.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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