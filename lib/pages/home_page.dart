import 'package:flutter/material.dart';
import '../services/user_services.dart';
import '../models/app_user.dart';
import 'mortgage_broker_about_you_page.dart';
import 'investor_about_you_page.dart';
import 'buyers_agent_page.dart';
import 'profile_page.dart';

import 'package:flutter_application_1pan/pages/mortgage_broker_intro_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await UserService.getCurrentUser();
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await UserService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MortgageBrokerAboutYouPage(),
      ),
    );
  }

  void _openRoleScreen(String role) {
    switch (role) {
      case 'investor':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InvestorAboutYouPage()),
        );
        break;
      case 'broker':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MortgageBrokerIntroPage()),
        );
        break;
      case 'buyer':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BuyersAgentPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user != null
            ? "Welcome, ${_user!.name}"
            : "PAN Property Advisor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(user: _user),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_user != null)
              Text(
                "Your role: ${_user!.role.toUpperCase()}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),

            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Role-based quick actions
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DashboardCard(
                  title: "Investor tools",
                  icon: Icons.trending_up,
                  onTap: () => _openRoleScreen('investor'),
                ),
                _DashboardCard(
                  title: "Mortgage broker tools",
                  icon: Icons.account_balance,
                  onTap: () => _openRoleScreen('broker'),
                ),
                _DashboardCard(
                  title: "Buyer’s agent tools",
                  icon: Icons.home,
                  onTap: () => _openRoleScreen('buyer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
