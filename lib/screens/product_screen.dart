import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import './components/custom_drawer.dart';
import './product_detail_screen.dart';
import './components/deals_carousel.dart';

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
  String? _selectedCategory;
  Future<QuerySnapshot>? _productsFuture;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchProducts();
    _fetchCategories();
  }

  void _fetchProducts() {
    setState(() {
      if (_selectedCategory == null) {
        _productsFuture = _firestore.collection('products').get();
      } else {
        _productsFuture = _firestore
            .collection('products')
            .where('categoryId', isEqualTo: _selectedCategory)
            .get();
      }
    });
  }

  void _fetchCategories() async {
    QuerySnapshot categorySnapshot =
        await _firestore.collection('categories').get();
    setState(() {
      _categories = categorySnapshot.docs
          .map((doc) =>
              CategoryModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery.toLowerCase();
    });
  }

  void _toggleCategory(String? categoryId) {
    setState(() {
      if (_selectedCategory == categoryId) {
        _selectedCategory = null;
      } else {
        _selectedCategory = categoryId;
      }
      _fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    double paddingHorizontal = MediaQuery.of(context).size.width * 0.038;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products', style: TextStyle(fontFamily: 'Lato')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
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
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchProducts();
          await _productsFuture;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const DealsCarousel(),
                  const SizedBox(height: 8.0),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                    child: GridView.builder(
                      shrinkWrap: true,
                      itemCount: _categories.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 6.0,
                        crossAxisSpacing: 8.0,
                      ),
                      itemBuilder: (context, index) {
                        var category = _categories[index];
                        bool isSelected = _selectedCategory == category.id;
                        return InkWell(
                          onTap: () {
                            _toggleCategory(category.id);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: isSelected ? Colors.teal : Colors.grey[200],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(category.imageUrl),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18.0),
                ],
              ),
            ),
            FutureBuilder<QuerySnapshot>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                var products = snapshot.data!.docs;
                var filteredProducts = products.where((product) {
                  return product['name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery);
                }).toList();
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 8.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2 / 3.5,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var productDoc = filteredProducts[index];
                        var product = ProductModel.fromMap(
                          productDoc.data() as Map<String, dynamic>,
                          productDoc.id,
                        );
                        var averageRating = product.averageRating;
                        var hasDiscount = product.discount > 0;
                        var discountedPrice = product.price * (1 - product.discount / 100);
                        return Stack(
                          children: [
                            Card(
                              elevation: 10.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(product: product),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                                      child: product.imageUrl.isNotEmpty
                                          ? Image.network(
                                              product.imageUrl,
                                              height: 150,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              height: 150,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if (hasDiscount) ...[
                                            Text(
                                              'Price: \$${product.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            Text(
                                              'Discounted: \$${discountedPrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ] else ...[
                                            Text(
                                              'Price: \$${product.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
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
                                            '${averageRating.toStringAsFixed(1)} (${product.ratings.length} rating${product.ratings.length == 1 ? '' : 's'})',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (hasDiscount)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Text(
                                    'Discount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                      childCount: filteredProducts.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
