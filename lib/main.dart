// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'home_wrapper.dart';
import 'change_password_page.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const FinSageApp(),
    ),
  );
}

class FinSageApp extends StatelessWidget {
  const FinSageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinSage',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F4F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6B5B95),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const HomeWrapper();
          }
          return const HomePage();
        },
      ),
      routes: {
        '/home': (context) => const HomeWrapper(),
        '/login': (context) => const HomePage(),
        '/change-password': (context) => const ChangePasswordPage(),
      },
    );
  }
}
