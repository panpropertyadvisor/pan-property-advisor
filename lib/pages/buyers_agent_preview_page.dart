// lib/pages/buyers_agent_preview_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'buyers_agent_summary_page.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class BuyersAgentPreviewPage extends StatefulWidget {
  final String fullName;
  final String title;
  final String companyName;
  final String experience;
  final String licenceNumber;
  final String afcaNumber;
  final String specialisation;
  final String states;
  final String shortBio;
  final String fullBio;
  final String difference;
  final String awards;
  final String testimonials;
  final String email;
  final String mobile;
  final String officeAddress;
  final String serviceAreas;
  final String linkedin;
  final String googleReviews;
  final String website;
  final File? profilePhoto;
  final File? companyLogo;

  // Existing network URLs (from Firestore when editing / opening from dashboard)
  final String? profilePhotoUrl;
  final String? companyLogoUrl;

  const BuyersAgentPreviewPage({
    super.key,
    required this.fullName,
    required this.title,
    required this.companyName,
    required this.experience,
    required this.licenceNumber,
    required this.afcaNumber,
    required this.specialisation,
    required this.states,
    required this.shortBio,
    required this.fullBio,
    required this.difference,
    required this.awards,
    required this.testimonials,
    required this.email,
    required this.mobile,
    required this.officeAddress,
    required this.serviceAreas,
    required this.linkedin,
    required this.googleReviews,
    required this.website,
    this.profilePhoto,
    this.companyLogo,
    this.profilePhotoUrl,
    this.companyLogoUrl,
  });

  @override
  State<BuyersAgentPreviewPage> createState() => _BuyersAgentPreviewPageState();
}

class _BuyersAgentPreviewPageState extends State<BuyersAgentPreviewPage> {
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User session not found. Please log in again.");
      }

      // Keep existing network URLs if user did not re-pick images
      String? profilePhotoUrl = widget.profilePhotoUrl;
      String? companyLogoUrl = widget.companyLogoUrl;

      // 1. Upload Profile Photo only if a new local file was selected
      if (widget.profilePhoto != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('user_photos/${user.uid}/profile.jpg');
          await ref.putFile(widget.profilePhoto!).timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception("Profile photo upload timed out."),
          );
          profilePhotoUrl = await ref.getDownloadURL();
        } catch (e) {
          debugPrint("Profile photo upload failed: $e");
        }
      }

      // 2. Upload Company Logo only if a new local file was selected
      if (widget.companyLogo != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('user_photos/${user.uid}/logo.jpg');
          await ref.putFile(widget.companyLogo!).timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception("Company logo upload timed out."),
          );
          companyLogoUrl = await ref.getDownloadURL();
        } catch (e) {
          debugPrint("Company logo upload failed: $e");
        }
      }

      // 3. Construct Payload
      final Map<String, dynamic> agentData = {
        'fullName': widget.fullName,
        'title': widget.title,
        'companyName': widget.companyName,
        'experience': widget.experience,
        'licenceNumber': widget.licenceNumber,
        'afcaNumber': widget.afcaNumber,
        'specialisation': widget.specialisation,
        'states': widget.states,
        'shortBio': widget.shortBio,
        'fullBio': widget.fullBio,
        'difference': widget.difference,
        'awards': widget.awards,
        'testimonials': widget.testimonials,
        'email': widget.email,
        'mobile': widget.mobile,
        'officeAddress': widget.officeAddress,
        'serviceAreas': widget.serviceAreas,
        'linkedin': widget.linkedin,
        'googleReviews': widget.googleReviews,
        'website': widget.website,
        if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
          'profilePhotoUrl': profilePhotoUrl,
        if (companyLogoUrl != null && companyLogoUrl.isNotEmpty)
          'companyLogoUrl': companyLogoUrl,
        'profileCompleted': true,
        'role': 'buyers_agent',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 4. Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(agentData, SetOptions(merge: true));

      // 5. Update local flags
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profileCompleted', true);
      await prefs.setBool('buyers_agent_profileCompleted', true);

      if (!mounted) return;

      // 6. Navigate to Summary
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => BuyersAgentSummaryPage(data: agentData),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Error submitting details: ${e.toString().replaceAll('Exception: ', '')}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImagePreview({
    required String label,
    File? file,
    String? networkUrl,
    double height = 100,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    Widget? imageWidget;

    if (file != null) {
      imageWidget = Image.file(file, height: height, width: width, fit: fit);
    } else if (networkUrl != null && networkUrl.isNotEmpty) {
      imageWidget = Image.network(
        networkUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    if (imageWidget == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageWidget,
        ),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview Profile Details")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profile Preview",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildSectionHeader("1. Personal & Professional Identity"),

              _buildImagePreview(
                label: "Profile Photo",
                file: widget.profilePhoto,
                networkUrl: widget.profilePhotoUrl,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),

              _buildImagePreview(
                label: "Company Logo",
                file: widget.companyLogo,
                networkUrl: widget.companyLogoUrl,
                height: 60,
                fit: BoxFit.contain,
              ),

              _buildPreviewTile("Full Name", widget.fullName),
              _buildPreviewTile("Title", widget.title),
              _buildPreviewTile("Company Name", widget.companyName),
              _buildPreviewTile("Experience", "${widget.experience} years"),

              _buildSectionHeader("2. Licensing & Focus Areas"),
              _buildPreviewTile("Licence Number", widget.licenceNumber),
              _buildPreviewTile("AFCA Number", widget.afcaNumber),
              _buildPreviewTile("Specialisation", widget.specialisation),
              _buildPreviewTile("Operating States", widget.states),

              _buildSectionHeader("3. Bio & Highlights"),
              _buildPreviewTile("Short Bio", widget.shortBio),
              _buildPreviewTile("Full Bio", widget.fullBio),
              _buildPreviewTile("What Makes You Different", widget.difference),
              _buildPreviewTile("Awards", widget.awards),
              _buildPreviewTile("Testimonials", widget.testimonials),

              _buildSectionHeader("4. Contact & Links"),
              _buildPreviewTile("Email Address", widget.email),
              _buildPreviewTile("Mobile Number", widget.mobile),
              _buildPreviewTile("Office Address", widget.officeAddress),
              _buildPreviewTile("Service Areas", widget.serviceAreas),
              _buildPreviewTile("LinkedIn", widget.linkedin),
              _buildPreviewTile("Google Reviews", widget.googleReviews),
              _buildPreviewTile("Website", widget.website),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit & Finish",
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildPreviewTile(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15)),
          const Divider(),
        ],
      ),
    );
  }
}