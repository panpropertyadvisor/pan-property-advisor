// lib/pages/buyers_agent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart';
import 'buyers_agent_preview_page.dart';

class BuyersAgentDashboard extends StatefulWidget {
  const BuyersAgentDashboard({super.key});

  @override
  State<BuyersAgentDashboard> createState() => _BuyersAgentDashboardState();
}

class _BuyersAgentDashboardState extends State<BuyersAgentDashboard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Logout but KEEP role + userPasscode (+ email) so LoginPage shows passcode mode.
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
        await FirebaseFirestore.instance.collection('users').doc(investorId).set({
          'meetRequestStatus': 'accepted',
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaymentPage(
            amountPaid: null,
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

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}";
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  String _statesToString(dynamic states) {
    if (states is List) {
      return states.map((e) => e.toString()).join(', ');
    }
    return states?.toString() ?? '';
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
        title: const Text("Buyer's Agent Dashboard"),
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

          final agentData = snapshot.data!.data() ?? {};
          final String fullName =
              agentData['fullName'] ?? agentData['name'] ?? 'Agent';
          final String companyName = agentData['companyName'] ?? 'Independent';
          final String specialisation =
              agentData['specialisation'] ?? 'Generalist';
          final bool paid = agentData['paid'] ?? false;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(fullName, companyName, specialisation, paid),
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
                  _buildActionList(context, agentData),
                ],
              ),
            ),
          );
        },
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
                    child: const Text("Accept"),
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

  Widget _buildHeaderCard(
      String name, String company, String spec, bool paid) {
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
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
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
      BuildContext context, Map<String, dynamic> agentData) {
    return Column(
      children: [
        // ---------- 1. View & Edit Profile ----------
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text("View & Edit Profile"),
          subtitle: const Text("Update contact information, bio & compliance"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/buyersAgentDetails',
              arguments: agentData,
            );
          },
        ),
        const Divider(),

        // ---------- 2. Preview Profile ----------
        ListTile(
          leading: const Icon(Icons.remove_red_eye_outlined),
          title: const Text("Preview Profile"),
          subtitle: const Text("See how investors view your public profile"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuyersAgentPreviewPage(
                  fullName:
                      agentData['fullName']?.toString() ??
                      agentData['name']?.toString() ??
                      '',
                  title: agentData['title']?.toString() ?? '',
                  companyName: agentData['companyName']?.toString() ?? '',
                  experience: agentData['experience']?.toString() ??
                      agentData['yearsOfExperience']?.toString() ??
                      '',
                  licenceNumber: agentData['licenceNumber']?.toString() ??
                      agentData['licence']?.toString() ??
                      '',
                  afcaNumber: agentData['afcaNumber']?.toString() ??
                      agentData['afca']?.toString() ??
                      '',
                  specialisation: agentData['specialisation']?.toString() ?? '',
                  states: _statesToString(agentData['states']),
                  shortBio: agentData['shortBio']?.toString() ?? '',
                  fullBio: agentData['fullBio']?.toString() ??
                      agentData['bio']?.toString() ??
                      '',
                  difference: agentData['difference']?.toString() ?? '',
                  awards: agentData['awards']?.toString() ?? '',
                  testimonials: agentData['testimonials']?.toString() ?? '',
                  email: agentData['email']?.toString() ?? '',
                  mobile: agentData['mobile']?.toString() ??
                      agentData['phone']?.toString() ??
                      '',
                  officeAddress: agentData['officeAddress']?.toString() ?? '',
                  serviceAreas: agentData['serviceAreas']?.toString() ?? '',
                  linkedin: agentData['linkedin']?.toString() ?? '',
                  googleReviews: agentData['googleReviews']?.toString() ?? '',
                  website: agentData['website']?.toString() ?? '',
                  profilePhotoUrl: agentData['profilePhotoUrl']?.toString() ??
                      agentData['photoUrl']?.toString(),
                  companyLogoUrl: agentData['companyLogoUrl']?.toString() ??
                      agentData['logoUrl']?.toString(),
                  // Local files not available from dashboard; network URLs
                  // are shown only after BuyersAgentPreviewPage is extended
                  // to accept URL strings. Text fields still preview correctly.
                ),
              ),
            );
          },
        ),
        const Divider(),

        // ---------- 3. Subscription Details ----------
        ListTile(
          leading: const Icon(Icons.payment_outlined),
          title: const Text("Subscription Details"),
          subtitle: const Text("Manage payment status and invoices"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Amount is stored in cents
            final rawAmount = agentData['lastPaymentAmount'] ??
                agentData['subscriptionAmount'] ??
                agentData['amountPaid'] ??
                0;

            num amountNum = 0;
            if (rawAmount is num) {
              amountNum = rawAmount;
            } else if (rawAmount is String) {
              amountNum = num.tryParse(rawAmount) ?? 0;
            }

            final String amountDisplay =
                (amountNum / 100).toStringAsFixed(2);

            // Payment date
            final paymentDateTime = _parseDate(
              agentData['lastPaymentAt'] ??
                  agentData['paidAt'] ??
                  agentData['createdAt'] ??
                  agentData['paymentDate'],
            );

            // Expiry date – prefer stored subscriptionExpiry
            DateTime? expiryDateTime = _parseDate(
              agentData['subscriptionExpiry'] ??
                  agentData['subscriptionExpiresAt'] ??
                  agentData['expiryDate'] ??
                  agentData['expiresAt'],
            );

            // Monthly plan fallback: +30 days from payment (or today)
            if (expiryDateTime == null) {
              final base = paymentDateTime ?? DateTime.now();
              expiryDateTime = DateTime(base.year + 1, base.month, base.day);
            }

            final String paymentDateStr =
                paymentDateTime != null ? _formatDate(paymentDateTime) : 'N/A';
            final String expiryDateStr = _formatDate(expiryDateTime);

            final rawRole = agentData['role'] ?? 'buyers_agent';
            String userRole;
            switch (rawRole) {
              case 'mortgage_broker':
                userRole = 'Mortgage Broker';
                break;
              case 'investor':
                userRole = 'Investor';
                break;
              case 'buyers_agent':
              default:
                userRole = "Buyer's Agent";
                break;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentPage(
                  amountPaid: amountDisplay,
                  paymentDate: paymentDateStr,
                  expiryDate: expiryDateStr,
                  role: userRole,
                  isPaid: agentData['paid'] == true,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}