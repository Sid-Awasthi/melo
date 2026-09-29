import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:melo/auth/auth.dart';
import 'package:melo/firebase_options.dart';

import 'package:melo/pages/home_page.dart';
import 'package:melo/pages/login_page.dart';
import 'package:melo/pages/profilepage.dart';
import 'package:melo/pages/register_page.dart';
import 'package:melo/pages/userspage.dart';
import 'package:melo/pages/splash_page.dart';

import 'package:melo/theme/dar_mode.dart';
import 'package:melo/theme/light_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MELO',
      debugShowCheckedModeBanner: false,

      theme: lightTheme,
      darkTheme: darkTheme,

      home: const SplashPage(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => ProfilePage(),
        '/users': (context) => const UsersPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
