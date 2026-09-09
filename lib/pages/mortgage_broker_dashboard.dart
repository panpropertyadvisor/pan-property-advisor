import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart';
import 'mortgage_broker_preview_page.dart';
import 'mortgage_broker_details_page.dart';

class MortgageBrokerDashboard extends StatefulWidget {
  const MortgageBrokerDashboard({super.key});

  @override
  State<MortgageBrokerDashboard> createState() => _MortgageBrokerDashboardState();
}

class _MortgageBrokerDashboardState extends State<MortgageBrokerDashboard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Helper to convert dynamic timestamp or string date formats to a readable DD/MM/YYYY string
  String _formatDate(dynamic rawDate, {int addYears = 0}) {
    DateTime? dt;
    if (rawDate is Timestamp) {
      dt = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      dt = DateTime.tryParse(rawDate);
    }

    if (dt == null) {
      if (addYears > 0) {
        dt = DateTime.now();
      } else {
        return 'N/A';
      }
    }

    if (addYears > 0) {
      dt = DateTime(dt.year + addYears, dt.month, dt.day);
    }

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return "$day/$month/${dt.year}";
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString('role');
    final passcode = prefs.getString('userPasscode');
    final email = prefs.getString('userEmail');
    final password = prefs.getString('userPassword');

    await prefs.clear();

    if (role != null && role.isNotEmpty) {
      await prefs.setString('role', role);
    }
    if (passcode != null && passcode.isNotEmpty) {
      await prefs.setString('userPasscode', passcode);
    }
    if (email != null && email.isNotEmpty) {
      await prefs.setString('userEmail', email);
    }
    if (password != null && password.isNotEmpty) {
      await prefs.setString('userPassword', password);
    }

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/loginPage', (route) => false);
  }

  Future<void> _acceptMeetRequest(
    String requestId,
    Map<String, dynamic> request,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('meet_requests')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      final investorId = request['investorId'];
      if (investorId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(investorId)
            .set({
          'meetRequestStatus': 'accepted',
          'assignedBrokerId': currentUser?.uid,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaymentPage(
            amountPaid: '99.00',
            paymentDate: null,
            isPaid: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mortgage Broker Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No profile data found."));
          }

          final brokerData = snapshot.data!.data() ?? {};
          final String fullName =
              brokerData['fullName'] ?? brokerData['name'] ?? 'Broker';
          final String companyName =
              brokerData['companyName'] ?? 'Independent';
          final String specialisation =
              brokerData['specialisation'] ?? 'Mortgage Specialist';
          final bool paid = brokerData['paid'] ?? false;
          
          final String? photoUrl =
              brokerData['profilePhotoUrl'] ?? brokerData['photoUrl'];

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(
                      fullName, companyName, specialisation, paid, photoUrl),
                  const SizedBox(height: 20),
                  _buildPendingRequests(),
                  const Text(
                    "Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsGrid(),
                  const SizedBox(height: 20),
                  const Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildActionList(context, brokerData),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
      String name, String company, String spec, bool paid, String? photoUrl) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'B',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text("$company • $spec"),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: paid
                          ? Colors.green.shade100
                          : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      paid ? "Active Membership" : "Payment Pending",
                      style: TextStyle(
                        fontSize: 12,
                        color: paid
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequests() {
    final uid = currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('meet_requests')
          .where('professionalId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pending Meet & Greet Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data = doc.data();
              final investorName = data['investorName'] ?? 'Investor';
              final message = data['message'] ?? '';

              return Card(
                child: ListTile(
                  title: Text(investorName),
                  subtitle: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _acceptMeetRequest(doc.id, data),
                    child: const Text("Accept (AUD \$99)"),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
            child: _buildStatTile(
                "Enquiries", "0", Icons.email_outlined, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatTile(
                "Leads", "0", Icons.people_outline, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatTile(
                "Profile Views", "0", Icons.visibility_outlined, Colors.green)),
      ],
    );
  }

  Widget _buildStatTile(
      String label, String count, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionList(
      BuildContext context, Map<String, dynamic> brokerData) {
    return Column(
      children: [
      // REPLACE this ListTile onTap:
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: const Text("View & Edit Profile"),
        subtitle: const Text("Update contact information, bio & compliance"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MortgageBrokerDetailsPage(
                initialData: brokerData,
              ),
            ),
          );
        },
      ),
        const Divider(),

        ListTile(
          leading: const Icon(Icons.preview_outlined),
          title: const Text("Preview Profile"),
          subtitle: const Text("See how your profile looks to clients"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MortgageBrokerPreviewPage(
                  fullName: brokerData['fullName'] ?? brokerData['name'] ?? '',
                  title: brokerData['title'] ?? '',
                  companyName: brokerData['companyName'] ?? '',
                  experience: brokerData['experience']?.toString() ?? '',
                  creditLicence: brokerData['creditLicence'] ?? '',
                  afcaNumber: brokerData['afcaNumber'] ?? '',
                  aggregator: brokerData['aggregator'] ?? '',
                  profilePhoto: null,
                  companyLogo: null,
                  profilePhotoUrl: brokerData['profilePhotoUrl']?.toString() ??
                      brokerData['photoUrl']?.toString(),
                  companyLogoUrl: brokerData['companyLogoUrl']?.toString() ??
                      brokerData['logoUrl']?.toString(),
                  shortBio: brokerData['shortBio'] ?? '',
                  fullBio: brokerData['fullBio'] ?? '',
                  difference: brokerData['difference'] ?? '',
                  awards: brokerData['awards'] ?? '',
                  testimonials: brokerData['testimonials'] ?? '',
                  email: brokerData['email'] ?? '',
                  mobile: brokerData['mobile'] ?? '',
                  officeAddress: brokerData['officeAddress'] ?? '',
                  serviceAreas: brokerData['serviceAreas'] ?? '',
                  linkedin: brokerData['linkedin'] ?? '',
                  googleReviews: brokerData['googleReviews'] ?? '',
                  website: brokerData['website'] ?? '',
                ),
              ),
            );
          },
        ),
        const Divider(),

        ListTile(
          leading: const Icon(Icons.payment_outlined),
          title: const Text("Subscription Details"),
          subtitle: const Text("Manage payment status and invoices"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final amountCents = brokerData['lastPaymentAmount'] ??
                brokerData['subscriptionAmount'] ??
                0;
            final amountDisplay = (amountCents is num)
                ? (amountCents / 100).toStringAsFixed(2)
                : '0.00';

            final rawPaymentDate = brokerData['lastPaymentAt'] ?? brokerData['createdAt'];
            final paymentDateStr = _formatDate(rawPaymentDate);

            final rawExpiryDate = brokerData['subscriptionExpiry'] ?? brokerData['expiryDate'];
            // If explicit expiry does not exist, calculate +1 year from payment date or today
            final expiryDateStr = (rawExpiryDate != null)
                ? _formatDate(rawExpiryDate)
                : _formatDate(rawPaymentDate, addYears: 1);

            final String userRole = brokerData['role'] ?? 'Mortgage Broker';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentPage(
                  amountPaid: amountDisplay,
                  paymentDate: paymentDateStr,
                  expiryDate: expiryDateStr,
                  role: userRole,
                  isPaid: brokerData['paid'] == true,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}