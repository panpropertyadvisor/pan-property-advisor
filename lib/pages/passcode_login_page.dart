// lib/pages/passcode_login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasscodeLoginPage extends StatefulWidget {
  const PasscodeLoginPage({super.key});

  @override
  State<PasscodeLoginPage> createState() => _PasscodeLoginPageState();
}

class _PasscodeLoginPageState extends State<PasscodeLoginPage> {
  final _passcodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyPasscode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final enteredPasscode = _passcodeController.text.trim();
      final prefs = await SharedPreferences.getInstance();
      final savedPasscode = prefs.getString('userPasscode');
      final savedEmail = prefs.getString('userEmail');
      final savedPassword = prefs.getString('userPassword');

      // Check passcode against stored local passcode
      if (enteredPasscode != savedPasscode) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Incorrect Passcode. Please try again.';
        });
        return;
      }

      // Re-establish Firebase Auth session if currentUser is null
      if (FirebaseAuth.instance.currentUser == null) {
        if (savedEmail != null && savedPassword != null) {
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: savedEmail,
              password: savedPassword,
            );
          } catch (e) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/loginPage');
            return;
          }
        } else {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/loginPage');
          return;
        }
      }

      // Fetch profile data from Firestore
      Map<String, dynamic> userData = {};
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          userData = doc.data()!;
        }
      }

      final role = prefs.getString('role');
      if (!mounted) return;

      // Route and pass userData where appropriate
      if (role == 'mortgage_broker') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/mortgageBrokerDetails',
          (route) => false,
          arguments: userData,
        );
      } else if (role == 'buyers_agent') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/buyersAgentDashboard',
          (route) => false,
          arguments: userData,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/investorDashboard',
          (route) => false,
          arguments: userData,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Welcome Back'),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFD700),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Enter your passcode',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'You already have an account with us.\nEnter your 4-digit passcode to continue.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 40),

                // Passcode Field
                TextFormField(
                  controller: _passcodeController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 8,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: '4-digit Passcode',
                    labelStyle: const TextStyle(color: Colors.white70),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFD700),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your passcode';
                    }
                    if (value.trim().length != 4) {
                      return 'Passcode must be 4 digits';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _verifyPasscode(),
                ),

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ],

                const Spacer(),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPasscode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Optional: Start over
                Center(
                  child: TextButton(
                    onPressed: () async {
                      // Clear everything and go back to welcome
                      await FirebaseAuth.instance.signOut();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Not you? Start over',
                      style: TextStyle(
                        color: Colors.white54,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}