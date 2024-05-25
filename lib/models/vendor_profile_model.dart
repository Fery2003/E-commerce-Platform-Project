// models/vendor_profile_model.dart
class VendorProfileModel {
  String id;
  String userId;
  String vendorName;
  String description;
  List<String> productIds;

  VendorProfileModel({
    required this.id,
    required this.userId,
    required this.vendorName,
    required this.description,
    required this.productIds,
  });

  factory VendorProfileModel.fromMap(Map<String, dynamic> data) {
    return VendorProfileModel(
      id: data['id'],
      userId: data['userId'],
      vendorName: data['vendorName'],
      description: data['description'],
      productIds: List<String>.from(data['productIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'vendorName': vendorName,
      'description': description,
      'productIds': productIds,
    };
  }
}
