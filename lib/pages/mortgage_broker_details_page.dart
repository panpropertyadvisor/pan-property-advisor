// lib/pages/mortgage_broker_details_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'mortgage_broker_preview_page.dart';

class MortgageBrokerDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const MortgageBrokerDetailsPage({
    super.key,
    this.initialData,
  });

  @override
  State<MortgageBrokerDetailsPage> createState() =>
      _MortgageBrokerDetailsPageState();
}

class _MortgageBrokerDetailsPageState extends State<MortgageBrokerDetailsPage> {
  // SECTION VISIBILITY
  bool _showSection2 = false;
  bool _showSection3 = false;

  // ERROR MESSAGE
  String _errorMessage = "";

  // IMAGE FILES (new local picks)
  File? _profilePhoto;
  File? _companyLogo;

  // EXISTING NETWORK IMAGE URLS (from Firestore)
  String? _profileImageUrl;
  String? _companyLogoUrl;

  // TRACK TOUCHED FIELDS
  final Map<String, bool> _touched = {};

  // CONTROLLERS
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _experienceController = TextEditingController();

  final _creditLicenceController = TextEditingController();
  final _afcaController = TextEditingController();

  final _shortBioController = TextEditingController();
  final _fullBioController = TextEditingController();
  final _differenceController = TextEditingController();
  final _awardsController = TextEditingController();
  final _testimonialsController = TextEditingController();

  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _availabilityController = TextEditingController();

  final _linkedinController = TextEditingController();
  final _googleReviewsController = TextEditingController();
  final _websiteController = TextEditingController();

  // VISIBILITY TOGGLES
  bool _showEmailToCustomers = true;
  bool _showMobileToCustomers = true;

  // DROPDOWNS & TOGGLES
  String? _selectedAggregator;
  bool _onlineAppointments = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    if (data != null && data.isNotEmpty) {
      _isEditing = true;

      _fullNameController.text =
          data['fullName']?.toString() ?? data['name']?.toString() ?? '';
      _companyNameController.text =
          data['companyName']?.toString() ?? data['company']?.toString() ?? '';
      _experienceController.text = data['experience']?.toString() ??
          data['yearsOfExperience']?.toString() ??
          '';
      _creditLicenceController.text = data['creditLicence']?.toString() ??
          data['creditLicenceNumber']?.toString() ??
          '';
      _afcaController.text =
          data['afcaNumber']?.toString() ?? data['afca']?.toString() ?? '';
      _selectedAggregator = data['aggregator']?.toString();
      _shortBioController.text = data['shortBio']?.toString() ?? '';
      _fullBioController.text = data['fullBio']?.toString() ?? '';
      _differenceController.text = data['difference']?.toString() ?? '';
      _awardsController.text = data['awards']?.toString() ?? '';
      _testimonialsController.text = data['testimonials']?.toString() ?? '';
      _emailController.text = data['email']?.toString() ?? '';
      _mobileController.text =
          data['mobile']?.toString() ?? data['phone']?.toString() ?? '';
      _availabilityController.text = data['availability']?.toString() ??
          data['availabilityHours']?.toString() ??
          '';
      _linkedinController.text = data['linkedin']?.toString() ?? '';
      _googleReviewsController.text = data['googleReviews']?.toString() ?? '';
      _websiteController.text = data['website']?.toString() ?? '';

      // Load existing network image URLs so photos/logos are retained
      _profileImageUrl = data['profilePhotoUrl']?.toString() ??
          data['photoUrl']?.toString() ??
          data['imageUrl']?.toString();
      _companyLogoUrl = data['companyLogoUrl']?.toString() ??
          data['logoUrl']?.toString();

      // Visibility / toggles
      _showEmailToCustomers = data['showEmailToCustomers'] ?? true;
      _showMobileToCustomers = data['showMobileToCustomers'] ?? true;
      _onlineAppointments = data['onlineAppointments'] == true;

      // Always open full form when editing
      _showSection2 = true;
      _showSection3 = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _experienceController.dispose();
    _creditLicenceController.dispose();
    _afcaController.dispose();
    _shortBioController.dispose();
    _fullBioController.dispose();
    _differenceController.dispose();
    _awardsController.dispose();
    _testimonialsController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _availabilityController.dispose();
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

  bool _validateName(String text) {
    if (text.trim().length < 3) return false;
    if (RegExp(r'[^a-zA-Z0-9 ]').hasMatch(text)) return false;
    return true;
  }

  bool _validateExperience(String text) {
    if (text.isEmpty) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(text)) return false;
    return true;
  }

  bool _validateEmail(String text) {
    return text.contains("@") && text.contains(".com");
  }

  bool _validateMobile(String text) {
    if (!RegExp(r'^[0-9]+$').hasMatch(text)) return false;
    if (text.length < 10) return false;
    return true;
  }

  bool _validateSection1() {
    return _validateName(_fullNameController.text) &&
        _validateName(_companyNameController.text) &&
        _validateExperience(_experienceController.text);
  }

  bool _validateSection2() {
    return _creditLicenceController.text.trim().isNotEmpty &&
        _afcaController.text.trim().isNotEmpty &&
        _selectedAggregator != null;
  }

  bool _validateContactVisibility() {
    return _showEmailToCustomers || _showMobileToCustomers;
  }

  bool _validateAll() {
    return _validateSection1() &&
        _validateSection2() &&
        _shortBioController.text.trim().isNotEmpty &&
        _validateEmail(_emailController.text) &&
        _validateMobile(_mobileController.text) &&
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
      _touched["Full Name *"] = true;
      _touched["Company Name *"] = true;
      _touched["Years of Experience *"] = true;
      _touched["Credit Licence Number (ACL/CRN) *"] = true;
      _touched["AFCA Membership Number *"] = true;
      _touched["Short Bio *"] = true;
      _touched["Email Address *"] = true;
      _touched["Mobile Number *"] = true;
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
        builder: (_) => MortgageBrokerPreviewPage(
          fullName: _fullNameController.text,
          title: "",
          companyName: _companyNameController.text,
          experience: _experienceController.text,
          creditLicence: _creditLicenceController.text,
          afcaNumber: _afcaController.text,
          aggregator: _selectedAggregator ?? "",
          profilePhoto: _profilePhoto,
          companyLogo: _companyLogo,
          profilePhotoUrl: _profileImageUrl,
          companyLogoUrl: _companyLogoUrl,
          // Pass existing network URLs so preview can still show them
          // if the user did not re-pick images (requires matching update
          // on MortgageBrokerPreviewPage — see note below)
          shortBio: _shortBioController.text,
          fullBio: _fullBioController.text,
          difference: _differenceController.text,
          awards: _awardsController.text,
          testimonials: _testimonialsController.text,
          email: _emailController.text,
          mobile: _mobileController.text,
          officeAddress: "",
          serviceAreas: "",
          linkedin: _linkedinController.text,
          googleReviews: _googleReviewsController.text,
          website: _websiteController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mortgage Broker Details")),
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

              sectionTitle("1. Personal & Professional Identity"),

              mandatoryNameField("Full Name *", _fullNameController, () {
                if (!_isEditing) {
                  setState(() {
                    _showSection2 = _validateSection1();
                  });
                }
              }),

              mandatoryNameField("Company Name *", _companyNameController, () {
                if (!_isEditing) {
                  setState(() {
                    _showSection2 = _validateSection1();
                  });
                }
              }),

              mandatoryExperienceField(
                  "Years of Experience *", _experienceController, () {
                if (!_isEditing) {
                  setState(() {
                    _showSection2 = _validateSection1();
                  });
                }
              }),

              // Profile photo: local file takes priority, then network URL
              imageUpload(
                "Profile Photo",
                _profilePhoto,
                _profileImageUrl,
                () => _pickImage(true),
              ),

              // Company logo: local file takes priority, then network URL
              imageUpload(
                "Company Logo",
                _companyLogo,
                _companyLogoUrl,
                () => _pickImage(false),
              ),

              if (_showSection2) ...[
                const SizedBox(height: 24),
                sectionTitle("2. Licensing & Compliance"),

                mandatoryField(
                    "Credit Licence Number (ACL/CRN) *",
                    _creditLicenceController, () {
                  if (!_isEditing) {
                    setState(() {
                      _showSection3 = _validateSection2();
                    });
                  }
                }),

                mandatoryField(
                    "AFCA Membership Number *", _afcaController, () {
                  if (!_isEditing) {
                    setState(() {
                      _showSection3 = _validateSection2();
                    });
                  }
                }),

                dropdownField(
                  "Aggregator Name *",
                  ["PLAN", "AFG", "Connective", "Loan Market", "Other"],
                  _selectedAggregator,
                  (value) {
                    setState(() {
                      _selectedAggregator = value;
                      if (!_isEditing) {
                        _showSection3 = _validateSection2();
                      }
                    });
                  },
                ),
              ],

              if (_showSection3) ...[
                const SizedBox(height: 24),
                sectionTitle("3. About / Bio"),

                mandatoryField("Short Bio *", _shortBioController, () {}),

                longField("Full Bio / Story", _fullBioController),
                longField("What Makes You Different?", _differenceController),
                longField("Awards & Recognition", _awardsController),
                longField("Customer Testimonials", _testimonialsController),

                const SizedBox(height: 24),
                sectionTitle("4. Contact & Availability"),

                mandatoryEmailField("Email Address *", _emailController, () {
                  setState(() {});
                }),

                SwitchListTile(
                  title: const Text("Do you want customers to see your email?"),
                  value: _showEmailToCustomers,
                  onChanged: (v) {
                    setState(() => _showEmailToCustomers = v);
                  },
                ),

                mandatoryMobileField("Mobile Number *", _mobileController, () {
                  setState(() {});
                }),

                SwitchListTile(
                  title: const Text(
                      "Do you want customers to see your contact number?"),
                  value: _showMobileToCustomers,
                  onChanged: (v) {
                    setState(() => _showMobileToCustomers = v);
                  },
                ),

                if (!_validateContactVisibility())
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      "At least one contact method should be made available",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                normalField("Availability Hours", _availabilityController),

                SwitchListTile(
                  title: const Text("Online Appointments Available"),
                  value: _onlineAppointments,
                  onChanged: (v) {
                    setState(() => _onlineAppointments = v);
                  },
                ),

                const SizedBox(height: 12),
                normalField("LinkedIn Profile URL", _linkedinController),
                normalField("Google Reviews Link", _googleReviewsController),
                normalField("Company Website URL", _websiteController),

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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget mandatoryNameField(
      String label, TextEditingController controller, VoidCallback onChanged) {
    final String text = controller.text.trim();
    final bool touched = _touched[label] ?? false;

    String? errorMessage;
    if (touched) {
      if (text.isEmpty) {
        errorMessage = "This field is required";
      } else if (text.length < 3) {
        errorMessage = "Must be at least 3 characters";
      } else if (RegExp(r'[^a-zA-Z0-9 ]').hasMatch(text)) {
        errorMessage = "Special characters are not allowed";
      }
    }

    final bool showRed = touched && errorMessage != null;

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
          onChanged: (value) {
            _touched[label] = true;
            onChanged();
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: label,
            errorText: errorMessage,
            labelStyle: TextStyle(
              color: showRed ? Colors.red : Colors.black,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mandatoryExperienceField(
      String label, TextEditingController controller, VoidCallback onChanged) {
    final String text = controller.text.trim();
    final bool touched = _touched[label] ?? false;

    String? errorMessage;
    if (touched) {
      if (text.isEmpty) {
        errorMessage = "This field is required";
      } else if (!RegExp(r'^[0-9]+$').hasMatch(text)) {
        errorMessage = "Only numbers allowed";
      } else if (int.tryParse(text)! >= 100) {
        errorMessage = "Value must be less than 100";
      }
    }

    final bool showRed = touched && errorMessage != null;

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
          onChanged: (value) {
            _touched[label] = true;
            onChanged();
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: label,
            errorText: errorMessage,
            labelStyle: TextStyle(
              color: showRed ? Colors.red : Colors.black,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mandatoryEmailField(
      String label, TextEditingController controller, VoidCallback onChanged) {
    final String text = controller.text.trim();
    final bool touched = _touched[label] ?? false;

    String? errorMessage;
    if (touched) {
      if (text.isEmpty) {
        errorMessage = "This field is required";
      } else if (!text.contains("@") || !text.contains(".com")) {
        errorMessage = "Enter a valid email address";
      }
    }

    final bool showRed = touched && errorMessage != null;

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
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            _touched[label] = true;
            onChanged();
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: label,
            errorText: errorMessage,
            labelStyle: TextStyle(
              color: showRed ? Colors.red : Colors.black,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mandatoryMobileField(
      String label, TextEditingController controller, VoidCallback onChanged) {
    final String text = controller.text.trim();
    final bool touched = _touched[label] ?? false;

    String? errorMessage;
    if (touched) {
      if (text.isEmpty) {
        errorMessage = "This field is required";
      } else if (!RegExp(r'^[0-9]+$').hasMatch(text)) {
        errorMessage = "Only numbers allowed";
      } else if (text.length < 10) {
        errorMessage = "Must be at least 10 digits";
      }
    }

    final bool showRed = touched && errorMessage != null;

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
          onChanged: (value) {
            _touched[label] = true;
            onChanged();
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: label,
            errorText: errorMessage,
            labelStyle: TextStyle(
              color: showRed ? Colors.red : Colors.black,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mandatoryField(
      String label, TextEditingController controller, VoidCallback onChanged) {
    final bool isEmpty = controller.text.trim().isEmpty;
    final bool touched = _touched[label] ?? false;
    final bool showRed = touched && isEmpty;

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
          onChanged: (value) {
            _touched[label] = true;
            onChanged();
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: label,
            errorText: touched && isEmpty ? "This field is required" : null,
            labelStyle: TextStyle(
              color: showRed ? Colors.red : Colors.black,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: showRed ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget normalField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget longField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget dropdownField(
    String label,
    List<String> items,
    String? selected,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selected,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  /// Shows local File if present, otherwise falls back to network URL.
  Widget imageUpload(
    String label,
    File? file,
    String? networkUrl,
    VoidCallback onTap,
  ) {
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
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}