import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'intro_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully!");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
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
      // ✅ You can change this to IntroPage if you want to always show it on launch
      home: const FirebaseCheckWrapper(),
    );
  }
}

class FirebaseCheckWrapper extends StatefulWidget {
  const FirebaseCheckWrapper({super.key});

  @override
  State<FirebaseCheckWrapper> createState() => _FirebaseCheckWrapperState();
}

class _FirebaseCheckWrapperState extends State<FirebaseCheckWrapper> {
  late Future<FirebaseApp> _firebaseInit;

  @override
  void initState() {
    super.initState();
    _firebaseInit = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firebaseInit,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Firebase connection failed:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        } else {
          return HomePage(); // ✅ Still loads HomePage after Firebase works
        }
      },
    );
  }
}
