import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'home_wrapper.dart'; // Import the new wrapper
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      // The StreamBuilder listens to the user's authentication state.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while checking auth state.
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // If the user is logged in, show the HomeWrapper (with the bottom bar).
            return const HomeWrapper();
          }
          // If the user is not logged in, show the HomePage (login screen).
          return const HomePage();
        },
      ),
      routes: {
        // You can also use named routes for cleaner navigation.
        '/home': (context) => const HomeWrapper(),
        '/login': (context) => const HomePage(),
      },
    );
  }
}
