import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isVendor = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _checkIfVendor();
  }

  Future<void> _checkIfVendor() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isVendor = userDoc['isVendor'] ?? false;
        });
      }
    }
  }

  void _navigateTo(String routeName) {
    Navigator.pop(context); // Close the drawer
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = _currentUser != null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.teal, // Teal green color for the header
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Products'),
            onTap: () => Navigator.pushNamed(context, '/products'),
          ),
          if (isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                if (_isVendor) {
                  Navigator.pushNamed(context, '/vendor_profile');
                } else {
                  Navigator.pushNamed(context, '/user_profile');
                }
              },
            ),
            if (!_isVendor)
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('My Cart'),
                onTap: () => Navigator.pushNamed(context, '/cart'),
              ),
            if (_isVendor)
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('Vendor Management'),
                onTap: () => Navigator.pushNamed(context, '/vendor_management'),
              ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Log Out'),
              onTap: () async {
                await _auth.signOut();
                Navigator.pushNamed(context, '/');
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Log In'),
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
          ],
        ],
      ),
    );
  }
}