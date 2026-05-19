import 'package:alarm_walker/models/profile_category.dart';

class UserProfile {
  final String userId;
  final String name;
  final String language;
  final String theme;
  final ProfileCategory profileCategory;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.language,
    required this.theme,
    this.profileCategory = ProfileCategory.fallback,
  });

  UserProfile copyWith({
    String? name,
    String? language,
    String? theme,
    ProfileCategory? profileCategory,
  }) {
    return UserProfile(
      userId: userId,
      name: name ?? this.name,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      profileCategory: profileCategory ?? this.profileCategory,
    );
  }
}
