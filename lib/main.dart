import 'package:ecomm_platform/screens/manage_discounts_screen.dart';
import 'package:ecomm_platform/screens/manage_products_screen.dart';
import 'package:ecomm_platform/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/welcome_page.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/product_screen.dart';
import 'screens/become_vendor_screen.dart';
import 'screens/vendor_management_screen.dart';
import 'screens/cart_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/': (context) => const AuthCheck(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/become_vendor': (context) => const BecomeVendorScreen(),
        '/products': (context) => const ProductScreen(),
        '/vendor_management': (context) => const VendorManagementScreen(),
        '/user_profile': (context) => const UserProfileScreen(),
        '/vendor_profile': (context) => const VendorProfileScreen(),
        '/cart': (context) => const CartScreen(),
        '/manage_discounts': (context) => const ManageDiscountsScreen(),
        '/manage_products': (context) => const ManageProductsScreen(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasData && snapshot.data != null) {
          return const ProductScreen();
        } else {
          return const WelcomePage();
        }
      },
    );
  }
}
