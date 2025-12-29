//wrapper for auth
import 'package:alarm_walker/screens/authenticate.dart';
import 'package:alarm_walker/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:alarm_walker/app_router.dart';
import 'package:go_router/go_router.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Home();
  }
}
