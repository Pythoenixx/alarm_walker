class UserProfileDbEntry {
  final String userId;
  final String name;
  final String language;
  final String theme;

  UserProfileDbEntry({
    required this.userId,
    required this.name,
    required this.language,
    required this.theme,
  });

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'name': name,
    'language': language,
    'theme': theme,
  };

  factory UserProfileDbEntry.fromMap(Map<String, dynamic> map) {
    return UserProfileDbEntry(
      userId: map['user_id'],
      name: map['name'] ?? '',
      language: map['language'] ?? 'en',
      theme: map['theme'] ?? 'system',
    );
  }
}
