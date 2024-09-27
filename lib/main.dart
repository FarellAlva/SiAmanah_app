// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zakatapp/src/core/services/supabase_key.dart';
import 'package:zakatapp/src/navigator/navbar.dart';
import 'package:zakatapp/src/pages/login_page.dart';
import 'package:zakatapp/src/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

  runApp(const App());
}

String globalSelectedTempat = '';
final supabase = Supabase.instance.client;

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/account': (context) {
          final user = supabase.auth.currentUser;
          if (user != null) {
            String userId = user.id;
            return Navbar(userId: userId);
          } else {
            return const LoginPage();
          }
        },
      },
    );
  }
}
