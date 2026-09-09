import 'package:flutter/material.dart';
import 'terms_and_conditions_page.dart';

class MortgageBrokerIntroPage extends StatefulWidget {
  const MortgageBrokerIntroPage({super.key});

  @override
  State<MortgageBrokerIntroPage> createState() =>
      _MortgageBrokerIntroPageState();
}

class _MortgageBrokerIntroPageState extends State<MortgageBrokerIntroPage> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mortgage Broker Introduction'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // -------------------------
              // HEADER
              // -------------------------
              const Text(
                'Welcome, Mortgage Broker',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------
              // INTRO CARD
              // -------------------------
              _buildDarkCard(
                '''
This section allows you to present your professional profile, achievements and sales data to potential customers.

You can:
• Add your bio and experience.
• Highlight your lending specialisations and success stories.
• Showcase your performance and customer outcomes.

Customers using PAN Property Advisor will be able to view your profile and may choose to contact you.

Important:
• A customer will contact only one mortgage broker at a time so they get exclusive access to you.
• You should respond promptly and professionally to any customer enquiries.
                ''',
              ),

              const SizedBox(height: 20),

              // -------------------------
              // FEES & SUBSCRIPTION
              // -------------------------
              const Text(
                'Fees and Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 10),

              _buildDarkCardRichText(),

              const SizedBox(height: 16),

              _buildDarkCard(
                '''
By participating, you agree that:
• Subscription fees may be charged on a recurring basis.
• The one-time fee of AUD 99 is payable each time a new customer selects you.
• You are responsible for complying with all applicable Australian laws, including credit and consumer laws.
                ''',
              ),

              const SizedBox(height: 20),

              // -------------------------
              // TERMS & CONDITIONS
              // -------------------------
              const Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 10),

              _buildDarkCard(
                '''
These terms are in addition to the general Terms and Conditions of PAN Property Advisor.

Key points:
• Customers will contact only one mortgage broker at a time so they get exclusive access to you.
• You may communicate with the customer via email, phone or other agreed channels.
• You must handle customer data in accordance with Australian privacy laws.
• You are solely responsible for any credit assistance, advice or services you provide.
• PAN Property Advisor does not guarantee any particular number of leads or conversions.
                ''',
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsAndConditionsPage(),
                    ),
                  );
                },
                child: const Text(
                  'View full Terms and Conditions',
                  style: TextStyle(color: Color(0xFFFFD700)),
                ),
              ),

              const SizedBox(height: 20),

              // -------------------------
              // ACCEPTANCE CHECKBOX
              // -------------------------
              Row(
                children: [
                  Checkbox(
                    value: _accepted,
                    activeColor: const Color(0xFFFFD700),
                    checkColor: Colors.black,
                    onChanged: (value) {
                      setState(() {
                        _accepted = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I accept the subscription fees, one-time fees and the Terms and Conditions.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // -------------------------
              // NEXT BUTTON
              // -------------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _accepted
                      ? () {
                          Navigator.pushNamed(
                              context, '/mortgageBrokerAboutYou');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _accepted ? const Color(0xFFFFD700) : Colors.grey[800],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------
  // DARK CARD (MATCHES T&C PAGE)
  // -------------------------
  Widget _buildDarkCard(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.55,
        ),
      ),
    );
  }

  // -------------------------
  // DARK RICH TEXT CARD
  // -------------------------
Widget _buildDarkCardRichText() {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[800]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "There is a small subscription fee of",
          textAlign: TextAlign.justify,
          style: TextStyle(color: Colors.white, fontSize: 15, height: 1.55),
        ),

        const SizedBox(height: 6),

        // GOLD TAG
        _goldTag("AUD 25 per month"),

        const SizedBox(height: 12),

        const Text(
          "Plus a one-time fee of",
          textAlign: TextAlign.justify,
          style: TextStyle(color: Colors.white, fontSize: 15, height: 1.55),
        ),

        const SizedBox(height: 6),

        // GOLD TAG
        _goldTag("AUD 99 whenever an investor selects you"),
      ],
    ),
  );
}

Widget _goldTag(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFD700),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    ),
  );
}


}
