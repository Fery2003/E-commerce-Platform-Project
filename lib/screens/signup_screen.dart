import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(color: Colors.white),
              child: Stack(
                children: [
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 * -1.1,
                    top: MediaQuery.of(context).size.height / 2 * -0.2,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 2,
                      height: MediaQuery.of(context).size.height,
                      child: Stack(
                        children: [
                          Positioned(
                            left: MediaQuery.of(context).size.width / 2 * 1.5,
                            top: MediaQuery.of(context).size.height / 3.5,
                            child: Transform(
                              transform: Matrix4.identity()
                                ..translate(0.0, 0.0)
                                ..rotateZ(0.87)
                                ..invert(),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.84,
                                height: MediaQuery.of(context).size.height,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1EC0AC),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black,
                                      offset: Offset(1, 1),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: MediaQuery.of(context).size.width / 2 * 1.65,
                            top: MediaQuery.of(context).size.height / 4.2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width / 1.8,
                                  child: const Text(
                                    'Sign Up',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF2F2222),
                                      fontSize: 55,
                                      fontFamily: 'Basic',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.person_add,
                                  size: 50,
                                  color: Color(0xFF2F2222),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height / 2,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(20), // Add padding around the container
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 20,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFEAEAEA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontSize: 24,
                                  fontFamily: 'Basic',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscureText,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontSize: 24,
                                  fontFamily: 'Basic',
                                  fontWeight: FontWeight.w400,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureText,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'Confirm Password',
                                labelStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontSize: 24,
                                  fontFamily: 'Basic',
                                  fontWeight: FontWeight.w400,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () async {
                                if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Error'),
                                        content: const Text('Passwords do not match'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                }

                                try {
                                  final newUser = await _auth.createUserWithEmailAndPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  );
                                  if (newUser != null) {
                                    Navigator.pushReplacementNamed(context, '/products');
                                  }
                                } catch (e) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Error'),
                                        content: Text(e.toString()),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              child: Container(
                                width: 247,
                                height: 54,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFF1EC0AC),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  shadows: const [
                                    BoxShadow(
                                      color: Color(0x3F000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 4),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'Sign Up',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFE3E3E3),
                                      fontSize: 30,
                                      fontFamily: 'Basic',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/become_vendor');
                              },
                              child: const Text(
                                'Become a Vendor',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xB71EC0AC),
                                  fontSize: 16,
                                  fontFamily: 'Basic',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
