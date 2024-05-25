// screens/manage_discounts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageDiscountsScreen extends StatefulWidget {
  const ManageDiscountsScreen({Key? key}) : super(key: key);

  @override
  _ManageDiscountsScreenState createState() => _ManageDiscountsScreenState();
}

class _ManageDiscountsScreenState extends State<ManageDiscountsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  bool _loading = true;
  List<DocumentSnapshot> _products = [];
  String? _selectedProductId;
  double _discountPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchVendorProducts();
  }

  Future<void> _fetchVendorProducts() async {
    setState(() {
      _loading = true;
    });

    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      QuerySnapshot productSnapshot = await _firestore
          .collection('products')
          .where('vendorId', isEqualTo: _currentUser!.uid)
          .get();

      setState(() {
        _products = productSnapshot.docs;
        _loading = false;
      });
    }
  }

  Future<void> _applyDiscount() async {
    if (_selectedProductId != null) {
      await _firestore
          .collection('products')
          .doc(_selectedProductId)
          .update({'discount': _discountPercentage});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Discount applied to product!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Discounts'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Discounts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedProductId,
              hint: const Text('Select a product'),
              items: _products.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                document.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: document.id,
                  child: Text(data['name'] ?? 'Unnamed product'),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProductId = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Discount Percentage',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _discountPercentage = double.tryParse(value) ?? 0.0;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _applyDiscount,
              child: const Text('Apply Discount'),
            ),
          ],
        ),
      ),
    );
  }
}
