import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout.dart'; // Import the new CheckoutScreen

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _updateQuantity(String userId, String productId, int quantity) async {
    final DocumentReference cartItemRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items')
        .doc(productId);

    if (quantity > 0) {
      await cartItemRef.update({'quantity': quantity});
    } else {
      await cartItemRef.delete();
    }
  }

  Future<void> _removeItem(String userId, String productId) async {
    final DocumentReference cartItemRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items')
        .doc(productId);

    await cartItemRef.delete();
  }

  void _checkout(BuildContext context, List<QueryDocumentSnapshot> cartItems) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(cartItems: cartItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Cart'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/products'); // Navigate back to products screen
            },
          ),
        ),
        body: const Center(
          child: Text('You need to be logged in to view your cart.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/products'); // Navigate back to products screen
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user.uid)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var cartItems = snapshot.data!.docs;
          if (cartItems.isEmpty) {
            return const Center(child: Text('Your cart is empty.'));
          }

          return Column(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // Add padding to raise the button
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      var cartItem = cartItems[index];
                      var productId = cartItem['productId'];
                      var quantity = cartItem['quantity'];

                      return Dismissible(
                        key: Key(productId),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _removeItem(user.uid, productId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Item removed from cart')),
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('products')
                              .doc(productId)
                              .get(),
                          builder: (context, productSnapshot) {
                            if (!productSnapshot.hasData) {
                              return const ListTile(
                                title: Text('Loading...'),
                              );
                            }

                            var product = productSnapshot.data!;
                            return ListTile(
                              leading: product['imageUrl'].isNotEmpty
                                  ? Image.network(
                                product['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                                  : const Icon(Icons.image, size: 50),
                              title: Text(product['name']),
                              subtitle: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        _updateQuantity(user.uid, productId, quantity - 1);
                                      } else {
                                        _removeItem(user.uid, productId);
                                      }
                                    },
                                  ),
                                  Text('Quantity: $quantity'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      _updateQuantity(user.uid, productId, quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                              trailing: Text('\$${product['price']}'),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _checkout(context, cartItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Set the button color to teal
                      padding: const EdgeInsets.symmetric(vertical: 16), // Increase the button height
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(fontSize: 18), // Increase the font size
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
