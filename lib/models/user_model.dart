class UserModel {
  String uid;
  String email;
  bool isVendor;

  UserModel({
    required this.uid,
    required this.email,
    this.isVendor = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'isVendor': isVendor,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      isVendor: map['isVendor'] ?? false,
    );
  }
}
