import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static const _userIdKey = 'userId';

  static Future<void> saveUser(AppUser user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, user.id);
    await prefs.setBool('isLoggedIn', true);
  }

  static Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    if (userId == null) return null;

    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    return AppUser.fromMap(doc.id, doc.data()!);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove('isLoggedIn');
  }
}
