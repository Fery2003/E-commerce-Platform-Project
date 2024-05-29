import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

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

  Future<void> _addComment(String productId, String comment, User user) async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentReference productRef = _firestore.collection('products').doc(productId);
  CollectionReference commentsRef = productRef.collection('comments');

  await commentsRef.add({
    'userId': user.uid,
    'username': user.displayName ?? 'Anonymous',
    'comment': comment,
    'timestamp': FieldValue.serverTimestamp(),
  });

  // Get the vendor's FCM token
  DocumentSnapshot vendorSnapshot = await _firestore.collection('vendor_tokens').doc(productId).get();
  if (vendorSnapshot.exists) {
    String vendorToken = vendorSnapshot['token'];

    // Send a notification to the vendor
    await FirebaseMessaging.instance.sendMessage(
      to: vendorToken,
      data: {
        'title': 'New Comment',
        'body': 'A new comment has been added to your product',
      },
    );
  }
}


  Future<void> _addToCart(String productId, User user) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    DocumentReference cartRef = _firestore.collection('carts').doc(user.uid);
    CollectionReference cartItemsRef = cartRef.collection('items');

    // Check if the product is already in the cart
    QuerySnapshot existingCartItems = await cartItemsRef
        .where('productId', isEqualTo: productId)
        .get();

    if (existingCartItems.docs.isEmpty) {
      // If the product is not in the cart, add it
      await cartItemsRef.add({
        'productId': productId,
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // If the product is already in the cart, increase the quantity
      DocumentReference existingCartItemRef = existingCartItems.docs.first.reference;
      await existingCartItemRef.update({
        'quantity': FieldValue.increment(1),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    var averageRating = widget.product.averageRating;

    double discountedPrice = widget.product.price - (widget.product.price * widget.product.discount / 100);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.product.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      height: 250,
                      width: double.infinity,
                    )
                  : const Icon(Icons.image, size: 250),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.product.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (user != null)
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      color: Colors.teal,
                      onPressed: () {
                        _addToCart(widget.product.id, user);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${widget.product.name} added to cart')),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Price: \$${widget.product.price}',
                style: TextStyle(
                  fontSize: 20,
                  decoration: widget.product.discount > 0 ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              if (widget.product.discount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Discounted Price: \$${discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, color: Colors.red),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Text(
                    'Discount',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.product.description.isNotEmpty ? widget.product.description : 'No description available',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Average Rating',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
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
                  const SizedBox(width: 8),
                  Text(
                    averageRating.toStringAsFixed(1), // Display average rating with one decimal place
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (user != null) ...[
                const Text(
                  'Rate this product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RatingBar.builder(
                  initialRating: widget.product.ratings[user.uid]?.toDouble() ?? 0,
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
                    _rateProduct(widget.product.id, rating, user);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add a comment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter your comment',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      _addComment(widget.product.id, _commentController.text, user);
                      _commentController.clear();
                    }
                  },
                  child: const Text('Submit'),
                ),
              ] else ...[
                const Text(
                  'You need to be logged in to rate, comment, or add this product to your cart.',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Comments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.product.id)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var comments = snapshot.data!.docs;
                  if (comments.isEmpty) {
                    return const Text('No comments yet.');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      var comment = comments[index];
                      var timestamp = (comment['timestamp'] as Timestamp?)?.toDate();
                      var formattedTime = timestamp != null ? DateFormat.yMMMd().add_jm().format(timestamp) : 'Unknown time';
                      return ListTile(
                        title: Text(comment['username']),
                        subtitle: Text(comment['comment']),
                        trailing: Text(formattedTime),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
