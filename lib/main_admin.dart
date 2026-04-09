import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:alarm_walker/admin_app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This 'options' argument is what tells the Web build
  // how to talk to your Firebase project.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}
