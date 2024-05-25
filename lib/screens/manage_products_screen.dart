import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error fetching products.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found.'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final productDoc = snapshot.data!.docs[index];
              final product = ProductModel.fromMap(productDoc.data() as Map<String, dynamic>, productDoc.id);

              double discountedPrice = product.price - (product.price * product.discount / 100);

              return Dismissible(
                key: Key(product.id), // Use product ID as key
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  // Show a confirmation dialog before deleting the product
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text("Are you sure you want to delete this product?"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("DELETE"),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  // Handle deleting the product from the database
                  FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(product.imageUrl),
                    ),
                    title: Text(product.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text('Price: \$${product.price.toStringAsFixed(2)}'),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text('Discounted: \$${discountedPrice.toStringAsFixed(2)}'),
                            ),
                          ],
                        ),
                        if (product.averageRating > 0)
                          Text('Rating: ${product.averageRating.toStringAsFixed(1)}'),
                        if (product.averageRating <= 0) // Show message for products without ratings
                          const Text('No ratings yet'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Navigate to a screen to edit product details
                        // Pass the product document ID to the editing screen
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
