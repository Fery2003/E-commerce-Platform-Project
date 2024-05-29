class CartModel {
  String productId;
  int quantity;
  double unitPrice; // Add unitPrice field
  double totalPrice;

  CartModel({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CartModel.fromMap(Map<String, dynamic> data) {
    return CartModel(
      productId: data['productId'] ?? '',
      quantity: data['quantity'] ?? 1,
      unitPrice: data['unitPrice']?.toDouble() ?? 0.0,
      totalPrice: data['totalPrice']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  void changeQuantity(int newQuantity) {
    quantity = newQuantity;
    totalPrice = calculateTotalPrice(unitPrice, newQuantity);
  }

  double calculateTotalPrice(double price, int quantity) {
    return price * quantity;
  }
}
