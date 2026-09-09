import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://pan-backend-api.onrender.com";

  // -----------------------------
  // RETRY HELPER
  // -----------------------------
  static Future<http.Response> retryRequest(
    Future<http.Response> Function() request,
  ) async {
    int retries = 3;

    for (int i = 0; i < retries; i++) {
      try {
        return await request();
      } catch (e) {
        print("Retry ${i + 1} after error: $e");
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    // Only reached if all retries fail
    throw Exception("Request failed after $retries retries");

  }


  // -----------------------------
  // SEND OTP
  // -----------------------------
  static Future<bool> sendOtp(String email) async {
    print("SEND OTP API CALLED with email: $email");

    final url = Uri.parse("$baseUrl/send-otp");

    final response = await retryRequest(() {
      return http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
    });

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return response.statusCode == 200;
  }

  // -----------------------------
  // VERIFY OTP
  // -----------------------------
  static Future<bool> verifyOtp(String email, String otp) async {
    print("VERIFY OTP API CALLED");

    final url = Uri.parse("$baseUrl/verify-otp");

    final response = await retryRequest(() {
      return http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );
    });

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return response.statusCode == 200;
  }

  // -----------------------------
  // CREATE PAYMENT INTENT
  // -----------------------------
  static Future<String> createPaymentIntent(int amount) async {
    print("CREATE PAYMENT INTENT CALLED");

    final url = Uri.parse("$baseUrl/create-payment-intent");

    final response = await retryRequest(() {
      return http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"amount": amount}),
      );
    });

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["clientSecret"];
    } else {
      throw Exception("Failed to create PaymentIntent");
    }
  }
}
