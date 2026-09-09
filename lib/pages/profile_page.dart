import 'package:flutter/material.dart';
import '../models/app_user.dart';

class ProfilePage extends StatelessWidget {
  final AppUser? user;

  const ProfilePage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(
          child: Text("No user data available."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${user!.name}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Email: ${user!.email}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Mobile: ${user!.mobile}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Role: ${user!.role}", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
