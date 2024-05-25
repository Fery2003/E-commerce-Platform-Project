import 'package:ecomm_platform/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/product_screen.dart';
import 'package:ecomm_platform/screens/become_vendor_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce Platform',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/become_vendor': (context) => const BecomeVendorScreen(),
        '/products': (context) => const ProductScreen(),
        // Add other routes here
      },
    );
  }
}
