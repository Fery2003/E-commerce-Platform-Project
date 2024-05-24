// screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecomm_platform/models/vendor_profile_model.dart';
import 'package:ecomm_platform/screens/components/image_upload.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  bool _isVendor = false;
  bool _loading = true;
  VendorProfileModel? _vendorProfile;
  String? _profileImageUrl;

  final TextEditingController _vendorNameController = TextEditingController();
  final TextEditingController _vendorDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isVendor = userDoc['isVendor'] ?? false;
          _profileImageUrl = userDoc['profileImageUrl'];
          _loading = false;
        });

        if (_isVendor) {
          DocumentSnapshot vendorDoc = await _firestore.collection('vendors').doc(_currentUser!.uid).get();
          if (vendorDoc.exists) {
            _vendorProfile = VendorProfileModel.fromMap(vendorDoc.data() as Map<String, dynamic>);
            _vendorNameController.text = _vendorProfile!.vendorName;
            _vendorDescriptionController.text = _vendorProfile!.description;
          }
        }
      } else {
        await _firestore.collection('users').doc(_currentUser!.uid).set({
          'email': _currentUser!.email,
          'isVendor': false,
          'profileImageUrl': null,
        });
        setState(() {
          _isVendor = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _upgradeToVendor() async {
    if (_currentUser != null) {
      await _firestore.collection('users').doc(_currentUser!.uid).update({'isVendor': true});
      await _firestore.collection('vendors').doc(_currentUser!.uid).set({
        'id': _currentUser!.uid,
        'userId': _currentUser!.uid,
        'vendorName': _vendorNameController.text,
        'description': _vendorDescriptionController.text,
        'productIds': [],
      });
      setState(() {
        _isVendor = true;
        _vendorProfile = VendorProfileModel(
          id: _currentUser!.uid,
          userId: _currentUser!.uid,
          vendorName: _vendorNameController.text,
          description: _vendorDescriptionController.text,
          productIds: [],
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account upgraded to vendor')),
      );
    }
  }

  Future<void> _updateVendorProfile() async {
    if (_currentUser != null && _vendorProfile != null) {
      await _firestore.collection('vendors').doc(_currentUser!.uid).update({
        'vendorName': _vendorNameController.text,
        'description': _vendorDescriptionController.text,
      });
      setState(() {
        _vendorProfile = VendorProfileModel(
          id: _vendorProfile!.id,
          userId: _vendorProfile!.userId,
          vendorName: _vendorNameController.text,
          description: _vendorDescriptionController.text,
          productIds: _vendorProfile!.productIds,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vendor profile updated')),
      );
    }
  }

  Future<void> _updateProfileImage(String imageUrl) async {
    if (_currentUser != null) {
      await _firestore.collection('users').doc(_currentUser!.uid).update({'profileImageUrl': imageUrl});
      setState(() {
        _profileImageUrl = imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_profileImageUrl != null)
              Image.network(_profileImageUrl!)
            else
              const Icon(Icons.account_circle, size: 100),
            ImageUpload(onUploadComplete: _updateProfileImage),
            const SizedBox(height: 20),
            Text('Email: ${_currentUser?.email ?? 'No email'}'),
            const SizedBox(height: 20),
            if (_isVendor)
              Column(
                children: [
                  const Text('Account Type: Vendor'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _vendorNameController,
                    decoration: const InputDecoration(labelText: 'Vendor Name'),
                  ),
                  TextField(
                    controller: _vendorDescriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateVendorProfile,
                    child: const Text('Update Vendor Profile'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Text('Account Type: User'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _vendorNameController,
                    decoration: const InputDecoration(labelText: 'Vendor Name'),
                  ),
                  TextField(
                    controller: _vendorDescriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _upgradeToVendor,
                    child: const Text('Upgrade to Vendor'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
