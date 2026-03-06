import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finsage/dashboard_page.dart';
import 'change_password_page.dart';
import 'firebase_options.dart';
import 'theme_provider.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables for the AI
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Environment variables load failed: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const FinSageApp(),
    ),
  );
}

class FinSageApp extends StatelessWidget {
  const FinSageApp({super.key});

  Future<void> _saveUserToFirestore(User user) async {
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'name': user.displayName ?? 'User',
        'email': user.email,
        'phone': user.phoneNumber ?? '',
        'profilePictureUrl': 'assets/avatars/avatar2.jpeg',
        'receiveSuggestions': true,
        'createdAt': DateTime.now(),
      });
      debugPrint("✅ User data saved to Firestore");
    }
  }

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
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            _saveUserToFirestore(snapshot.data!);
            return const DashboardPage();
          }
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/change-password': (context) => const ChangePasswordPage(),
      },
    );
  }
}
