import 'package:flutter/material.dart';

/// Language preference stored by the app.
///
/// `system` keeps Flutter's default device language behavior.
enum AppLanguage {
  system,
  english,
  malay;

  static AppLanguage fromName(String? value) {
    return AppLanguage.values.firstWhere(
      (language) => language.name == value,
      orElse: () => AppLanguage.system,
    );
  }

  Locale? get locale {
    return switch (this) {
      AppLanguage.system => null,
      AppLanguage.english => const Locale('en'),
      AppLanguage.malay => const Locale('ms'),
    };
  }

  String get label {
    return switch (this) {
      AppLanguage.system => 'System default',
      AppLanguage.english => 'English',
      AppLanguage.malay => 'Bahasa Melayu',
    };
  }

  String get description {
    return switch (this) {
      AppLanguage.system => 'Follow device language',
      AppLanguage.english => 'Use English where translations are available',
      AppLanguage.malay => 'Use Malay where translations are available',
    };
  }
}
