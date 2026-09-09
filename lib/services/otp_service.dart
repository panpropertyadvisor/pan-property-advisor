import 'dart:convert';
import 'package:http/http.dart' as http;

class OtpService {
  // IMPORTANT:
  // Use the correct base URL depending on where you're running the app.
  // Android Emulator → http://10.0.2.2:3000
  // iOS Simulator → http://localhost:3000
  // Real Device → Use deployed backend URL
  static const String baseUrl = "http://10.0.2.2:3000";

  static Future<bool> sendOtp(String email) async {
    final url = Uri.parse("$baseUrl/send-otp");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> verifyOtp(String email, String otp) async {
    final url = Uri.parse("$baseUrl/verify-otp");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    return response.statusCode == 200;
  }
}
