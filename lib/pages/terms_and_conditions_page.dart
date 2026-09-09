// lib/pages/terms_and_conditions_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _accepted = false; // start unchecked by default
  bool _saving = false;
  bool _scrolledToEnd = false;

  @override
  void initState() {
    super.initState();
    // Intentionally NOT auto-loading persisted acceptedTerms here so the checkbox
    // starts unchecked on every page open. If you want to respect persisted acceptance,
    // call a loader here and remove the unused helper.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Mark scrolled-to-end when user reaches the bottom (small tolerance).
    if (!_scrolledToEnd &&
        _scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0 &&
        _scrollController.offset >= _scrollController.position.maxScrollExtent - 8) {
      setState(() => _scrolledToEnd = true);
    }
  }

  /// Accepts the terms, persists locally and (if signed in) to Firestore,
  /// then either returns `true` to the caller (if this page was pushed)
  /// or navigates to /aboutYou when opened as a root route.
  Future<void> _acceptTermsAndContinue() async {
    if (!_accepted) return;

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc();

      // Persist locally
      await prefs.setBool('acceptedTerms', true);
      await prefs.setString('acceptedTermsAt', now.toIso8601String());
      await prefs.setString('acceptedTermsVersion', 'v1'); // bump when terms change

      // Persist to Firestore if user is signed in
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'acceptedTerms': true,
          'acceptedTermsAt': now.toIso8601String(),
          'acceptedTermsVersion': 'v1',
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      // If this page was pushed from another page, return true to the caller.
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(true);
      } else {
        // Open AboutYou as replacement if this page is the root.
        Navigator.of(context).pushReplacementNamed('/aboutYou');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save acceptance. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // TERMS TEXT CONTAINER
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: const Text(
                        _termsText,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CHECKBOX + gating: disabled until scrolled to end
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _accepted,
                    activeColor: const Color(0xFFFFD700),
                    checkColor: Colors.black,
                    onChanged: _scrolledToEnd
                        ? (value) {
                            setState(() {
                              _accepted = value ?? false;
                            });
                          }
                        : null, // disabled until scrolled to end
                  ),
                  const Expanded(
                    child: Text(
                      'I accept the Terms & Conditions',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),

              if (!_scrolledToEnd)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Please scroll to the end of the terms to enable acceptance.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ),

              const SizedBox(height: 8),

              // CONFIRM BUTTON
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_accepted && !_saving) ? _acceptTermsAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accepted ? const Color(0xFFFFD700) : Colors.grey[800],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
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
}

/// Terms text kept as a single constant for clarity.
/// Replace or update this string as your legal team requires.
const String _termsText = """
PAN Property Advisor – Terms and Conditions (Australia)

1. General
PAN Property Advisor ("we", "us", "our") provides general information and tools to assist users in making property-related decisions in Australia. The information provided is of a general nature only and does not take into account your personal objectives, financial situation or needs. You should consider seeking independent legal, financial and taxation advice before making any decisions.

2. No Financial or Legal Advice
The content, calculators and outputs in this app are for informational purposes only and do not constitute financial, legal, taxation or other professional advice. We do not hold an Australian Financial Services Licence and do not provide personal financial product advice.

3. Accuracy and Limitations
While we endeavour to ensure the information and calculations are current and accurate, we do not warrant that they are complete, up to date or suitable for your particular circumstances. Stamp duty, taxes, fees and lending criteria may change and may vary by state or territory. You are responsible for verifying all figures with the relevant government authorities, lenders and advisers.

4. User Responsibilities
You are responsible for:
• Ensuring that all information you enter into the app is accurate and complete.
• Making your own assessment of the suitability of any property, loan or service.
• Obtaining independent professional advice where appropriate.

5. Use of Personal Data and Marketing
By using this app, you consent to the collection, storage and use of the personal information you provide, including but not limited to your name, contact details and property-related information.
Your data may be used:
• To operate and improve the app and related services.
• To communicate with you about your use of the app.
• For marketing and promotional purposes, including sending you information about products and services that may be of interest to you.
You may opt out of certain marketing communications by following the unsubscribe instructions in those communications, subject to applicable Australian privacy and spam laws.

6. Privacy
We aim to handle your personal information in accordance with applicable Australian privacy laws, including the Privacy Act 1988 (Cth) and the Australian Privacy Principles. We take reasonable steps to protect your personal information from misuse, interference, loss, unauthorised access, modification or disclosure. However, we cannot guarantee absolute security of data transmitted over the internet.

7. Third-Party Services
The app may integrate with or link to third-party services (including mortgage brokers, buyers agents, payment gateways and other providers). We are not responsible for the content, accuracy, terms, privacy practices or performance of any third-party services. Your dealings with third parties are solely between you and the relevant third party.

8. Limitation of Liability
To the maximum extent permitted by law, we exclude all liability for any loss, damage, cost or expense (including indirect or consequential loss) arising out of or in connection with:
• Your use of or reliance on the app, its content or outputs.
• Any errors or omissions in the information or calculations.
• Any acts or omissions of third-party providers.
Nothing in these terms excludes, restricts or modifies any consumer guarantees, rights or remedies that cannot be excluded under the Australian Consumer Law.

9. No Guarantee of Outcomes
We do not guarantee that you will obtain finance, secure a property, achieve any particular investment outcome or receive any particular service from a mortgage broker, buyers agent or other provider.

10. Payments and Subscriptions
Where subscription fees or one-off fees are payable (for example, by mortgage brokers or buyers agents), the applicable fees, billing cycles and cancellation terms will be disclosed at the time of sign-up. All fees are subject to change, subject to applicable Australian consumer and contract laws.

11. Changes to These Terms
We may update these Terms and Conditions from time to time. Continued use of the app after changes are made constitutes your acceptance of the updated terms.

12. Governing Law
These Terms and Conditions are governed by the laws of the State of New South Wales and the laws of the Commonwealth of Australia. You submit to the non-exclusive jurisdiction of the courts of New South Wales and the Commonwealth of Australia.

By using PAN Property Advisor, you acknowledge that you have read, understood and agree to be bound by these Terms and Conditions, including the use of your data for marketing purposes as described above.
""";
