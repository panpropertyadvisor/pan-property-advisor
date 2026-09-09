import 'package:flutter/material.dart';
import 'terms_and_conditions_page.dart';

class BuyersAgentIntroPage extends StatefulWidget {
  const BuyersAgentIntroPage({super.key});

  @override
  State<BuyersAgentIntroPage> createState() => _BuyersAgentIntroPageState();
}

class _BuyersAgentIntroPageState extends State<BuyersAgentIntroPage> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyers Agent Introduction'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome, Buyers Agent',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '''
This section allows you to present your professional profile, experience and property buying expertise to potential investors.

You can:
- Add your bio and experience.
- Highlight your property search specialisations and success stories.
- Showcase your performance and customer outcomes.

Investors using PAN Property Advisor will be able to view your profile and may choose to contact you.

Important:
- A customer will contact only one buyers agent at a time so they get exclusive access to you.
- You should respond promptly and professionally to any customer enquiries.
                ''',
              ),
              const SizedBox(height: 16),
              const Text(
                'Fees and Subscription',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: 'There is a small subscription fee of '),
                    TextSpan(
                      text: 'AUD 29 per month',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: ', plus a one-time fee of '),
                    TextSpan(
                      text: 'AUD 149 whenever an investor selects you',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '''
By participating, you agree that:
- Subscription fees may be charged on a recurring basis.
- The one-time fee of AUD 149 is payable each time a new customer selects you.
- You are responsible for complying with all applicable Australian laws, including property, consumer and privacy laws.
                ''',
              ),
              const SizedBox(height: 16),
              const Text(
                'Terms and Conditions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '''
These terms are in addition to the general Terms and Conditions of PAN Property Advisor.

Key points:
- Customers will contact only one buyers agent at a time so they get exclusive access to you.
- You may communicate with the customer via email, phone or other agreed channels.
- You must handle customer data in accordance with Australian privacy laws.
- You are solely responsible for any property advice or services you provide.
- PAN Property Advisor does not guarantee any particular number of leads or conversions.
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
                child: const Text('View full Terms and Conditions'),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _accepted,
                    onChanged: (value) {
                      setState(() {
                        _accepted = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I accept the subscription fees, one-time fees and the Terms and Conditions.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _accepted
                      ? () {
                          Navigator.pushNamed(
                              context, '/buyersAgentAboutYou');
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
