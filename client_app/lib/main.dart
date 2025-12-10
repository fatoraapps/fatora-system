// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/client_app_main_shell.dart';
import 'config.dart';
import 'screens/client_app_splash_screen.dart';
import 'screens/client_app_login_screen.dart';
import 'screens/client_app_register_screen.dart';
import 'screens/client_app_home_screen.dart';
// مفيش داعي لاستيراد client_app_supplier_screen هنا
// لأنه بيستخدم من داخل client_app_home_screen.dart مش من main.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.kSupabaseUrl,
    anonKey: AppConfig.kSupabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fatoora Client App',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Cairo',
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ClientAppSplashScreen(),
        '/client/login': (context) => const ClientAppLoginScreen(),
        '/client/register': (context) => const ClientAppRegisterScreen(),


        // ✅ المسار الجديد اللي يحتوي على الـ Bottom Bar
        '/client/main': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final clientId =
          (args is String && args.isNotEmpty) ? args : 'UNKNOWN_CLIENT';

          return ClientAppMainShell(clientId: clientId);
        },
      },
    );
  }
}
