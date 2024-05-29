import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecomm_platform/screens/manage_discounts_screen.dart';
import 'package:ecomm_platform/screens/manage_products_screen.dart';
import 'package:ecomm_platform/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/welcome_page.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/product_screen.dart';
import 'screens/become_vendor_screen.dart';
import 'screens/vendor_management_screen.dart';
import 'screens/cart_screen.dart';

// Initialize FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for notifications (iOS specific)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a message in the foreground: ${message.notification?.title}');
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Display a notification
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            channelDescription: 'your_channel_description',
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

Future<void> saveTokenToDatabase(String token) async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    DocumentReference tokenRef = _firestore.collection('vendor_tokens').doc(user.uid);
    await tokenRef.set({
      'token': token,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

void initializeFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Get the token for this device
  String? token = await messaging.getToken();

  // Save the token to Firestore
  if (token != null) {
    saveTokenToDatabase(token);
  }
}
