import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerService {
  static Future<void> saveCustomer({
    required String name,
    required String email,
    required String mobile,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('customers').doc();

    await docRef.set({
      'customerId': docRef.id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'status': 'active',
      'notes': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
