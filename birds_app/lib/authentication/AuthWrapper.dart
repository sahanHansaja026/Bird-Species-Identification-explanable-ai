import 'package:birds_app/authentication/login.dart';
import 'package:birds_app/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, navigate to home page
      return const HomePage();
    } else {
      // User not logged in, show login page
      return const LoginPage();
    }
  }
}
