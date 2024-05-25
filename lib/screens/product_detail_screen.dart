// screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProductDetailScreen extends StatelessWidget {
  final DocumentSnapshot product;

  const ProductDetailScreen({super.key, required this.product});

  Future<void> _rateProduct(String productId, double rating, User user) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    DocumentReference productRef = _firestore.collection('products').doc(productId);
    String userId = user.uid;

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(productRef);

      if (!snapshot.exists) {
        throw Exception("Product does not exist!");
      }

      Map<String, dynamic> ratings = snapshot['ratings'] != null
          ? Map<String, dynamic>.from(snapshot['ratings'] as Map)
          : {};
      ratings[userId] = rating;

      transaction.update(productRef, {'ratings': ratings});
    });
  }

  double _calculateAverageRating(Map<String, dynamic> ratings) {
    if (ratings.isEmpty) return 0.0;
    double sum = ratings.values.fold(0, (a, b) => a + b);
    return sum / ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    var ratings = product['ratings'] != null
        ? Map<String, dynamic>.from((product['ratings'] as Map).map((key, value) => MapEntry(key.toString(), value)))
        : {};
    var averageRating = _calculateAverageRating(Map<String, dynamic>.from(product['ratings']));
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            product['imageUrl'] != null
                ? Image.network(
                    product['imageUrl'],
                    fit: BoxFit.cover,
                    height: 250,
                    width: double.infinity,
                  )
                : const Icon(Icons.image, size: 250),
            const SizedBox(height: 16),
            Text(
              product['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: \$${product['price']}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              product['description'] ?? 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Average Rating',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RatingBarIndicator(
              rating: averageRating,
              itemBuilder: (context, index) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              itemCount: 5,
              itemSize: 30.0,
              direction: Axis.horizontal,
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              const Text(
                'Rate this product',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RatingBar.builder(
                initialRating: ratings[user.uid]?.toDouble() ?? 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  _rateProduct(product.id, rating, user);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
