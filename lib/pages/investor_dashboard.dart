import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Adjust these import paths and class names to match your exact files
import 'know_your_finances_page.dart'; 
import 'meet_and_greet_page.dart';

class InvestorDashboard extends StatefulWidget {
  final Map<String, dynamic>? initialSelectedUser;
  final String? initialSelectedUserId;

  const InvestorDashboard({
    super.key,
    this.initialSelectedUser,
    this.initialSelectedUserId,
  });

  @override
  State<InvestorDashboard> createState() => _InvestorDashboardState();
}

class _InvestorDashboardState extends State<InvestorDashboard> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream;
  String? _selectedUserId;
  Map<String, dynamic>? _selectedUserData;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    _selectedUserId = widget.initialSelectedUserId;
    _selectedUserData = widget.initialSelectedUser;
  }

  @override
  void didUpdateWidget(covariant InvestorDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedUserId != oldWidget.initialSelectedUserId) {
      setState(() {
        _selectedUserId = widget.initialSelectedUserId;
        _selectedUserData = widget.initialSelectedUser;
      });
    }
  }

  /// Handles secure user logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('paid');
      await prefs.remove('profileCompleted');
      await prefs.remove('investor_profileCompleted');

      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/loginPage',
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: ${e.toString()}")),
      );
    }
  }

  /// Opens contact us dialog or screen
  void _openContactUs(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Contact Us"),
        content: const Text(
            "Need help? Reach out to support at support@panpropertyadvisor.com"),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: const Color(0xFFFFD700),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _onTileTapped(String docId, Map<String, dynamic> data) {
    if (_selectedUserId != null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Selection"),
        content: Text(
            "Do you want to proceed with selecting ${data['fullName'] ?? data['name'] ?? 'this professional'}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _selectedUserId = docId;
                _selectedUserData = data;
              });
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const KnowYourFinancePage(),
              ),
            );
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Investor Dashboard",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
            ),
            SizedBox(height: 2),
            Text(
              "You can select one service at a time either Mortgage Broker or Buyer Agent",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFD700),
        actions: [
          TextButton(
            onPressed: () => _openContactUs(context),
            child: const Text(
              "Contact Us",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      bottomNavigationBar: _selectedUserId != null
          ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                final userDoc = snapshot.data?.data() ?? {};
                final status = userDoc['meetRequestStatus'];

                final bool isDisabled =
                    status == 'pending' || status == 'accepted';

                String buttonText = "Proceed to Meet & Greet";
                if (status == 'pending') {
                  buttonText = "Request Pending";
                } else if (status == 'accepted') {
                  buttonText = "Request Accepted";
                }

                return Container(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 12, bottom: 40),
                  color: Colors.white,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDisabled ? Colors.grey : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isDisabled
                        ? null
                        : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MeetAndGreetPage(
                                    selectedUser: _selectedUserData!),
                              ),
                            );

                            if (result != null &&
                                result is Map<String, dynamic>) {
                              setState(() {
                                _selectedUserId =
                                    result['id'] ?? _selectedUserId;
                                _selectedUserData =
                                    result['data'] ?? _selectedUserData;
                              });
                            } else {
                              setState(() {});
                            }
                          },
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: isDisabled
                            ? Colors.white70
                            : const Color(0xFFFFD700),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            )
          : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("Error loading data: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final mortgageBrokers = docs
              .where((doc) => doc.data()['role'] == 'mortgage_broker')
              .toList();

          final buyersAgents = docs
              .where((doc) => doc.data()['role'] == 'buyers_agent')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                    "Mortgage Brokers", Icons.account_balance, mortgageBrokers),
                const SizedBox(height: 24),
                _buildSection(
                    "Buyers Agents", Icons.real_estate_agent, buyersAgents),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, icon),
        const SizedBox(height: 8),
        if (items.isEmpty)
          _buildEmptyMessage("No $title registered yet.")
        else
          for (int index = 0; index < items.length; index++) ...[
            Opacity(
              opacity: (_selectedUserId != null &&
                      _selectedUserId != items[index].id)
                  ? 0.4
                  : 1.0,
              child: _buildUserTile(
                serialNumber: index + 1,
                data: items[index].data(),
                docId: items[index].id,
                isSelected: _selectedUserId == items[index].id,
                isDisabled: _selectedUserId != null &&
                    _selectedUserId != items[index].id,
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildUserTile({
    required int serialNumber,
    required Map<String, dynamic> data,
    required String docId,
    required bool isSelected,
    required bool isDisabled,
  }) {
    final name = data['fullName'] ?? data['name'] ?? 'Unnamed Profile';
    final company = data['companyName'] ?? '';
    final email = data['email'] ?? 'No email provided';
    final mobile = data['mobile'] ?? 'No mobile provided';

    return Card(
      color: isSelected ? const Color(0xFFFFF9C4) : Colors.white,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        enabled: !isDisabled,
        onTap: isDisabled || _selectedUserId != null
            ? null
            : () => _onTileTapped(docId, data),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: isDisabled ? Colors.grey : Colors.black,
          child: Text(
            '$serialNumber',
            style: TextStyle(
              color: isDisabled ? Colors.white : const Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDisabled ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (company.isNotEmpty) Text(company),
            Text(email, style: const TextStyle(fontSize: 12)),
            Text(mobile, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
            : null,
      ),
    );
  }
}