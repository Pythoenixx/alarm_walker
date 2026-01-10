class UserProfile {
  final String userId;
  final String name;
  final String language;
  final String theme;

  const UserProfile({
    required this.userId,
    required this.name,
    required this.language,
    required this.theme,
  });

  UserProfile copyWith({String? name, String? language, String? theme}) {
    return UserProfile(
      userId: userId,
      name: name ?? this.name,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}
