import 'package:alarm_walker/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  bool get isDarkMode => Theme.brightnessOf(this) == Brightness.dark;
  AppLocalizations get localization {
    return AppLocalizations.of(this)!;
  }
  /// Lightweight runtime translation helper for user-facing text that has not
  /// been migrated into ARB/generated localization yet.
  ///
  /// This keeps the first locale pass low-risk while still allowing the Malay
  /// language setting to stress-test layout width and overflow behavior.
  String tr(String english, [Map<String, Object?> values = const {}]) {
    final languageCode = Localizations.localeOf(this).languageCode;
    var text = languageCode == 'ms' ? (_msTranslations[english] ?? english) : english;
    for (final entry in values.entries) {
      text = text.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return text;
  }
}

const Map<String, String> _msTranslations = {
  // Common actions
  'Save': 'Simpan',
  'Cancel': 'Batal',
  'Delete': 'Padam',
  'Back': 'Kembali',
  'Stay': 'Kekal',
  'Discard': 'Buang',
  'Dismiss': 'Henti',
  'Configure': 'Tetapkan',
  'Default': 'Lalai',
  'Off': 'Tutup',
  'ON: scheduled alarms are paused until disabled.':
      'HIDUP: penggera berjadual dijeda sehingga dimatikan.',
  // Auth
  'Log In': 'Log Masuk',
  'Log in': 'Log masuk',
  'Log in to sync and track your progress':
      'Log masuk untuk segerak dan jejaki kemajuan anda',
  'Email': 'E-mel',
  'Enter your email': 'Masukkan e-mel anda',
  'Password': 'Kata laluan',
  'Enter your password': 'Masukkan kata laluan anda',
  'Forgot password?': 'Lupa kata laluan?',
  'Not yet Sign Up?': 'Belum daftar?',
  'OR': 'ATAU',
  'Continue without an account': 'Terus tanpa akaun',
  'Use the app without signing in.\nYour data stays on this device.':
      'Guna aplikasi tanpa log masuk.\nData anda kekal pada peranti ini.',
  'Continue as guest': 'Terus sebagai tetamu',
  'Create Account': 'Cipta Akaun',
  'Sign up to sync your alarms across devices':
      'Daftar untuk segerakkan penggera merentas peranti',
  'Full Name': 'Nama Penuh',
  'Enter your name': 'Masukkan nama anda',
  'Confirm Password': 'Sahkan Kata Laluan',
  'Re-enter your password': 'Masukkan semula kata laluan',
  'Already have an account?': 'Sudah ada akaun?',
  'Profile Category': 'Kategori Profil',
  'Choose a category to apply suitable default alarm difficulty.':
      'Pilih kategori untuk gunakan tahap kesukaran penggera yang sesuai.',
  'Easy tasks': 'Tugasan mudah',
  'Balanced tasks': 'Tugasan seimbang',
  'Light tasks': 'Tugasan ringan',
  'Account Created!': 'Akaun Berjaya Dicipta!',
  'Your account has been successfully created. Welcome aboard!':
      'Akaun anda berjaya dicipta. Selamat datang!',
  'Get Started': 'Mula',
  'Please enter your email': 'Sila masukkan e-mel anda',
  'Please enter a valid email': 'Sila masukkan e-mel yang sah',
  'Please enter your password': 'Sila masukkan kata laluan anda',
  'Please enter a password': 'Sila masukkan kata laluan',
  'Password must be at least 6 characters': 'Kata laluan mestilah sekurang-kurangnya 6 aksara',
  'Please confirm your password': 'Sila sahkan kata laluan anda',
  'Passwords do not match': 'Kata laluan tidak sepadan',
  'Please enter your name': 'Sila masukkan nama anda',
  'Name must be at least 2 characters': 'Nama mestilah sekurang-kurangnya 2 aksara',
  // Settings
  'Appearance': 'Paparan',
  'Language': 'Bahasa',
  'System default': 'Lalai sistem',
  'Follow device language': 'Ikut bahasa peranti',
  'English': 'Bahasa Inggeris',
  'Use English where translations are available':
      'Guna Bahasa Inggeris jika terjemahan tersedia',
  'Bahasa Melayu': 'Bahasa Melayu',
  'Use Malay where translations are available':
      'Guna Bahasa Melayu jika terjemahan tersedia',
  'Weather-aware wake-up': 'Bangun ikut cuaca',
  'Show weather messages': 'Tunjuk mesej cuaca',
  'Adaptive difficulty': 'Kesukaran adaptif',
  'Adjust future alarm defaults': 'Laraskan lalai penggera akan datang',
  'Reminder options': 'Pilihan peringatan',
  'Bedtime alert': 'Amaran waktu tidur',
  'Remind me to prepare for sleep and check alarms.':
      'Ingatkan saya bersedia tidur dan semak penggera.',
  'Bedtime reminder time': 'Masa peringatan tidur',
  'Weekend reminder': 'Peringatan hujung minggu',
  'Warn me on weekends if no weekday alarm is set.':
      'Ingatkan pada hujung minggu jika tiada penggera hari bekerja.',
  'Vacation mode': 'Mod cuti',
  'Pause scheduled alarms without deleting them.':
      'Jeda penggera berjadual tanpa memadamkannya.',
  'Sticky alarm notification': 'Notifikasi penggera kekal',
  'Show a persistent notification for the next alarm.':
      'Tunjuk notifikasi kekal untuk penggera seterusnya.',
  'New alarm defaults': 'Lalai penggera baharu',
  'Sound': 'Bunyi',
  'Snooze': 'Tunda',
  'Help & Feedback': 'Bantuan & Maklum Balas',
  'Report a problem': 'Lapor masalah',
  'Send feedback or request help from admin':
      'Hantar maklum balas atau minta bantuan admin',
  'System': 'Sistem',
  'Permissions': 'Kebenaran',
  'Backup & Restore': 'Sandaran & Pulih',
  'Export or restore alarms, settings, and logs':
      'Eksport atau pulihkan penggera, tetapan dan log',
  'About': 'Tentang',
  'About Alarm Walker': 'Tentang Alarm Walker',
  'Replay onboarding': 'Ulang pengenalan',
  'View the introduction and category guide again':
      'Lihat semula pengenalan dan panduan kategori',
  'Replay': 'Ulang',
  'This will show the introduction screens again. Your alarms, settings, and wake-up logs will not be deleted.':
      'Ini akan memaparkan skrin pengenalan semula. Penggera, tetapan dan log bangun tidak akan dipadam.',
  // Home
  'Vacation mode is on': 'Mod cuti sedang aktif',
  'Your scheduled alarms are paused until you turn this off.':
      'Penggera berjadual dijeda sehingga anda mematikannya.',
  'Turn off': 'Matikan',
  // Add/edit alarm
  'Discard changes?': 'Buang perubahan?',
  'You have unsaved alarm changes. Save the alarm to keep them, or discard to leave this page.':
      'Anda ada perubahan penggera yang belum disimpan. Simpan untuk kekalkan, atau buang untuk keluar.',
  'Please select at least one repeat day.':
      'Sila pilih sekurang-kurangnya satu hari ulangan.',
  'Repeat': 'Ulang',
  'One-time': 'Sekali sahaja',
  'This alarm will ring once at the next matching time and then disable itself after successful dismiss.':
      'Penggera ini akan berbunyi sekali pada masa seterusnya dan dimatikan selepas berjaya dihentikan.',
  'Settings': 'Tetapan',
  'Normal': 'Biasa',
  'Walk': 'Berjalan',
  'Math': 'Matematik',
  'Shake': 'Goncang',
  'Retype': 'Taip semula',
  'Easy': 'Mudah',
  'Medium': 'Sederhana',
  'Hard': 'Sukar',
  'Retype phrase': 'Taip semula frasa',
  'steps': 'langkah',
  // Dismiss settings
  'Tap to dismiss': 'Ketik untuk henti',
  'Take steps to dismiss': 'Berjalan untuk henti',
  'Solve equations to dismiss': 'Selesaikan soalan untuk henti',
  'Shake phone to dismiss': 'Goncang telefon untuk henti',
  'Type a phrase to dismiss': 'Taip frasa untuk henti',
  // Help feedback
  'Need help with Alarm Walker?': 'Perlukan bantuan dengan Alarm Walker?',
  'Report alarm problems, account issues, backup trouble, or send improvement ideas to the admin.':
      'Lapor masalah penggera, isu akaun, masalah sandaran, atau cadangan penambahbaikan kepada admin.',
  'Submitted feedback is saved as a support ticket for admin review. Please avoid sharing passwords or private security details.':
      'Maklum balas disimpan sebagai tiket sokongan untuk semakan admin. Elakkan berkongsi kata laluan atau maklumat sulit.',
  'Submit feedback': 'Hantar maklum balas',
  'Submit Feedback': 'Hantar Maklum Balas',
  'Submitting...': 'Menghantar...',
  'Feedback type': 'Jenis maklum balas',
  'Describe the problem or idea': 'Terangkan masalah atau idea',
  'Example: My alarm did not ring after I restored my backup.':
      'Contoh: Penggera saya tidak berbunyi selepas saya pulihkan sandaran.',
  'Please enter your feedback.': 'Sila masukkan maklum balas anda.',
  'Please describe it a bit more.': 'Sila terangkan dengan lebih jelas.',
  'Optional experience rating': 'Penilaian pengalaman pilihan',
  'Feedback submitted. The admin can now review it.':
      'Maklum balas dihantar. Admin kini boleh menyemaknya.',
  'Unable to submit feedback right now. Please try again.':
      'Tidak dapat menghantar maklum balas sekarang. Sila cuba lagi.',
  'Alarm Problem': 'Masalah Penggera',
  'Account Problem': 'Masalah Akaun',
  'Backup / Restore': 'Sandaran / Pulih',
  'Suggestion': 'Cadangan',
  'General Feedback': 'Maklum Balas Umum',
  // Alarm gate / challenges
  'Wake now': 'Bangun sekarang',
  'Wake now to dismiss': 'Bangun sekarang untuk henti',
  'Dismiss — Walk': 'Henti — Berjalan',
  'Dismiss — Math': 'Henti — Matematik',
  'Dismiss — Shake': 'Henti — Goncang',
  'Dismiss — Retype': 'Henti — Taip Semula',
  'Snoozed {count}×': 'Ditunda {count}×',
  'Snoozed {count} / {max}×': 'Ditunda {count} / {max}×',
  'Ringing again at {time}': 'Berbunyi semula pada {time}',
  'Tap to snooze · drag to adjust': 'Ketik untuk tunda · seret untuk laras',
  'min': 'min',
};
