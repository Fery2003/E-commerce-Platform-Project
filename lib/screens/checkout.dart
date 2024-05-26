import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class CheckoutScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'Credit Card';

  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _paypalEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _completeCheckout() async {
    print('Complete checkout button pressed');

    if ((_selectedPaymentMethod == 'Credit Card' || _selectedPaymentMethod == 'PayPal') && !_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to complete the checkout.')),
      );
      return;
    }

    print('Creating order data');
    // Create order data
    final orderData = {
      'email': user.email,
      'items': widget.cartItems.map((item) {
        var productData = item.data() as Map<String, dynamic>;
        return {
          'name': productData['name'] ?? 'Unknown',
          'price': productData['price'] ?? 0.0,
          'quantity': item['quantity'] ?? 0,
        };
      }).toList(),
      'total': _calculateTotal(),
      'paymentMethod': _selectedPaymentMethod,
      'createdAt': Timestamp.now(),
    };

    // Add order to Firestore
    await FirebaseFirestore.instance.collection('orders').add(orderData);

    // Delete all items from the user's cart
    var cartItemsCollection = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items');

    var batch = FirebaseFirestore.instance.batch();
    for (var cartItem in widget.cartItems) {
      batch.delete(cartItem.reference);
    }
    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checkout completed using $_selectedPaymentMethod')),
    );

    // Display the receipt
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              const Text('Your order has been placed successfully.'),
              const SizedBox(height: 10),
              Text('Payment Method: $_selectedPaymentMethod'),
              const SizedBox(height: 10),
              ...widget.cartItems.map((item) {
                var productData = item.data() as Map<String, dynamic>;
                var name = productData['name'] ?? 'Unknown';
                var price = productData['price'] ?? 0.0;
                var quantity = item['quantity'] ?? 0;
                return Text('$name - \$${price.toStringAsFixed(2)} x $quantity');
              }).toList(),
              const SizedBox(height: 10),
              Text('Total: \$${_calculateTotal().toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to the cart screen
            },
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double total = 0.0;
    for (var item in widget.cartItems) {
      var productData = item.data() as Map<String, dynamic>;
      var price = productData['price'] ?? 0.0;
      var quantity = item['quantity'] ?? 0;
      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: const Text('Credit Card'),
                leading: Radio<String>(
                  value: 'Credit Card',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('PayPal'),
                leading: Radio<String>(
                  value: 'PayPal',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Cash on Delivery'),
                leading: Radio<String>(
                  value: 'Cash on Delivery',
                  groupValue: _selectedPaymentMethod,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedPaymentMethod = value!;
                    });
                  },
                ),
              ),
              if (_selectedPaymentMethod == 'Credit Card') ...[
                const SizedBox(height: 16),
                const Text(
                  'Enter Credit Card Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 16) {
                      return 'Please enter a valid card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                        validator: (value) {
                          if (value == null || value.isEmpty || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                            return 'Please enter a valid expiry date (MM/YY)';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty || value.length != 3) {
                            return 'Please enter a valid CVV';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (_selectedPaymentMethod == 'PayPal') ...[
                const SizedBox(height: 16),
                const Text(
                  'Enter PayPal Email',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _paypalEmailController,
                  decoration: const InputDecoration(
                    labelText: 'PayPal Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _completeCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // Set the button color to teal
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32), // Increase the button size
                  ),
                  child: const Text(
                    'Complete Checkout',
                    style: TextStyle(fontSize: 18), // Increase the font size
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
