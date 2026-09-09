import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passcodeController = TextEditingController();

  bool _isPasscodeMode = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSavedLoginMode();
  }

  Future<void> _checkSavedLoginMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPasscode = prefs.getString('userPasscode');
    final savedRole = prefs.getString('role');

    if ((savedPasscode != null && savedPasscode.isNotEmpty) ||
        (savedRole != null && savedRole.isNotEmpty)) {
      setState(() {
        _isPasscodeMode = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isPasscodeMode = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  /// Wipe all local session data and return to Welcome (new user flow).
  Future<void> _clearLocalSessionAndGoWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;
    // Use '/' so main.dart StreamBuilder rebuilds as a brand-new user
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _loginWithPasscode() async {
    final enteredPasscode = _passcodeController.text.trim();

    if (enteredPasscode.length != 4) {
      setState(() => _errorMessage = "Passcode must be 4 digits.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final localPasscode = prefs.getString('userPasscode');
      String role = prefs.getString('role') ?? '';
      User? user = FirebaseAuth.instance.currentUser;

      bool passcodeMatched = false;

      // 1) If Auth session still exists, verify passcode against Firestore
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!doc.exists) {
          // User was deleted from Firestore – wipe stale local data
          await _clearLocalSessionAndGoWelcome();
          return;
        }

        final data = doc.data();
        if (data?['passcode']?.toString() == enteredPasscode) {
          role = (data?['role'] as String?) ?? role;
          passcodeMatched = true;
        }
      }

      // 2) Fallback: match against local passcode
      if (!passcodeMatched && localPasscode == enteredPasscode) {
        passcodeMatched = true;
      }

      if (!passcodeMatched) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Incorrect Passcode. Please try again.";
        });
        return;
      }

      // 3) Need a valid Firebase Auth session
      if (FirebaseAuth.instance.currentUser == null) {
        final savedEmail = prefs.getString('userEmail') ?? '';
        final savedPassword = prefs.getString('userPassword') ?? '';

        if (savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: savedEmail,
              password: savedPassword,
            );
          } on FirebaseAuthException catch (e) {
            // Account deleted or credentials invalid → clear and start over
            if (e.code == 'user-not-found' ||
                e.code == 'wrong-password' ||
                e.code == 'invalid-credential' ||
                e.code == 'user-disabled') {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    "This account no longer exists. Starting fresh…";
              });
              await Future.delayed(const Duration(milliseconds: 800));
              await _clearLocalSessionAndGoWelcome();
              return;
            }
            setState(() {
              _isLoading = false;
              _isPasscodeMode = false;
              _errorMessage =
                  "Could not restore session. Please log in with email & password.";
            });
            return;
          }
        } else {
          // No stored credentials – switch to email form (do NOT clear yet)
          setState(() {
            _isLoading = false;
            _isPasscodeMode = false;
            _errorMessage =
                "Please log in with email & password to restore your session.";
          });
          return;
        }
      }

      // 4) Auth OK – navigate based on live Firestore data
      await _navigateByRole(role);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Login error: ${e.toString()}";
      });
    }
  }

  Future<void> _loginWithEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter email and password.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Authentication failed.";
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Auth user exists but Firestore profile was deleted
      if (!doc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Account data was removed. Starting a new registration…";
        });
        await Future.delayed(const Duration(milliseconds: 800));
        await _clearLocalSessionAndGoWelcome();
        return;
      }

      final data = doc.data()!;
      final role = (data['role'] as String?) ?? '';
      final passcode = data['passcode']?.toString() ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', role);
      await prefs.setString('userEmail', email);
      await prefs.setString('userPassword', password);
      if (passcode.isNotEmpty) {
        await prefs.setString('userPasscode', passcode);
      }
      await prefs.setBool('paid', data['paid'] == true);
      await prefs.setBool(
          'profileCompleted', data['profileCompleted'] == true);

      await _navigateByRole(role);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        // Stale local session after Firebase user was deleted
        setState(() {
          _isLoading = false;
          _errorMessage =
              "No account found for this email. Clear session to register again.";
        });
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? "Authentication failed.";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error logging in: $e";
      });
    }
  }

  /// Navigate using LIVE Firestore flags (source of truth).
  Future<void> _navigateByRole(String role) async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Not signed in.";
      });
      return;
    }

    bool isPaid = false;
    bool isCompleted = false;
    String resolvedRole = role;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await _clearLocalSessionAndGoWelcome();
        return;
      }

      final data = doc.data()!;
      isPaid = data['paid'] == true;
      isCompleted = data['profileCompleted'] == true;
      resolvedRole = (data['role'] as String?) ?? role;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('paid', isPaid);
      await prefs.setBool('profileCompleted', isCompleted);
      await prefs.setString('role', resolvedRole);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not load profile: $e";
      });
      return;
    }

    if (!mounted) return;

    if (!isPaid) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/paymentPage', (route) => false);
      return;
    }

    if (!isCompleted) {
      if (resolvedRole == 'mortgage_broker') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/mortgageBrokerAboutYou', (route) => false);
      } else if (resolvedRole == 'buyers_agent') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/buyersAgentAboutYou', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/investorAboutYou', (route) => false);
      }
      return;
    }

    // Fully complete → dashboard
    if (resolvedRole == 'investor') {
      Navigator.pushNamedAndRemoveUntil(
          context, '/investorDashboard', (route) => false);
    } else if (resolvedRole == 'buyers_agent') {
      Navigator.pushNamedAndRemoveUntil(
          context, '/buyersAgentDashboard', (route) => false);
    } else if (resolvedRole == 'mortgage_broker') {
      Navigator.pushNamedAndRemoveUntil(
          context, '/mortgageBrokerDashboard', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, '/loginPage', (route) => false);
    }
  }

  void _switchToEmailLogin() {
    setState(() {
      _isPasscodeMode = false;
      _errorMessage = null;
    });
  }

  void _switchToPasscodeLogin() {
    setState(() {
      _isPasscodeMode = true;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFD700),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isPasscodeMode)
                _buildPasscodeView()
              else
                _buildEmailPasswordView(),
              const SizedBox(height: 32),
              // Always available escape hatch when local session is stale
              Center(
                child: TextButton(
                  onPressed: _clearLocalSessionAndGoWelcome,
                  child: const Text(
                    "Not you? Start over / New registration",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasscodeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome Back",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Enter your 4-digit passcode to continue.",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _passcodeController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: "4-Digit Passcode",
            border: OutlineInputBorder(),
            counterText: "",
          ),
          onFieldSubmitted: (_) => _loginWithPasscode(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: const Color(0xFFFFD700),
            ),
            onPressed: _loginWithPasscode,
            child: const Text(
              "Submit Passcode",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _switchToEmailLogin,
            child: const Text("Login with Email & Password instead"),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailPasswordView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sign In",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "Email",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _loginWithEmailPassword(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: const Color(0xFFFFD700),
            ),
            onPressed: _loginWithEmailPassword,
            child: const Text(
              "Login",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _switchToPasscodeLogin,
            child: const Text("Login with Passcode instead"),
          ),
        ),
      ],
    );
  }
}