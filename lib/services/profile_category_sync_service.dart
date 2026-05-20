import 'package:alarm_walker/models/profile_category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileCategorySyncService {
  const ProfileCategorySyncService._();

  static final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  static bool _isValidCategoryName(String? value) {
    if (value == null) return false;

    return ProfileCategory.values.any((category) => category.name == value);
  }

  /// Returns the cloud category when it exists.
  ///
  /// If an older Firestore user document does not have profileCategory yet,
  /// the current local category is written back to Firestore using merge so
  /// other existing user fields are not overwritten.
  static Future<ProfileCategory> syncOrBackfill({
    required String userId,
    required ProfileCategory localCategory,
    Map<String, dynamic>? cloudData,
  }) async {
    try {
      final doc = _users.doc(userId);
      final data = cloudData ?? (await doc.get()).data();
      final rawCategory = data?['profileCategory'] as String?;

      if (_isValidCategoryName(rawCategory)) {
        return ProfileCategory.fromName(rawCategory);
      }

      await doc.set(
        {'profileCategory': localCategory.name},
        SetOptions(merge: true),
      );

      return localCategory;
    } catch (_) {
      return localCategory;
    }
  }


  /// Stores the Firebase Authentication email in the Firestore user document
  /// when it is missing. This keeps the admin user-management screen useful
  /// because client apps cannot directly list Firebase Auth users.
  static Future<bool> syncAccountEmail({
    required String userId,
    required String? email,
    Map<String, dynamic>? cloudData,
  }) async {
    final trimmedEmail = email?.trim();
    if (trimmedEmail == null || trimmedEmail.isEmpty) return false;

    try {
      final doc = _users.doc(userId);
      final data = cloudData ?? (await doc.get()).data();
      final currentEmail = data?['email']?.toString().trim() ?? '';

      if (currentEmail.isNotEmpty) return true;

      await doc.set({'email': trimmedEmail}, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Saves the selected profile category to Firestore without touching other
  /// user fields. Returns false when cloud sync fails, but local profile data
  /// can still continue working offline.
  static Future<bool> saveCategory({
    required String userId,
    required ProfileCategory category,
  }) async {
    try {
      await _users.doc(userId).set(
        {'profileCategory': category.name},
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
