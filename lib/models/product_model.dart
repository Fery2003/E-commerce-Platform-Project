class ProductModel {
  String id;
  String name;
  String price;
  String imageUrl;
  String description; // New description field
  String vendorId;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.vendorId,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      price: data['price'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '', // Fetch the description
      vendorId: data['vendorId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'vendorId': vendorId,
    };
  }
}
