class AppUser {
  final String id;          // Firestore doc ID
  final String name;
  final String email;
  final String mobile;
  final String role;        // "investor" | "broker" | "buyer"

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      mobile: data['mobile'] ?? '',
      role: data['role'] ?? 'investor',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'role': role,
    };
  }
}
