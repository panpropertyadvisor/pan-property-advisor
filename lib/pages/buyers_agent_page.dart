import 'package:flutter/material.dart';

class BuyersAgentPage extends StatelessWidget {
  const BuyersAgentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyers Agent'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'This section will allow buyers agents to add their profile, '
          'bio, achievements and fee structure. Customers will be able to '
          'view and select one buyers agent at a time.\n\n'
          'This is a placeholder page for now.',
        ),
      ),
    );
  }
}
