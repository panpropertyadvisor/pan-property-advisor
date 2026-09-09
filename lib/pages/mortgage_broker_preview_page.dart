// lib/pages/mortgage_broker_preview_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mortgage_broker_summary_page.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class MortgageBrokerPreviewPage extends StatefulWidget {
  final String fullName;
  final String title;
  final String companyName;
  final String experience;
  final File? profilePhoto;
  final File? companyLogo;

  // Existing network URLs (from Firestore when editing / opening from dashboard)
  final String? profilePhotoUrl;
  final String? companyLogoUrl;

  final String creditLicence;
  final String afcaNumber;
  final String aggregator;

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

  const MortgageBrokerPreviewPage({
    super.key,
    required this.fullName,
    required this.title,
    required this.companyName,
    required this.experience,
    required this.creditLicence,
    required this.afcaNumber,
    required this.aggregator,
    this.profilePhoto,
    this.companyLogo,
    this.profilePhotoUrl,
    this.companyLogoUrl,
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
  });

  @override
  State<MortgageBrokerPreviewPage> createState() =>
      _MortgageBrokerPreviewPageState();
}

class _MortgageBrokerPreviewPageState extends State<MortgageBrokerPreviewPage> {
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User session not found. Please log in again.");
      }

      // Start with existing network URLs so re-submit without re-picking
      // images does not wipe them from Firestore.
      String? profilePhotoUrl = widget.profilePhotoUrl;
      String? companyLogoUrl = widget.companyLogoUrl;

      // Upload Profile Photo only if a new local file was selected
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

      // Upload Company Logo only if a new local file was selected
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

      // Construct Payload
      final Map<String, dynamic> brokerData = {
        'fullName': widget.fullName,
        'title': widget.title,
        'companyName': widget.companyName,
        'experience': widget.experience,
        'creditLicence': widget.creditLicence,
        'afcaNumber': widget.afcaNumber,
        'aggregator': widget.aggregator,
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
        'role': 'mortgage_broker',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(brokerData, SetOptions(merge: true));

      // Update local flags
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profileCompleted', true);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MortgageBrokerSummaryPage(data: brokerData),
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
              if (widget.title.trim().isNotEmpty)
                _buildPreviewTile("Title", widget.title),
              _buildPreviewTile("Company Name", widget.companyName),
              _buildPreviewTile("Experience", "${widget.experience} years"),

              _buildSectionHeader("2. Licensing & Compliance"),
              _buildPreviewTile("Credit Licence Number", widget.creditLicence),
              _buildPreviewTile("AFCA Membership Number", widget.afcaNumber),
              _buildPreviewTile("Aggregator", widget.aggregator),

              _buildSectionHeader("3. Bio & Highlights"),
              _buildPreviewTile("Short Bio", widget.shortBio),
              _buildPreviewTile("Full Bio", widget.fullBio),
              _buildPreviewTile("What Makes You Different", widget.difference),
              _buildPreviewTile("Awards & Recognition", widget.awards),
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