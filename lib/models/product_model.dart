class ProductModel {
  String id;
  String name;
  double discount; // Add discount field
  double price;
  String imageUrl;
  String description;
  String vendorId;
  Map<String, dynamic> ratings;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.discount, // Add discount to constructor parameters
    required this.imageUrl,
    required this.description,
    required this.vendorId,
    this.ratings = const {},
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(), // Convert price to double
      discount: (data['discount'] ?? 0.0).toDouble(), // Convert discount to double and add default value
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      vendorId: data['vendorId'] ?? '',
      ratings: data['ratings'] != null ? Map<String, dynamic>.from(data['ratings']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'discount': discount, // Include discount in the map
      'imageUrl': imageUrl,
      'description': description,
      'vendorId': vendorId,
      'ratings': ratings,
    };
  }

  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    double sum = ratings.values.fold(0.0, (a, b) => a + b);
    return sum / ratings.length;
  }
}
