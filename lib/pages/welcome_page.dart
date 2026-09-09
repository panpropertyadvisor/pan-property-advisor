import 'package:flutter/material.dart';
import 'terms_and_conditions_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _hasAcceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Image.asset(
                  'assets/logo/logo2.png',
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                // TITLE
                const Text(
                  'Welcome to PAN Property Advisor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),

                const SizedBox(height: 32),

                // TERMS & CONDITIONS LINK
                TextButton(
                  onPressed: () async {
                    final accepted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsAndConditionsPage(),
                      ),
                    );

                    if (accepted == true) {
                      setState(() {
                        _hasAcceptedTerms = true;
                      });
                    }
                  },
                  child: const Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: TextDecoration.underline,   // ⭐ UNDERLINE
                      decorationColor: Colors.white,          // ⭐ MATCH COLOR
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Please read and accept the Terms and Conditions to proceed.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // GET STARTED BUTTON
                ElevatedButton(
                  onPressed: _hasAcceptedTerms
                      ? () {
                          Navigator.pushNamed(context, '/aboutYou');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasAcceptedTerms
                        ? const Color(0xFFFFD700)
                        : Colors.grey[800],
                    foregroundColor: _hasAcceptedTerms ? Colors.black : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}