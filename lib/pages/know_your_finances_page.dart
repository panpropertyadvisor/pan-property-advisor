import 'package:flutter/material.dart';
import '../utils/stamp_duty_calculator.dart';

class KnowYourFinancePage extends StatefulWidget {
  const KnowYourFinancePage({super.key});

  @override
  State<KnowYourFinancePage> createState() => _KnowYourFinancePageState();
}

class _KnowYourFinancePageState extends State<KnowYourFinancePage> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String? propertyType;
  String? stateValue;
  String? lvrValue;

  final TextEditingController propertyValueController = TextEditingController();
  final TextEditingController interestRateController = TextEditingController();
  final TextEditingController lvrOtherController = TextEditingController();

  // Calculation results
  double? stampDuty;
  double? initialContribution;
  double? monthlyMortgage;
  double? totalInitialContribution;

  // Button state
  bool _calculated = false;

  @override
  void dispose() {
    propertyValueController.dispose();
    interestRateController.dispose();
    lvrOtherController.dispose();
    super.dispose();
  }

  // Helper to format currency numbers with commas
  String _formatCurrency(double? val) {
    if (val == null) return "0";
    return val.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // Get LVR numeric value
  double _getLvrValue() {
    if (lvrValue == null) return 0;
    if (lvrValue == "Other") {
      return double.tryParse(lvrOtherController.text.trim()) ?? 0;
    }
    return double.parse(lvrValue!.replaceAll("%", ""));
  }

  // Perform real calculation
  void _performCalculation() {
    if (!_formKey.currentState!.validate()) return;

    final propertyValue =
        double.tryParse(propertyValueController.text.trim()) ?? 0;
    final lvrPercent = _getLvrValue();
    final interestRate =
        double.tryParse(interestRateController.text.trim()) ?? 0;

    final sd = calculateStampDuty(
      state: stateValue!,
      propertyValue: propertyValue,
    );

    final ic = propertyValue - (propertyValue * lvrPercent / 100);

    final mm = calculateMonthlyMortgage(
      propertyValue: propertyValue,
      lvrPercent: lvrPercent,
      annualInterestPercent: interestRate,
    );

    final total = sd + ic + 2000;

    setState(() {
      stampDuty = sd;
      initialContribution = ic;
      monthlyMortgage = mm;
      totalInitialContribution = total;

      _calculated = true;
    });
  }

  // Helper method for styled result rows inside the summary card
  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String amount,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFFD700),
          size: isHighlight ? 22 : 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isHighlight ? Colors.white : Colors.grey[400],
              fontSize: isHighlight ? 15 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: const Color(0xFFFFD700),
            fontSize: isHighlight ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Know Your Finances"),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFD700),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PROPERTY TYPE
                const Text("Property Type *",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: propertyType,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ["House", "Apartment", "Townhouse", "Land", "Retirement"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  validator: (v) => v == null ? "Required" : null,
                  onChanged: (value) {
                    setState(() {
                      propertyType = value;
                      _calculated = false;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // STATE
                const Text("State *",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: stateValue,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ["NSW", "VIC", "QLD", "SA", "WA", "TAS", "ACT", "NT"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  validator: (v) => v == null ? "Required" : null,
                  onChanged: (value) {
                    setState(() {
                      stateValue = value;
                      _calculated = false;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // PROPERTY VALUE
                const Text("Estimated Property Value *",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: propertyValueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter amount (max 10,000,000)",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required";
                    }
                    final v = double.tryParse(value.trim());
                    if (v == null) return "Numeric only";
                    if (v <= 0) return "Must be > 0";
                    if (v > 10000000) return "Max allowed is 10,000,000";
                    return null;
                  },
                  onChanged: (_) {
                    if (_calculated) setState(() => _calculated = false);
                  },
                ),
                const SizedBox(height: 16),

                // LVR
                const Text("LVR % *",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: lvrValue,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ["70%", "80%", "90%", "95%", "Other"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  validator: (v) => v == null ? "Required" : null,
                  onChanged: (value) {
                    setState(() {
                      lvrValue = value;
                      _calculated = false;
                    });
                  },
                ),

                if (lvrValue == "Other") ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: lvrOtherController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter LVR% (0–100)",
                    ),
                    validator: (value) {
                      if (lvrValue != "Other") return null;
                      if (value == null || value.trim().isEmpty) {
                        return "Required";
                      }
                      final v = double.tryParse(value.trim());
                      if (v == null) return "Numeric only";
                      if (v < 0 || v > 100) return "Must be 0–100";
                      return null;
                    },
                    onChanged: (_) {
                      if (_calculated) setState(() => _calculated = false);
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // INTEREST RATE
                const Text("Home Loan Interest Rate % *",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: interestRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter % rate",
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required";
                    }
                    final v = double.tryParse(value.trim());
                    if (v == null) return "Numeric only";
                    if (v < 0 || v > 100) return "Must be 0–100";
                    return null;
                  },
                  onChanged: (_) {
                    if (_calculated) setState(() => _calculated = false);
                  },
                ),

                const SizedBox(height: 30),

                // CALCULATE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _performCalculation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFFFFD700),
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: const Text(
                      "Calculate",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ENHANCED RESULTS SECTION (VISUALLY BALANCED BLACK & GOLD CARD)
                if (_calculated) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildResultRow(
                          icon: Icons.receipt_long,
                          label: "Estimated Stamp Duty",
                          amount: "\$${_formatCurrency(stampDuty)}",
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildResultRow(
                          icon: Icons.account_balance_wallet,
                          label: "Initial Contribution",
                          amount: "\$${_formatCurrency(initialContribution)}",
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildResultRow(
                          icon: Icons.calendar_month,
                          label: "Estimated Monthly Mortgage",
                          amount: "\$${_formatCurrency(monthlyMortgage)}",
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildResultRow(
                          icon: Icons.payments,
                          label: "Total Initial Contribution",
                          amount: "\$${_formatCurrency(totalInitialContribution)}",
                          isHighlight: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // BUY YOUR DREAM HOME BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/investorTerms');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: const Color(0xFFFFD700),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFFFFD700),
                            width: 2.0,
                          ),
                        ),
                      ),
                      child: const Text(
                        "Buy Your Dream Home",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}