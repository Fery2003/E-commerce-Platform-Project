// screens/product_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './components/custom_drawer.dart';
import './components/image_upload.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  User? _currentUser;
  bool _isVendor = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _checkIfVendor();
  }

  Future<void> _checkIfVendor() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _isVendor = userDoc['isVendor'] ?? false;
        });
      } else {
        await _firestore.collection('users').doc(_currentUser!.uid).set({
          'email': _currentUser!.email,
          'isVendor': false,
        });
        setState(() {
          _isVendor = false;
        });
      }
    }
  }

  void _addProduct(String imageUrl) async {
    String productName = _productNameController.text.trim();
    String productPrice = _productPriceController.text.trim();

    if (productName.isNotEmpty && productPrice.isNotEmpty && _currentUser != null) {
      DocumentReference productRef = await _firestore.collection('products').add({
        'name': productName,
        'price': productPrice,
        'vendorId': _currentUser!.uid,
        'imageUrl': imageUrl,
      });
      await _firestore.collection('vendors').doc(_currentUser!.uid).update({
        'productIds': FieldValue.arrayUnion([productRef.id]),
      });
      _productNameController.clear();
      _productPriceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added')),
      );
    }
  }

  void _deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    await _firestore.collection('vendors').doc(_currentUser!.uid).update({
      'productIds': FieldValue.arrayRemove([productId]),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted')),
    );
  }

  void _editProduct(String productId, String newName, String newPrice) async {
    await _firestore.collection('products').doc(productId).update({
      'name': newName,
      'price': newPrice,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          if (_isVendor)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _productNameController,
                    decoration: const InputDecoration(labelText: 'Product Name'),
                  ),
                  TextField(
                    controller: _productPriceController,
                    decoration: const InputDecoration(labelText: 'Product Price'),
                    keyboardType: TextInputType.number,
                  ),
                  ImageUpload(onUploadComplete: _addProduct),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var products = snapshot.data!.docs;
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two products per row
                    childAspectRatio: 3 / 2, // Aspect ratio for product boxes
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var product = products[index];
                    return Dismissible(
                      key: Key(product.id),
                      direction: _isVendor && product['vendorId'] == _currentUser!.uid
                          ? DismissDirection.horizontal
                          : DismissDirection.none,
                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          _deleteProduct(product.id);
                        }
                      },
                      background: Container(color: Colors.red),
                      child: GridTile(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: product['imageUrl'] != null
                                  ? Image.network(
                                      product['imageUrl'],
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Price: \$${product['price']}'),
                                ],
                              ),
                            ),
                            if (_isVendor && product['vendorId'] == _currentUser!.uid)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditProductDialog(product.id, product['name'], product['price']);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(String productId, String currentName, String currentPrice) {
    TextEditingController _editNameController = TextEditingController(text: currentName);
    TextEditingController _editPriceController = TextEditingController(text: currentPrice);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editNameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: _editPriceController,
                decoration: const InputDecoration(labelText: 'Product Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _editProduct(productId, _editNameController.text, _editPriceController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
