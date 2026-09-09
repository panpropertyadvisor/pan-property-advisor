import 'package:flutter/material.dart';

class BuyersAgentSummaryPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const BuyersAgentSummaryPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buyers Agent - Profile Summary"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),

                      if (data['profilePhotoUrl'] != null && data['profilePhotoUrl'].toString().isNotEmpty) ...[
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              data['profilePhotoUrl'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (data['companyLogoUrl'] != null && data['companyLogoUrl'].toString().isNotEmpty) ...[
                        Center(
                          child: Image.network(
                            data['companyLogoUrl'],
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      _buildSummaryRow("Full Name", data['fullName']),
                      _buildSummaryRow("Title", data['title']),
                      _buildSummaryRow("Company Name", data['companyName']),
                      _buildSummaryRow("Experience", "${data['experience'] ?? ''} years"),
                      const Divider(),

                      const Text(
                        "2. Licensing & Focus Areas",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow("Licence Number", data['licenceNumber']),
                      _buildSummaryRow("AFCA Number", data['afcaNumber']),
                      _buildSummaryRow("Specialisation", data['specialisation']),
                      _buildSummaryRow("States", data['states']),
                      const Divider(),

                      const Text(
                        "3. Bio & Highlights",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow("Short Bio", data['shortBio']),
                      _buildSummaryRow("Full Bio", data['fullBio']),
                      _buildSummaryRow("Differentiators", data['difference']),
                      _buildSummaryRow("Awards", data['awards']),
                      _buildSummaryRow("Testimonials", data['testimonials']),
                      const Divider(),

                      const Text(
                        "4. Contact & Links",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow("Email", data['email']),
                      _buildSummaryRow("Mobile", data['mobile']),
                      _buildSummaryRow("LinkedIn", data['linkedin']),
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
                    Navigator.pushReplacementNamed(context, '/buyersAgentDashboard');
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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