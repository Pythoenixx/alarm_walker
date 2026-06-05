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
  'Version': 'Versi',
  'Build': 'Binaan',
  'App version': 'Versi aplikasi',
  'App version copied': 'Versi aplikasi disalin',
  'Loading version': 'Memuatkan versi',
  'Tap to copy': 'Ketik untuk salin',
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
  // L2: profile, sub-settings, backup, challenge screens
  'Profile': 'Profil',
  'Edit name': 'Edit nama',
  'Profile category': 'Kategori profil',
  'Choose the category that best fits the user. The app will apply recommended default difficulty for new alarms.': 'Pilih kategori yang paling sesuai. Aplikasi akan guna tahap kesukaran lalai yang disyorkan untuk penggera baharu.',
  'Recommended defaults will be applied for new alarms only. Existing alarms will not be changed automatically.': 'Lalai yang disyorkan hanya digunakan untuk penggera baharu. Penggera sedia ada tidak akan berubah secara automatik.',
  'Apply Category': 'Guna Kategori',
  'Child': 'Kanak-kanak',
  'Adult': 'Dewasa',
  'Senior': 'Warga emas',
  'Used for recommended new-alarm difficulty': 'Digunakan untuk kesukaran penggera baharu yang disyorkan',
  'Guest User': 'Pengguna Tetamu',
  'User': 'Pengguna',
  'Not signed in': 'Belum log masuk',
  'Sign in to sync & backup': 'Log masuk untuk segerak & sandaran',
  'Sign out': 'Log keluar',
  'Gentler defaults for younger users.': 'Lalai lebih lembut untuk pengguna muda.',
  'Balanced defaults for regular use.': 'Lalai seimbang untuk kegunaan biasa.',
  'Lighter defaults for safer wake-up tasks.': 'Lalai lebih ringan untuk tugasan bangun yang lebih selamat.',
  '{category} category saved. Recommended defaults applied for new alarms.': 'Kategori {category} disimpan. Lalai disyorkan digunakan untuk penggera baharu.',
  '{category} category saved locally. Cloud sync will retry when you update it again.': 'Kategori {category} disimpan secara tempatan. Segerak awan akan cuba semula apabila anda mengemas kini lagi.',
  'Unable to preview this sound.': 'Tidak dapat pratonton bunyi ini.',
  'Selected audio file does not exist.': 'Fail audio yang dipilih tidak wujud.',
  'Unable to read the selected audio file path.': 'Tidak dapat membaca laluan fail audio yang dipilih.',
  'Please select an MP3, WAV, M4A, AAC, or OGG file.': 'Sila pilih fail MP3, WAV, M4A, AAC, atau OGG.',
  'Selected {file}': '{file} dipilih',
  'Unable to save the selected audio file.': 'Tidak dapat menyimpan fail audio yang dipilih.',
  'System default sound': 'Bunyi lalai sistem',
  'Saved custom audio from device': 'Audio tersuai disimpan dari peranti',
  'Bundled alarm sound': 'Bunyi penggera terbina',
  'Remove custom sound': 'Buang bunyi tersuai',
  'Stop preview': 'Henti pratonton',
  'Preview sound': 'Pratonton bunyi',
  'Alarm 1': 'Penggera 1',
  'Samsung Alarm': 'Penggera Samsung',
  'Smooth Alarm': 'Penggera Lembut',
  'Rooster Alarm': 'Penggera Ayam Jantan',
  'Birds': 'Burung',
  'System Default': 'Lalai Sistem',
  'From device…': 'Dari peranti…',
  'Choose MP3, WAV, M4A, AAC, or OGG': 'Pilih MP3, WAV, M4A, AAC, atau OGG',
  'Volume': 'Kelantangan',
  'Override phone volume': 'Guna kelantangan penggera sendiri',
  'Alarm uses its own volume level': 'Penggera menggunakan tahap kelantangan sendiri',
  'Allow volume changes mid-alarm': 'Benarkan ubah kelantangan semasa penggera',
  'Let hardware buttons adjust alarm volume': 'Benarkan butang telefon melaras kelantangan penggera',
  'Fade in': 'Naik perlahan',
  'Gradually increase volume': 'Naikkan kelantangan secara beransur',
  'Starts quiet and builds up over time': 'Mula perlahan dan meningkat dari masa ke masa',
  'Increase over {seconds}s': 'Naik dalam {seconds}s',
  'Haptics': 'Getaran',
  'Vibrate': 'Getar',
  'Enable snooze': 'Benarkan tunda',
  'Duration': 'Tempoh',
  'How long each snooze lasts': 'Berapa lama setiap tunda berlangsung',
  'Max snoozes': 'Had tunda maksimum',
  'How many times the alarm can be snoozed': 'Berapa kali penggera boleh ditunda',
  'Local device profile': 'Profil peranti tempatan',
  'Signed-in Firebase account': 'Akaun Firebase yang log masuk',
  'Restore backup': 'Pulihkan sandaran',
  'This will replace alarms, settings, profile data, and wake-up logs for the current profile only. Other local/Firebase profiles are not changed.': 'Ini akan menggantikan penggera, tetapan, data profil dan log bangun untuk profil semasa sahaja. Profil tempatan/Firebase lain tidak berubah.',
  'Choose backup': 'Pilih sandaran',
  'Back up data': 'Sandarkan data',
  'Restore data': 'Pulihkan data',
  'Protect your alarm data': 'Lindungi data penggera anda',
  'Export current profile alarms, settings, and wake logs to JSON.': 'Eksport penggera, tetapan dan log bangun profil semasa ke JSON.',
  'Import a previous Alarm Walker JSON backup for this profile.': 'Import sandaran JSON Alarm Walker terdahulu untuk profil ini.',
  'Backups are local JSON files. Restore only backups that you trust. The restore action replaces data for the current profile only.': 'Sandaran ialah fail JSON tempatan. Pulihkan hanya sandaran yang anda percayai. Tindakan pulih hanya menggantikan data profil semasa.',
  'Incorrect! Please type the sentence exactly as shown.': 'Salah! Sila taip ayat tepat seperti yang dipaparkan.',
  'Type this sentence to dismiss:': 'Taip ayat ini untuk henti:',
  'Type here...': 'Taip di sini...',
  '✓ Correct!': '✓ Betul!',
  'Match capitalization and punctuation exactly': 'Padankan huruf besar dan tanda baca dengan tepat',
  'Time\'s up!': 'Masa tamat!',
  'Skip problem': 'Langkau soalan',
  'Gentle sensitivity': 'Kepekaan lembut',
  'Balanced sensitivity': 'Kepekaan seimbang',
  'Strong shake needed': 'Perlu goncangan kuat',
  'Activity recognition permission is required to use this feature.': 'Kebenaran pengecaman aktiviti diperlukan untuk menggunakan ciri ini.',
  'Permission permanently denied. Please enable it in settings.': 'Kebenaran ditolak secara kekal. Sila benarkan dalam tetapan.',
  'Step counter error: {error}': 'Ralat pengira langkah: {error}',
  'Dismiss Alarm?': 'Hentikan penggera?',
  'You haven\'t completed the walking goal. Are you sure you want to dismiss the alarm?': 'Anda belum melengkapkan sasaran berjalan. Anda pasti mahu hentikan penggera?',
  'Dismiss Anyway': 'Henti juga',
  'of {count} steps': 'daripada {count} langkah',
  'Walk naturally for best results': 'Berjalan secara semula jadi untuk hasil terbaik',
  'Walking detected': 'Berjalan dikesan',
  'Start walking!': 'Mula berjalan!',
  'Unknown status': 'Status tidak diketahui',
  '✓ Goal reached! Tap below to dismiss': '✓ Sasaran dicapai! Ketik bawah untuk henti',
  'Walk naturally until you reach {count} steps': 'Berjalan secara semula jadi sehingga mencapai {count} langkah',
  'Permission Required': 'Kebenaran diperlukan',
  'Activity recognition permission is needed': 'Kebenaran pengecaman aktiviti diperlukan',
  'Open Settings': 'Buka Tetapan',
};
