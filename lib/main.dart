import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase here, once, before the app runs.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully!");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
    // Handle the error here if needed.
  }

  runApp(const FinSageApp());
}

class FinSageApp extends StatelessWidget {
  const FinSageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinSage',
      theme: ThemeData(primarySwatch: Colors.blue),
      // This is the corrected line. It will now open HomePage first.
      home: const HomePage(),
    );
  }
}

// The following class is redundant since you are now setting the home
// property directly. You can remove this class if you wish.
class FirebaseCheckWrapper extends StatelessWidget {
  const FirebaseCheckWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
