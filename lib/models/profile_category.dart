enum ProfileCategory {
  child,
  adult,
  senior;

  static const fallback = ProfileCategory.adult;

  static ProfileCategory fromName(String? value) {
    return ProfileCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => fallback,
    );
  }

  String get label {
    return switch (this) {
      ProfileCategory.child => 'Child',
      ProfileCategory.adult => 'Adult',
      ProfileCategory.senior => 'Senior',
    };
  }
}
