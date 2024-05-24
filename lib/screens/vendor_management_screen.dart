// screens/vendor_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './components/image_upload.dart';

class VendorManagementScreen extends StatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  _VendorManagementScreenState createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends State<VendorManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  String? _productImageUrl;

  void addProduct() async {
    String productName = _productNameController.text.trim();
    String productPrice = _productPriceController.text.trim();
    User? user = _auth.currentUser;

    if (productName.isNotEmpty && productPrice.isNotEmpty && user != null) {
      await _firestore.collection('products').add({
        'name': productName,
        'price': productPrice,
        'vendorId': user.uid,
        'imageUrl': _productImageUrl,
      });
      _productNameController.clear();
      _productPriceController.clear();
      _productImageUrl = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added')),
      );
    }
  }

  void deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted')),
    );
  }

  void editProduct(String productId, String newName, String newPrice, String newImageUrl) async {
    await _firestore.collection('products').doc(productId).update({
      'name': newName,
      'price': newPrice,
      'imageUrl': newImageUrl,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product updated')),
    );
  }

  void _showEditProductDialog(String productId, String currentName, String currentPrice, String currentImageUrl) {
    TextEditingController _editNameController = TextEditingController(text: currentName);
    TextEditingController _editPriceController = TextEditingController(text: currentPrice);
    String? _editImageUrl = currentImageUrl;

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
              ImageUpload(onUploadComplete: (imageUrl) {
                _editImageUrl = imageUrl;
              }),
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
                editProduct(productId, _editNameController.text, _editPriceController.text, _editImageUrl ?? '');
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
      ),
      body: Padding(
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
            ImageUpload(onUploadComplete: (imageUrl) {
              _productImageUrl = imageUrl;
            }),
            ElevatedButton(
              onPressed: addProduct,
              child: const Text('Add Product'),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('products')
                    .where('vendorId', isEqualTo: _auth.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var products = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      var product = products[index];
                      return ListTile(
                        leading: product['imageUrl'] != null
                            ? Image.network(product['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.image),
                        title: Text(product['name']),
                        subtitle: Text('Price: \$${product['price']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditProductDialog(
                                  product.id,
                                  product['name'],
                                  product['price'],
                                  product['imageUrl'],
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => deleteProduct(product.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
