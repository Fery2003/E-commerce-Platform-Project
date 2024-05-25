import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import './components/image_upload.dart'; // Ensure the correct import path for ImageUpload

class VendorManagementScreen extends StatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  _VendorManagementScreenState createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends State<VendorManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  String? _productImageUrl;

  void addProduct(String imageUrl) async {
    String productName = _productNameController.text.trim();
    String productPrice = _productPriceController.text.trim();
    String productDescription = _productDescriptionController.text.trim();
    User? user = _auth.currentUser;

    if (productName.isNotEmpty && productPrice.isNotEmpty && productDescription.isNotEmpty && imageUrl.isNotEmpty && user != null) {
      await _firestore.collection('products').add({
        'name': productName,
        'price': productPrice,
        'description': productDescription,
        'imageUrl': imageUrl,
        'vendorId': user.uid,
        'ratings': {},
      });
      _productNameController.clear();
      _productPriceController.clear();
      _productDescriptionController.clear();
      setState(() {
        _productImageUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added')),
      );
    }
  }

  Future<void> deleteProduct(String productId, String imageUrl) async {
    DocumentReference productRef = _firestore.collection('products').doc(productId);
    CollectionReference commentsRef = productRef.collection('comments');

    // Get all documents in the comments sub-collection
    QuerySnapshot commentsSnapshot = await commentsRef.get();

    // Delete each document in the comments sub-collection
    for (DocumentSnapshot doc in commentsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the product document
    await productRef.delete();

    // Delete the image from Firebase Storage
    if (imageUrl.isNotEmpty) {
      await _storage.refFromURL(imageUrl).delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product and its comments deleted')),
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
            TextField(
              controller: _productDescriptionController, // New TextField for description
              decoration: const InputDecoration(labelText: 'Product Description'),
            ),
            ImageUpload(
              onUploadComplete: (String imageUrl) {
                setState(() {
                  _productImageUrl = imageUrl;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_productImageUrl != null) {
                  addProduct(_productImageUrl!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please upload an image')),
                  );
                }
              },
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
                        title: Text(product['name']),
                        subtitle: Text('Price: \$${product['price']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => deleteProduct(product.id, product['imageUrl']),
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
