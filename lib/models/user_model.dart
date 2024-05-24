// models/user_model.dart
class UserModel {
  String uid;
  String name;
  String email;
  bool isVendor;
  String? vendorProfileId; // Optional field for vendors

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.isVendor = false,
    this.vendorProfileId,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      isVendor: data['isVendor'] ?? false,
      vendorProfileId: data['vendorProfileId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'isVendor': isVendor,
      'vendorProfileId': vendorProfileId,
    };
  }
}
