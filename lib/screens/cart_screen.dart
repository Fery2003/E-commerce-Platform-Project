import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout.dart'; // Import the new CheckoutScreen
import '../models/cart_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _updateQuantity(String userId, CartModel cartItem, int quantity) async {
    final DocumentReference cartItemRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items')
        .doc(cartItem.productId);

    final DocumentSnapshot cartItemSnapshot = await cartItemRef.get();

    if (cartItemSnapshot.exists) {
      if (quantity > 0) {
        cartItem.changeQuantity(quantity);
        await cartItemRef.update(cartItem.toMap());
      } else {
        await cartItemRef.delete();
      }
    } else {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Document not found',
        code: 'not-found',
      );
    }
  }

  Future<void> _removeItem(String userId, String productId) async {
    final DocumentReference cartItemRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items')
        .doc(productId);

    final DocumentSnapshot cartItemSnapshot = await cartItemRef.get();

    if (cartItemSnapshot.exists) {
      await cartItemRef.delete();
    } else {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Document not found',
        code: 'not-found',
      );
    }
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

          return FutureBuilder<List<CartModel>>(
            future: Future.wait(cartItems.map((doc) async {
              var cartItem = CartModel.fromMap(doc.data() as Map<String, dynamic>);
              var productSnapshot = await FirebaseFirestore.instance
                  .collection('products')
                  .doc(cartItem.productId)
                  .get();
              if (productSnapshot.exists) {
                double productPrice = productSnapshot['price'];
                double discount = productSnapshot['discount']?.toDouble() ?? 0.0;
                double discountedPrice = productPrice - (productPrice * discount / 100);
                cartItem.unitPrice = discountedPrice;
                cartItem.changeQuantity(cartItem.quantity);
              }
              return cartItem;
            }).toList()),
            builder: (context, AsyncSnapshot<List<CartModel>> cartModelSnapshot) {
              if (!cartModelSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var cartModels = cartModelSnapshot.data!;
              double totalPrice = cartModels.fold(0.0, (sum, item) => sum + item.totalPrice);

              return Column(
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0), // Add padding to raise the button
                      child: ListView.builder(
                        itemCount: cartModels.length,
                        itemBuilder: (context, index) {
                          var cartItem = cartModels[index];

                          return Dismissible(
                            key: Key(cartItem.productId),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _removeItem(user.uid, cartItem.productId).catchError((error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to remove item from cart.')),
                                );
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Item removed from cart')),
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
                                  .doc(cartItem.productId)
                                  .get(),
                              builder: (context, productSnapshot) {
                                if (productSnapshot.connectionState == ConnectionState.waiting) {
                                  return const ListTile(
                                    title: Text('Loading...'),
                                  );
                                }
                                if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                                  return const ListTile(
                                    title: Text('Product not found'),
                                  );
                                }

                                var product = productSnapshot.data!;
                                double productPrice = product['price'];
                                double discount = product['discount']?.toDouble() ?? 0.0;
                                double discountedPrice = productPrice - (productPrice * discount / 100);

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
                                          if (cartItem.quantity > 1) {
                                            _updateQuantity(user.uid, cartItem, cartItem.quantity - 1).catchError((error) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Failed to update quantity.')),
                                              );
                                            });
                                          } else {
                                            _removeItem(user.uid, cartItem.productId).catchError((error) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Failed to remove item from cart.')),
                                              );
                                            });
                                          }
                                        },
                                      ),
                                      Text('Quantity: ${cartItem.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          _updateQuantity(user.uid, cartItem, cartItem.quantity + 1).catchError((error) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Failed to update quantity.')),
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: Text('\$${cartItem.totalPrice.toStringAsFixed(2)}'),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _checkout(context, cartItems),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal, // Set the button color to teal
                            padding: const EdgeInsets.symmetric(vertical: 16), // Increase the button height
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(fontSize: 18, color: Colors.white), // Increase the font size
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
