// lib/pages/investor_terms_page.dart
import 'package:flutter/material.dart';

class InvestorTermsPage extends StatefulWidget {
  const InvestorTermsPage({super.key});

  @override
  State<InvestorTermsPage> createState() => _InvestorTermsPageState();
}

class _InvestorTermsPageState extends State<InvestorTermsPage> {
  bool _accepted = false;
  bool _showError = false;

  @override
  Widget build(BuildContext context) {
    const TextStyle bodyStyle = TextStyle(fontSize: 15, height: 1.4, color: Colors.black);
    final TextStyle boldBody = bodyStyle.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Investor Terms & Conditions"),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFD700),
      ),

      // FIX: Use SafeArea + Column + Expanded + Footer
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RichText(
                  text: TextSpan(
                    style: bodyStyle,
                    children: [
                      const TextSpan(text: '1. Purpose of Service\n'),
                      const TextSpan(text: 'PAN Property Advisor provides general property information, financial estimations, and investment tools. This service does not constitute financial, legal, or taxation advice.\n\n'),

                      const TextSpan(text: '2. No Financial Advice\n'),
                      const TextSpan(text: 'All insights are general in nature. Investors should seek independent professional advice before making financial decisions.\n\n'),

                      const TextSpan(text: '3. Accuracy of Information\n'),
                      const TextSpan(text: 'While reasonable efforts are made to ensure accuracy, PAN Property Advisor does not guarantee completeness or suitability of any information.\n\n'),

                      const TextSpan(text: '4. Investor Responsibilities\n'),
                      const TextSpan(text: 'You acknowledge that you are solely responsible for your investment decisions and will independently verify all calculations.\n\n'),

                      // Subscription Fees line made bold
                      TextSpan(text: '5. Subscription Fees\n', style: boldBody),
                      const TextSpan(text: 'By proceeding, you agree to a one time subscription fee of AUD 49.99.\n\n'),

                      const TextSpan(text: '6. Refunds\n'),
                      const TextSpan(text: 'Subscription fees are non-refundable except where required under Australian Consumer Law.\n\n'),

                        const TextSpan(text: '7. Limitation of Liability\n'),
                        const TextSpan(text: 'PAN Property Advisor is not liable for financial loss, investment outcomes, or decisions made based on app content.\n\n'),

                        const TextSpan(text: '8. Privacy & Data Use\n'),
                        const TextSpan(text: 'Your personal information will be handled in accordance with our Privacy Policy.\n\n'),

                        const TextSpan(text: '9. Acceptance\n'),
                        const TextSpan(text: 'By selecting "I Agree", you confirm acceptance of these Terms & Conditions and the ',
                        ),
                        const TextSpan(
                          text: 'AUD 49.99',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' one time subscription.\n'),
                    ],
                  ),
                ),
              ),
            ),

            // FIX: Footer stays ABOVE home bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Error message (shown when user tries to continue without agreeing)
                  if (_showError)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please agree to terms and conditions',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Checkbox + label
                      Row(
                        children: [
                          Checkbox(
                            value: _accepted,
                            onChanged: (value) {
                              setState(() {
                                _accepted = value ?? false;
                                if (_accepted) _showError = false;
                              });
                            },
                          ),
                          const Text(
                            "I Agree",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Continue button (always tappable; shows error if not accepted)
                      ElevatedButton(
                        onPressed: () {
                          if (_accepted) {
                            Navigator.pushNamed(context, '/investorAboutYou');
                          } else {
                            setState(() {
                              _showError = true;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accepted ? Colors.black : Colors.grey[900],
                          foregroundColor: const Color(0xFFFFD700),   // gold text
                          disabledForegroundColor: Colors.grey,        // optional
                          disabledBackgroundColor: Colors.grey[800],   // optional
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: _accepted ? const Color(0xFFFFD700) : Colors.grey,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFFFD700),   // ensures gold text ALWAYS
                          ),
                        ),
                      )
                    ],
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
