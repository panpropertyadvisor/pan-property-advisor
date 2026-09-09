// lib/pages/payment_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1pan/services/api_service.dart';

class PaymentPage extends StatefulWidget {
  final String? amountPaid;
  final String? paymentDate;
  final String? expiryDate;
  final String? role;
  final bool isPaid;

  const PaymentPage({
    super.key,
    this.amountPaid,
    this.paymentDate,
    this.expiryDate,
    this.role,
    required this.isPaid,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _processingPayment = false;
  String? _paymentError;

  // Pricing
  static const int investorAmountCents = 4999; // AUD 49.99 one-time
  static const int brokerAmountCents = 2500; // AUD 25.00 monthly
  static const int buyersAgentAmountCents = 2900; // AUD 29.00 monthly

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  /// Parses dates in ISO or DD/MM/YYYY format.
  DateTime? _parseFlexibleDate(String? value) {
    if (value == null || value.trim().isEmpty || value == 'N/A') return null;

    // ISO / standard parse first
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;

    // DD/MM/YYYY
    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  String _formatDisplayDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}";
  }

  /// Resolves the expiry date to display on the "already paid" screen.
  String _resolveExpiryDate() {
    // 1. Prefer the value already calculated/passed by the dashboard
    if (widget.expiryDate != null &&
        widget.expiryDate!.trim().isNotEmpty &&
        widget.expiryDate != 'N/A') {
      return widget.expiryDate!;
    }

    // 2. Fallback: derive from payment date (+1 year for one-time, or use as-is)
    final paidDate = _parseFlexibleDate(widget.paymentDate);
    if (paidDate != null) {
      // Default display fallback: +1 year from payment date
      // (monthly plans should already pass subscriptionExpiry via widget.expiryDate)
      final expiry = DateTime(paidDate.year + 1, paidDate.month, paidDate.day);
      return _formatDisplayDate(expiry);
    }

    return 'N/A';
  }

  Future<Map<String, dynamic>> _getRoleAndAmount() async {
    final prefs = await SharedPreferences.getInstance();
    String role = prefs.getString('role') ?? 'investor';
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && (role.isEmpty || role == 'investor')) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      role = snap.data()?['role'] ?? role;
    }

    int amountCents;
    String displayAmount;
    String paymentType;

    switch (role) {
      case 'mortgage_broker':
        amountCents = brokerAmountCents;
        displayAmount = '\$25.00';
        paymentType = 'monthly';
        break;
      case 'buyers_agent':
        amountCents = buyersAgentAmountCents;
        displayAmount = '\$29.00';
        paymentType = 'monthly';
        break;
      case 'investor':
      default:
        amountCents = investorAmountCents;
        displayAmount = '\$49.99';
        paymentType = 'one-time';
        break;
    }

    return {
      'role': role,
      'amountCents': amountCents,
      'displayAmount': displayAmount,
      'paymentType': paymentType,
    };
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _paymentError = null;
    });

    if (_cardNameController.text.trim().isEmpty ||
        _cardNumberController.text.trim().length < 15 ||
        _expiryController.text.trim().length != 5 ||
        _cvvController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid card details")),
      );
      return;
    }

    setState(() => _processingPayment = true);

    try {
      final expiryParts = _expiryController.text.trim().split('/');
      if (expiryParts.length != 2) {
        throw Exception("Invalid expiry format. Please use MM/YY");
      }

      final month = int.tryParse(expiryParts[0]);
      final year = int.tryParse('20${expiryParts[1]}');

      if (month == null || month < 1 || month > 12 || year == null) {
        throw Exception("Invalid card expiration date.");
      }

      // 1. Update Card Details in Stripe SDK
      await Stripe.instance.dangerouslyUpdateCardDetails(
        CardDetails(
          number: _cardNumberController.text.replaceAll(' ', '').trim(),
          expirationMonth: month,
          expirationYear: year,
          cvc: _cvvController.text.trim(),
        ),
      );

      // 2. Get correct amount based on role
      final paymentInfo = await _getRoleAndAmount();
      final String role = paymentInfo['role'];
      final int amountCents = paymentInfo['amountCents'];
      final String displayAmount = paymentInfo['displayAmount'];
      final String paymentType = paymentInfo['paymentType'];

      // 3. Request Payment Intent Secret from backend
      final String clientSecret =
          await ApiService.createPaymentIntent(amountCents);
      if (clientSecret.isEmpty) {
        throw Exception('Failed to communicate with payment server.');
      }

      final user = FirebaseAuth.instance.currentUser;
      final billingDetails = BillingDetails(
        name: _cardNameController.text.trim(),
        email: user?.email ?? '',
      );

      // 4. Confirm Payment via Stripe
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );

      if (result.status == PaymentIntentsStatus.Succeeded) {
        if (!mounted) return;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('paid', true);

        final String paymentIntentId = result.id;

        // 5. Update user document + create payment record
        if (user != null) {
          final batch = FirebaseFirestore.instance.batch();

          final userDoc =
              FirebaseFirestore.instance.collection('users').doc(user.uid);

          // Calculate subscription expiry date based on payment type
          final DateTime now = DateTime.now();
          final DateTime expiryDate = DateTime(now.year + 1, now.month, now.day);

          final Map<String, dynamic> userUpdate = {
            'paid': true,
            'paymentType': paymentType,
            'lastPaymentAmount': amountCents,
            'lastPaymentAt': FieldValue.serverTimestamp(),
            'subscriptionExpiry': Timestamp.fromDate(expiryDate),
          };

          if (role == 'mortgage_broker' || role == 'buyers_agent') {
            userUpdate['subscriptionAmount'] = amountCents;
          }

          batch.set(userDoc, userUpdate, SetOptions(merge: true));

          final paymentDoc =
              FirebaseFirestore.instance.collection('payments').doc();

          batch.set(paymentDoc, {
            'userId': user.uid,
            'email': user.email ?? '',
            'name': _cardNameController.text.trim(),
            'role': role,
            'amount': amountCents,
            'amountDisplay': displayAmount,
            'currency': 'aud',
            'paymentType': paymentType,
            'status': 'succeeded',
            'stripePaymentIntentId': paymentIntentId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          await batch.commit();
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment of $displayAmount successful!')),
        );

        // 6. Role-based redirection
        if (role == 'buyers_agent') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/buyersAgentDetails',
            (route) => false,
          );
        } else if (role == 'mortgage_broker') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/mortgageBrokerDetails',
            (route) => false,
          );
        } else {
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({'profileCompleted': true}, SetOptions(merge: true));
          }
          await prefs.setBool('investor_profileCompleted', true);
          await prefs.setBool('profileCompleted', true);

          if (!mounted) return;

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/investorDashboard',
            (route) => false,
          );
        }
        return;
      }

      throw Exception('Payment was not completed.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _processingPayment = false;
          _paymentError =
              'Payment failed: ${e.toString().replaceAll("Exception: ", "")}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_paymentError!)),
        );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ========== ALREADY PAID → SHOW SUBSCRIPTION DETAILS ==========
    if (widget.isPaid) {
      final String expiryDate = _resolveExpiryDate();
      final String roleLabel = widget.role ?? 'Member';

      return Scaffold(
        appBar: AppBar(
          title: const Text('Subscription Details'),
          backgroundColor: Colors.black,
          foregroundColor: const Color(0xFFFFD700),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Payment Status",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Paid ✓",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 28),
                _detailRow("Role", roleLabel),
                const SizedBox(height: 16),
                _detailRow("Amount Paid", "\$${widget.amountPaid ?? '0.00'}"),
                const SizedBox(height: 16),
                _detailRow("Payment Date", widget.paymentDate ?? 'N/A'),
                const SizedBox(height: 16),
                _detailRow("Expiry Date", expiryDate),
                const SizedBox(height: 16),
                _detailRow("Status", "Active"),
                const Spacer(),
                const Text(
                  "Thank you for your subscription.\nYour account is active until the expiry date.",
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ========== NOT PAID → SHOW NORMAL PAYMENT FORM ==========
    return FutureBuilder<Map<String, dynamic>>(
      future: _getRoleAndAmount(),
      builder: (context, snapshot) {
        final displayAmount = snapshot.data?['displayAmount'] ?? '\$49.99';
        final role = snapshot.data?['role'] ?? 'investor';

        String subtitle;
        if (role == 'mortgage_broker') {
          subtitle =
              'Monthly subscription of $displayAmount AUD to activate your Mortgage Broker account.';
        } else if (role == 'buyers_agent') {
          subtitle =
              'Monthly subscription of $displayAmount AUD to activate your Buyers Agent account.';
        } else {
          subtitle =
              'One-time payment of $displayAmount AUD to activate your Investor account.';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete Payment'),
            backgroundColor: Colors.black,
            foregroundColor: const Color(0xFFFFD700),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Required',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // CARD HOLDER NAME
                  TextFormField(
                    controller: _cardNameController,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: "Name on Card",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CARD NUMBER
                  // NAME ON CARD
                  TextFormField(
                    controller: _cardNameController,
                    maxLength: 100,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")), // letters + spaces only
                    ],
                    decoration: const InputDecoration(
                      labelText: "Name on Card",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name on card is required';
                      }
                      if (value.length > 100) {
                        return 'Name cannot exceed 100 characters';
                      }
                      // Extra safety check (already filtered by inputFormatter)
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                        return 'Name cannot contain special characters or numbers';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // CARD NUMBER
                  TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: "Card Number",
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                    // Add your card number validator here if needed
                  ),
                  const SizedBox(height: 12),

                  // EXPIRY + CVV
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            CardExpiryInputFormatter(),
                          ],
                          decoration: const InputDecoration(
                            labelText: "Expiry (MM/YY)",
                            hintText: "MM/YY",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Expiry is required';
                            }

                            final cleaned = value.replaceAll('/', '');

                            // Both MM and YY must be exactly 2 digits
                            if (cleaned.length != 4) {
                              return 'Enter a valid MM/YY';
                            }

                            final mm = int.tryParse(cleaned.substring(0, 2));
                            final yy = int.tryParse(cleaned.substring(2, 4));

                            if (mm == null || yy == null) {
                              return 'Enter a valid MM/YY';
                            }

                            // Month must be 1–12
                            if (mm < 1 || mm > 12) {
                              return 'Month must be between 01 and 12';
                            }

                            // Year cannot be in the past
                            final now = DateTime.now();
                            final currentYear = now.year % 100;
                            final currentMonth = now.month;

                            if (yy < currentYear || (yy == currentYear && mm < currentMonth)) {
                              return 'Card has expired';
                            }

                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // no special chars / letters / negatives
                          ],
                          decoration: const InputDecoration(
                            labelText: "CVV",
                            border: OutlineInputBorder(),
                            counterText: "",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'CVV is required';
                            }
                            if (value.length < 3 || value.length > 4) {
                              return 'CVV must be 3 or 4 digits';
                            }
                            // Extra safety (already filtered)
                            if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
                              return 'CVV can only contain numbers';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  if (_paymentError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _paymentError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: const Color(0xFFFFD700),
                      ),
                      onPressed: _processingPayment ? null : _processPayment,
                      child: _processingPayment
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFD700),
                              ),
                            )
                          : Text(
                              'Pay $displayAmount AUD & Continue',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Formatter for MM/YY expiry input
class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text.length > newValue.text.length) {
      return newValue;
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanText.length > 4) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      if (i == 1 && cleanText.length >= 2) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}