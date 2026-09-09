import 'package:flutter/material.dart';
import 'package:flutter_application_1pan/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MortgageBrokerAboutYouPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool isEditing;

  const MortgageBrokerAboutYouPage({
    super.key,
    this.initialData,
    this.isEditing = false,
  });

  @override
  State<MortgageBrokerAboutYouPage> createState() => _MortgageBrokerAboutYouPageState();
}

class _MortgageBrokerAboutYouPageState
    extends State<MortgageBrokerAboutYouPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passcodeController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isAlreadyRegistered = false;
  bool _isLoading = true;

  bool _emailExists = false;
  bool _checkingEmail = false;

  bool _otpSent = false;
  bool _emailVerified = false;
  bool _canSendOtp = false;
  bool _otpValidLength = false;
  bool _sendingOtp = false;
  bool _showPaymentSection = false;

  String _statusMessage = "";

  @override
  void initState() {
    super.initState();

    // Pre-fill form controllers if initialData was provided
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _nameController.text = data['fullName'] ?? data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _mobileController.text = data['mobile'] ?? '';
      // Pre-fill any other fields as needed
    }

    // Register listeners
    _checkRegistrationStatus();
    _nameController.addListener(_updateSendOtpState);
    _emailController.addListener(_onEmailChanged);
    _mobileController.addListener(_updateSendOtpState);
    _passwordController.addListener(_updateSendOtpState);
    _passcodeController.addListener(_updateSendOtpState);
    _otpController.addListener(_checkOtpLength);
  }

  Future<void> _checkRegistrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    bool isCompleted = false;

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          if (data?['role'] == 'mortgage_broker' &&
              (data?['profileCompleted'] ?? false)) {
            isCompleted = true;
          }
        } else {
          await prefs.clear();
          await FirebaseAuth.instance.signOut();
          isCompleted = false;
        }
      } catch (e) {
        debugPrint("Error checking registration status: $e");
        isCompleted = false;
      }
    } else {
      isCompleted = false;
    }

    if (mounted) {
      setState(() {
        _isAlreadyRegistered = isCompleted;
        _isLoading = false;
      });
    }
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (emailRegex.hasMatch(email)) {
      _checkEmailExists(email);
    } else {
      if (_emailExists) {
        setState(() {
          _emailExists = false;
        });
      }
    }
    _updateSendOtpState();
  }

  Future<void> _checkEmailExists(String email) async {
    setState(() => _checkingEmail = true);
    try {
      final signInMethods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (mounted) {
        setState(() {
          _emailExists = signInMethods.isNotEmpty;
          _checkingEmail = false;
        });
        _updateSendOtpState();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checkingEmail = false);
      }
    }
  }

  void _resetRegistrationView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();

    setState(() {
      _isAlreadyRegistered = false;
      _nameController.clear();
      _emailController.clear();
      _mobileController.clear();
      _passwordController.clear();
      _passcodeController.clear();
      _otpController.clear();
      _otpSent = false;
      _emailVerified = false;
      _showPaymentSection = false;
      _emailExists = false;
      _statusMessage = "";
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _passcodeController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  bool _isNumeric(String s) => double.tryParse(s) != null;

  void _updateSendOtpState() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();
    final passcode = _passcodeController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    setState(() {
      _canSendOtp = name.isNotEmpty &&
          emailRegex.hasMatch(email) &&
          !_emailExists &&
          mobile.isNotEmpty &&
          mobile.length >= 8 &&
          password.length >= 6 &&
          passcode.length == 4 &&
          _isNumeric(passcode);
    });
  }

  void _checkOtpLength() {
    setState(() {
      _otpValidLength = _otpController.text.trim().length == 6;
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    setState(() {
      _sendingOtp = true;
      _statusMessage = "Checking email availability...";
    });

    try {
      final signInMethods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _sendingOtp = false;
          _emailExists = true;
          _statusMessage = "";
        });
        _updateSendOtpState();
        return;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        if (!mounted) return;
        setState(() {
          _sendingOtp = false;
          _emailExists = true;
          _statusMessage = "";
        });
        _updateSendOtpState();
        return;
      }
    } catch (_) {}

    setState(() {
      _statusMessage = "Sending OTP to your email...";
    });

    try {
      final success = await ApiService.sendOtp(email);
      if (!mounted) return;

      if (success) {
        setState(() {
          _sendingOtp = false;
          _otpSent = true;
          _statusMessage = "OTP sent to your email address";
        });

        FocusScope.of(context).requestFocus(_otpFocusNode);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your email')),
        );
      } else {
        setState(() {
          _sendingOtp = false;
          _statusMessage = "Failed to send OTP";
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sendingOtp = false;
        _statusMessage = "Error sending OTP";
      });
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    final success = await ApiService.verifyOtp(email, otp);

    if (!mounted) return;

    if (success) {
      setState(() {
        _emailVerified = true;
        _statusMessage = "OTP Verified! Saving your profile...";
      });
      await _handleSaveProfile();
    } else {
      setState(() {
        _statusMessage = "OTP is invalid. Enter correct OTP";
      });
    }
  }

Future<void> _verifyPasscodeLogin() async {
  final enteredPasscode = _passcodeController.text.trim();

  if (enteredPasscode.length != 4) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passcode must be 4 digits')),
    );
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final savedPasscode = prefs.getString('userPasscode');
  final savedEmail = prefs.getString('userEmail');
  final savedPassword = prefs.getString('userPassword');

  if (savedPasscode != enteredPasscode) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incorrect Passcode. Please try again.')),
    );
    return;
  }

  // 1. Re-authenticate session if Firebase Auth state was lost
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

  // 2. Fetch Firestore user document so initialData isn't empty
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

  if (!mounted) return;

  // 3. Pass userData as arguments to populate the mortgage route
  Navigator.pushNamed(
    context, 
    '/mortgageBrokerDetails', 
    arguments: userData,
  );
}

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        user = credential.user;
      }

      if (user == null) throw Exception("User creation failed.");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'role': 'mortgage_broker',
        'paid': false,
        'profileCompleted': false,
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'name': _nameController.text.trim(),
        'passcode': _passcodeController.text.trim(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', 'mortgage_broker');
      await prefs.setString('userPasscode', _passcodeController.text.trim());
      await prefs.setString('userEmail', _emailController.text.trim());
      await prefs.setString('userPassword', _passwordController.text.trim());
      await prefs.setBool('paid', false);
      await prefs.setBool('profileCompleted', false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your profile has been saved")),
      );

      setState(() {
        _showPaymentSection = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use') {
        setState(() {
          _emailExists = true;
        });
        _formKey.currentState?.validate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save profile: ${e.message}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('About You – Mortgage Broker')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _isAlreadyRegistered
              ? _buildPasscodeOnlyView()
              : _buildRegistrationForm(),
        ),
      ),
    );
  }

  Widget _buildPasscodeOnlyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome Back',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your 4-digit passcode to proceed.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _passcodeController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: const InputDecoration(
            labelText: 'Enter 4-digit Passcode',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _verifyPasscodeLogin,
            child: const Text('Submit'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _resetRegistrationView,
            child: const Text("New Registration / Register with another email"),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameController,
            enabled: !_emailVerified,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Name *',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _emailController,
            enabled: !_emailVerified,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: 'Email address *',
              border: const OutlineInputBorder(),
              suffixIcon: _checkingEmail
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                return 'Enter valid email';
              }
              if (_emailExists) return 'Email already in use';
              return null;
            },
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _mobileController,
            enabled: !_emailVerified,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Mobile number *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 12,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Mobile is required';
              if (!_isNumeric(v.trim())) return 'Numeric values only';
              return null;
            },
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _passwordController,
            enabled: !_emailVerified,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Create Password *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().length < 6
                ? 'Password must be >= 6 chars'
                : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _passcodeController,
            enabled: !_emailVerified,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Create 4-digit Passcode *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            validator: (v) {
              if (v == null ||
                  v.trim().length != 4 ||
                  !_isNumeric(v.trim())) {
                return 'Passcode must be 4 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          if (!_emailVerified) ...[
            Row(
              children: [
                ElevatedButton(
                  onPressed: (_canSendOtp && !_sendingOtp) ? _sendOtp : null,
                  child: _sendingOtp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_otpSent ? 'Resend OTP' : 'Send OTP'),
                ),
                const SizedBox(width: 12),
                if (_otpSent)
                  Expanded(
                    child: TextFormField(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-digit OTP',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                  ),
              ],
            ),
            if (_otpValidLength && _otpSent) ...[
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text("Verify OTP & Register"),
                ),
              ),
            ],
          ],

          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _emailVerified ? Colors.green : Colors.orange,
                ),
              ),
            ),

          if (_showPaymentSection) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              "Registration Fee – AUD 25",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/paymentPage'),
                child: const Text("Proceed to Payment"),
              ),
            ),
          ],
        ],
      ),
    );
  }
}