import 'package:flutter/material.dart';

class MortgageBrokerSummaryPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const MortgageBrokerSummaryPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Broker Profile Summary"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "Profile Saved Successfully!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "1. Personal & Professional Identity",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow("Full Name", data['fullName']),
                      _buildSummaryRow("Company Name", data['companyName']),
                      _buildSummaryRow(
                          "Experience", "${data['experience'] ?? ''} years"),
                      const Divider(),

                      const Text(
                        "2. Licensing & Compliance",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                          "Credit Licence", data['creditLicence']),
                      _buildSummaryRow("AFCA Number", data['afcaNumber']),
                      _buildSummaryRow("Aggregator", data['aggregator']),
                      const Divider(),

                      const Text(
                        "3. Bio & Highlights",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow("Short Bio", data['shortBio']),
                      _buildSummaryRow("Full Bio", data['fullBio']),
                      _buildSummaryRow(
                          "Differentiators", data['difference']),
                      _buildSummaryRow("Awards", data['awards']),
                      _buildSummaryRow("Testimonials", data['testimonials']),
                      const Divider(),

                      const Text(
                        "4. Contact & Links",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow("Email", data['email']),
                      _buildSummaryRow("Mobile", data['mobile']),
                      _buildSummaryRow(
                          "Office Address", data['officeAddress']),
                      _buildSummaryRow("Service Areas", data['serviceAreas']),
                      _buildSummaryRow("LinkedIn", data['linkedin']),
                      _buildSummaryRow(
                          "Google Reviews", data['googleReviews']),
                      _buildSummaryRow("Website", data['website']),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, '/mortgageBrokerDashboard');
                  },
                  child: const Text("Go to Dashboard"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              "$label:",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}