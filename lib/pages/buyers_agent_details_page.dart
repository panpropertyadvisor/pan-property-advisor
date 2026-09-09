// lib/pages/buyers_agent_details_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'buyers_agent_preview_page.dart';

class BuyersAgentDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const BuyersAgentDetailsPage({
    super.key,
    this.initialData,
  });

  @override
  State<BuyersAgentDetailsPage> createState() => _BuyersAgentDetailsPageState();
}

class _BuyersAgentDetailsPageState extends State<BuyersAgentDetailsPage> {
  bool _showSection2 = false;
  bool _showSection3 = false;
  String _errorMessage = "";

  File? _profilePhoto;
  File? _companyLogo;

  String? _profileImageUrl;
  String? _companyLogoUrl;

  // Track touched state for inputs to prevent preemptive red validation errors
  final Map<String, bool> _touched = {};

  final _fullNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _experienceController = TextEditingController();

  final _licenceController = TextEditingController();
  final _afcaController = TextEditingController();

  final _shortBioController = TextEditingController();
  final _fullBioController = TextEditingController();
  final _differenceController = TextEditingController();
  final _awardsController = TextEditingController();
  final _testimonialsController = TextEditingController();

  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _availabilityController = TextEditingController();

  final _officeAddressController = TextEditingController();
  final _serviceAreasController = TextEditingController();

  final _linkedinController = TextEditingController();
  final _googleReviewsController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _selectedSpecialisation;
  final List<String> _selectedStates = [];
  bool _onlineAppointments = false;

  bool _showEmailToCustomers = true;
  bool _showMobileToCustomers = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    if (data != null && data.isNotEmpty) {
      _isEditing = true;

      _fullNameController.text =
          data['fullName']?.toString() ?? data['name']?.toString() ?? '';
      _titleController.text = data['title']?.toString() ?? '';
      _companyNameController.text = data['companyName']?.toString() ?? '';
      _experienceController.text = data['experience']?.toString() ??
          data['yearsOfExperience']?.toString() ??
          '';
      _licenceController.text = data['licenceNumber']?.toString() ??
          data['licence']?.toString() ??
          '';
      _afcaController.text =
          data['afcaNumber']?.toString() ?? data['afca']?.toString() ?? '';
      _selectedSpecialisation = data['specialisation']?.toString();

      // Prefer keys written by preview submit (profilePhotoUrl / companyLogoUrl)
      _profileImageUrl = data['profilePhotoUrl']?.toString() ??
          data['profileImageUrl']?.toString() ??
          data['photoUrl']?.toString() ??
          data['imageUrl']?.toString();
      _companyLogoUrl = data['companyLogoUrl']?.toString() ??
          data['logoUrl']?.toString();

      // States – support List or comma-separated String
      final states = data['states'];
      if (states is List) {
        _selectedStates
          ..clear()
          ..addAll(states.map((e) => e.toString()));
      } else if (states is String && states.isNotEmpty) {
        _selectedStates
          ..clear()
          ..addAll(states
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty));
      }

      _shortBioController.text = data['shortBio']?.toString() ?? '';
      _fullBioController.text =
          data['fullBio']?.toString() ?? data['bio']?.toString() ?? '';
      _differenceController.text = data['difference']?.toString() ?? '';
      _awardsController.text = data['awards']?.toString() ?? '';
      _testimonialsController.text = data['testimonials']?.toString() ?? '';
      _emailController.text = data['email']?.toString() ?? '';
      _mobileController.text =
          data['mobile']?.toString() ?? data['phone']?.toString() ?? '';
      _availabilityController.text = data['availability']?.toString() ??
          data['availabilityHours']?.toString() ??
          '';
      _officeAddressController.text = data['officeAddress']?.toString() ?? '';
      _serviceAreasController.text = data['serviceAreas']?.toString() ?? '';
      _linkedinController.text = data['linkedin']?.toString() ?? '';
      _googleReviewsController.text = data['googleReviews']?.toString() ?? '';
      _websiteController.text = data['website']?.toString() ?? '';
      _onlineAppointments = data['onlineAppointments'] == true;
      _showEmailToCustomers = data['showEmailToCustomers'] ?? true;
      _showMobileToCustomers = data['showMobileToCustomers'] ?? true;

      // Always open full form when editing
      _showSection2 = true;
      _showSection3 = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _titleController.dispose();
    _companyNameController.dispose();
    _experienceController.dispose();
    _licenceController.dispose();
    _afcaController.dispose();
    _shortBioController.dispose();
    _fullBioController.dispose();
    _differenceController.dispose();
    _awardsController.dispose();
    _testimonialsController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _availabilityController.dispose();
    _officeAddressController.dispose();
    _serviceAreasController.dispose();
    _linkedinController.dispose();
    _googleReviewsController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _showFloatingMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _validateSection1() {
    return _fullNameController.text.trim().length >= 3 &&
        _companyNameController.text.trim().isNotEmpty &&
        _experienceController.text.trim().isNotEmpty;
  }

  bool _validateSection2() {
    return _licenceController.text.trim().isNotEmpty &&
        _afcaController.text.trim().isNotEmpty &&
        _selectedSpecialisation != null &&
        _selectedStates.isNotEmpty;
  }

  bool _validateContactVisibility() {
    return _showEmailToCustomers || _showMobileToCustomers;
  }

  bool _validateAll() {
    return _validateSection1() &&
        _validateSection2() &&
        _shortBioController.text.trim().isNotEmpty &&
        _emailController.text.contains("@") &&
        _mobileController.text.trim().length >= 8 &&
        _validateContactVisibility();
  }

  Future<void> _pickImage(bool isProfilePhoto) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        if (isProfilePhoto) {
          _profilePhoto = File(file.path);
          // Clear old network URL so the new local file is shown
          _profileImageUrl = null;
        } else {
          _companyLogo = File(file.path);
          _companyLogoUrl = null;
        }
      });
    }
  }

  void _attemptSave() {
    setState(() {
      _touched['Full Name *'] = true;
      _touched['Company Name *'] = true;
      _touched['Years of Experience *'] = true;
      _touched['Buyers Agent Licence Number *'] = true;
      _touched['AFCA Membership Number *'] = true;
      _touched['Short Bio *'] = true;
      _touched['Email Address *'] = true;
      _touched['Mobile Number *'] = true;
    });

    if (!_validateAll()) {
      if (!_validateContactVisibility()) {
        _showFloatingMessage(
            "At least one contact method should be made available.");
      } else {
        _showFloatingMessage("Please complete all mandatory fields.");
      }
      setState(() {
        _errorMessage = "Please complete mandatory fields";
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyersAgentPreviewPage(
          fullName: _fullNameController.text,
          title: _titleController.text,
          companyName: _companyNameController.text,
          experience: _experienceController.text,
          licenceNumber: _licenceController.text,
          afcaNumber: _afcaController.text,
          specialisation: _selectedSpecialisation ?? '',
          states: _selectedStates.join(", "),
          shortBio: _shortBioController.text,
          fullBio: _fullBioController.text,
          difference: _differenceController.text,
          awards: _awardsController.text,
          testimonials: _testimonialsController.text,
          email: _emailController.text,
          mobile: _mobileController.text,
          officeAddress: _officeAddressController.text,
          serviceAreas: _serviceAreasController.text,
          linkedin: _linkedinController.text,
          googleReviews: _googleReviewsController.text,
          website: _websiteController.text,
          profilePhoto: _profilePhoto,
          companyLogo: _companyLogo,
          profilePhotoUrl: _profileImageUrl,
          companyLogoUrl: _companyLogoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buyers Agent Details")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),

              // ---------------- SECTION 1 ----------------
              sectionTitle("1. Personal & Professional Identity"),

              // Profile Photo Preview & Upload
              _buildProfilePhotoUpload(),
              const SizedBox(height: 16),

              buildMandatoryField("Full Name *", _fullNameController, () {
                if (!_isEditing) {
                  setState(() => _showSection2 = _validateSection1());
                }
              }),
              buildTextField("Professional Title", _titleController, 50),
              buildMandatoryField("Company Name *", _companyNameController, () {
                if (!_isEditing) {
                  setState(() => _showSection2 = _validateSection1());
                }
              }),
              buildMandatoryNumber(
                  "Years of Experience *", _experienceController, () {
                if (!_isEditing) {
                  setState(() => _showSection2 = _validateSection1());
                }
              }),

              imageUpload(
                "Company Logo",
                _companyLogo,
                _companyLogoUrl,
                () => _pickImage(false),
              ),

              // ---------------- SECTION 2 ----------------
              if (_showSection2) ...[
                const SizedBox(height: 24),
                sectionTitle("2. Licensing & Focus Areas"),

                buildMandatoryField(
                    "Buyers Agent Licence Number *", _licenceController, () {
                  if (!_isEditing) {
                    setState(() => _showSection3 = _validateSection2());
                  }
                }),
                buildMandatoryField(
                    "AFCA Membership Number *", _afcaController, () {
                  if (!_isEditing) {
                    setState(() => _showSection3 = _validateSection2());
                  }
                }),
                dropdownField(
                  "Primary Specialisation *",
                  [
                    "First Home Buyers",
                    "Investors",
                    "Upsizers/Downsizers",
                    "Commercial Property",
                    "Other"
                  ],
                  _selectedSpecialisation,
                  (value) {
                    setState(() {
                      _selectedSpecialisation = value;
                      if (!_isEditing) {
                        _showSection3 = _validateSection2();
                      }
                    });
                  },
                ),

                multiSelectStates(),
              ],

              // ---------------- SECTION 3 & 4 ----------------
              if (_showSection3) ...[
                const SizedBox(height: 24),
                sectionTitle("3. About / Bio"),

                buildMandatoryField("Short Bio *", _shortBioController, () {}),
                buildLongField("Full Bio / Story", _fullBioController, 2000),
                buildLongField(
                    "What Makes You Different?", _differenceController, 1000),
                buildLongField(
                    "Awards & Recognition", _awardsController, 1000),
                buildLongField(
                    "Customer Testimonials", _testimonialsController, 2000),

                const SizedBox(height: 24),
                sectionTitle("4. Contact, Location & Online Links"),

                buildMandatoryField(
                    "Email Address *", _emailController, () => setState(() {})),
                SwitchListTile(
                  title:
                      const Text("Show email address to prospective clients"),
                  value: _showEmailToCustomers,
                  onChanged: (v) => setState(() => _showEmailToCustomers = v),
                ),

                buildMandatoryNumber(
                    "Mobile Number *", _mobileController, () => setState(() {})),
                SwitchListTile(
                  title:
                      const Text("Show phone number to prospective clients"),
                  value: _showMobileToCustomers,
                  onChanged: (v) => setState(() => _showMobileToCustomers = v),
                ),

                if (!_validateContactVisibility())
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      "At least one contact method should be enabled.",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                buildTextField("Office Address", _officeAddressController, 200),
                buildTextField(
                    "Service Areas (e.g., Sydney CBD, Eastern Suburbs)",
                    _serviceAreasController,
                    200),
                buildTextField(
                    "Availability Hours", _availabilityController, 100),

                buildTextField(
                    "LinkedIn Profile URL", _linkedinController, 150),
                buildTextField(
                    "Google Reviews Link", _googleReviewsController, 150),
                buildTextField(
                    "Company Website URL", _websiteController, 150),

                SwitchListTile(
                  title: const Text("Online Appointments Available"),
                  value: _onlineAppointments,
                  onChanged: (v) => setState(() => _onlineAppointments = v),
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _attemptSave,
                    child: const Text("Save & Preview"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildProfilePhotoUpload() {
    ImageProvider? imageProvider;
    if (_profilePhoto != null) {
      imageProvider = FileImage(_profilePhoto!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Text(
                        _fullNameController.text.isNotEmpty
                            ? _fullNameController.text[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt,
                        size: 18, color: Colors.white),
                    onPressed: () => _pickImage(true),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Profile Photo", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget buildMandatoryField(
      String label, TextEditingController controller, VoidCallback onChanged) {
    final bool isEmpty = controller.text.trim().isEmpty;
    final bool touched = _touched[label] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            setState(() {
              _touched[label] = true;
            });
          }
        },
        child: TextField(
          controller: controller,
          onChanged: (_) {
            _touched[label] = true;
            onChanged();
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: (touched && isEmpty) ? "This field is required" : null,
          ),
        ),
      ),
    );
  }

  Widget buildMandatoryNumber(
      String label, TextEditingController controller, VoidCallback onChanged) {
    final bool isEmpty = controller.text.trim().isEmpty;
    final bool touched = _touched[label] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            setState(() {
              _touched[label] = true;
            });
          }
        },
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) {
            _touched[label] = true;
            onChanged();
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: (touched && isEmpty) ? "This field is required" : null,
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      String label, TextEditingController controller, int max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLength: max,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildLongField(
      String label, TextEditingController controller, int max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLength: max,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget dropdownField(String label, List<String> items, String? selected,
      Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selected,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget multiSelectStates() {
    final states = ["NSW", "VIC", "QLD", "SA", "WA", "TAS", "ACT", "NT"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("States You Operate In *",
            style: TextStyle(fontWeight: FontWeight.bold)),
        ...states.map((state) {
          return CheckboxListTile(
            title: Text(state),
            value: _selectedStates.contains(state),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedStates.add(state);
                } else {
                  _selectedStates.remove(state);
                }
                if (!_isEditing) {
                  _showSection3 = _validateSection2();
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget imageUpload(
      String label, File? file, String? networkUrl, VoidCallback onTap) {
    Widget content;
    if (file != null) {
      content = Image.file(file, fit: BoxFit.cover);
    } else if (networkUrl != null && networkUrl.isNotEmpty) {
      content = Image.network(
        networkUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Text("Could not load image")),
      );
    } else {
      content = const Center(child: Text("Tap to upload image"));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}