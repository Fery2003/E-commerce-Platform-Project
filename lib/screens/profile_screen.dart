// screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecomm_platform/models/user_model.dart';
import 'package:ecomm_platform/screens/components/image_upload.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  UserModel? _userModel;
  String? _profileImageUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _loading = true;
    });

    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        _userModel = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        _profileImageUrl = userDoc['profileImageUrl'];

        if (_userModel!.isVendor) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const VendorProfileScreen()),
          );
        } else {
          setState(() {
            _loading = false;
          });
        }
        setState(() {
          _userModel =
              UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
          _profileImageUrl = userDoc['profileImageUrl'];
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateProfileImage(String imageUrl) async {
    if (_currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'profileImageUrl': imageUrl});
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
        title: const Text('Hello, Shopper'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Smart Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_back),
            label: '',
          ),
        ],
        onTap: (index) {
          // Handle navigation based on the index
          if (index == 0) {
            Navigator.pushNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/products');
          } else if (index == 2) {
            Navigator.pop(context);
          }
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                color: Colors.teal[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_profileImageUrl != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(_profileImageUrl!),
                          radius: 40,
                        )
                      else
                        const Icon(Icons.account_circle, size: 80),
                      const SizedBox(height: 8),
                      Text(
                        _userModel?.email ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ImageUpload(onUploadComplete: _updateProfileImage),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildProfileOption(
                    context: context,
                    icon: Icons.shopping_cart,
                    label: 'My Cart',
                    onTap: () => Navigator.pushNamed(context, '/cart'),
                  ),
                  _buildProfileOption(
                    context: context,
                    icon: Icons.favorite,
                    label: 'Wishlist',
                    onTap: () => Navigator.pushNamed(context, '/wishlist'),
                  ),
                  _buildProfileOption(
                    context: context,
                    icon: Icons.list,
                    label: 'Orders',
                    onTap: () => Navigator.pushNamed(context, '/orders'),
                  ),
                  _buildProfileOption(
                    context: context,
                    icon: Icons.store,
                    label: 'Become a Vendor',
                    onTap: () => Navigator.pushNamed(context, '/become_vendor'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.teal),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  _VendorProfileScreenState createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String? _profileImageUrl;
  String? _email;
  bool _loading = true;
  double _averageRating = 0.0; // Average rating of the vendor's products

  @override
  void initState() {
    super.initState();
    _fetchVendorData();
  }

  Future<void> _fetchVendorData() async {
    setState(() {
      _loading = true;
    });

    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _profileImageUrl = userDoc['profileImageUrl'];
          _email = userDoc['email'];
        });
        await _calculateAverageRating();
      }
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _calculateAverageRating() async {
    if (_currentUser != null) {
      QuerySnapshot productSnapshot = await _firestore
          .collection('products')
          .where('vendorId', isEqualTo: _currentUser!.uid)
          .get();

      double totalRating = 0.0;
      int totalRatingsCount = 0;

      for (var productDoc in productSnapshot.docs) {
        var productData = productDoc.data() as Map<String, dynamic>;
        if (productData['ratings'] != null) {
          Map<String, dynamic> ratings =
              Map<String, dynamic>.from(productData['ratings']);
          ratings.forEach((key, value) {
            totalRating += value;
            totalRatingsCount++;
          });
        }
      }

      if (totalRatingsCount > 0) {
        _averageRating = totalRating / totalRatingsCount;
      } else {
        _averageRating = 0.0;
      }
    }
  }

  Future<void> _updateProfileImage(String imageUrl) async {
    if (_currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'profileImageUrl': imageUrl});
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
        title: const Text('Hello, Vendor'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Smart Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.arrow_back),
            label: '',
          ),
        ],
        onTap: (index) {
          // Handle navigation based on the index
          if (index == 0) {
            Navigator.pushNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/products');
          } else if (index == 2) {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushNamed(context, '/products');
            }
          }
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                color: Colors.teal[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_profileImageUrl != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(_profileImageUrl!),
                          radius: 40,
                        )
                      else
                        const Icon(Icons.account_circle, size: 80),
                      const SizedBox(height: 8),
                      Text(
                        _email ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _averageRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.orange,
                            size: 24,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      ImageUpload(onUploadComplete: _updateProfileImage),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildProfileOption(
                    context: context,
                    icon: Icons.store,
                    label: 'My Products',
                    onTap: () =>
                        Navigator.pushNamed(context, '/vendor_management'),
                  ),
                  _buildProfileOption(
                    context: context,
                    icon: Icons.show_chart,
                    label: 'Sales',
                    onTap: () => Navigator.pushNamed(context, '/sales'),
                  ),
                  _buildProfileOption(
                    context: context,
                    icon: Icons.list,
                    label: 'Orders',
                    onTap: () => Navigator.pushNamed(context, '/orders'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.teal),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
