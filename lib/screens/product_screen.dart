import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/product_model.dart'; // Ensure this import is correct
import './components/custom_drawer.dart';
import './product_detail_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  User? _currentUser;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery.toLowerCase();
    });
  }

  double _calculateAverageRating(Map<String, dynamic> ratings) {
    if (ratings.isEmpty) return 0.0;
    double sum = ratings.values.fold(0, (a, b) => a + b);
    return sum / ratings.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 40.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search Products',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                ),
                onChanged: _updateSearchQuery,
              ),
            ),
          ),
        ),
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var products = snapshot.data!.docs;
                var filteredProducts = products.where((product) {
                  return product['name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery);
                }).toList();
                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2 / 3,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    var productDoc = filteredProducts[index];
                    var product = ProductModel.fromMap(
                      productDoc.data() as Map<String, dynamic>,
                      productDoc.id,
                    );
                    var ratings = productDoc['ratings'] ?? {};
                    var averageRating = _calculateAverageRating(ratings);
                    return Card(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12.0)),
                              child: product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image,
                                          size: 50, color: Colors.grey),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Price: \$${product.price}'),
                                  const SizedBox(height: 4),
                                  RatingBarIndicator(
                                    rating: averageRating,
                                    itemBuilder: (context, index) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: 20.0,
                                    direction: Axis.horizontal,
                                  ),
                                  Text(
                                    ratings.length > 1 ? '(${ratings.length} ratings)' : '(${ratings.length} rating)',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
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
}
