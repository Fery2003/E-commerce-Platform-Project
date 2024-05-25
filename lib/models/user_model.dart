class UserModel {
  String email;
  bool isVendor;

  UserModel({
    required this.email,
    this.isVendor = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'isVendor': isVendor,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] ?? '',
      isVendor: map['isVendor'] ?? false,
    );
  }
}
