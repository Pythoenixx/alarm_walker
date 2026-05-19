import 'package:alarm_walker/models/profile_category.dart';

class UserProfileDbEntry {
  final String userId;
  final String name;
  final String language;
  final String theme;
  final ProfileCategory profileCategory;

  UserProfileDbEntry({
    required this.userId,
    required this.name,
    required this.language,
    required this.theme,
    required this.profileCategory,
  });

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'name': name,
    'language': language,
    'theme': theme,
    'profile_category': profileCategory.name,
  };

  factory UserProfileDbEntry.fromMap(Map<String, dynamic> map) {
    return UserProfileDbEntry(
      userId: map['user_id'],
      name: map['name'] ?? '',
      language: map['language'] ?? 'en',
      theme: map['theme'] ?? 'system',
      profileCategory: ProfileCategory.fromName(
        map['profile_category'] as String?,
      ),
    );
  }
}
