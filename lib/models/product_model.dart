class ProductModel {
  String id;
  String name;
  String price;
  String imageUrl;
  String description;
  String vendorId;
  Map<String, dynamic> ratings; // Added ratings field

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.vendorId,
    this.ratings = const {}, // Default to an empty map
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      price: data['price'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      vendorId: data['vendorId'] ?? '',
      ratings: data['ratings'] != null ? Map<String, dynamic>.from(data['ratings']) : {}, // Initialize ratings
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
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
