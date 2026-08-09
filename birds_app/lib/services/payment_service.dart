import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  static const String premiumUrl =
      "https://buy.stripe.com/test_00w7sL2NF3AHdR6gs708g00";

  static Future<void> openPayment() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint("User is not logged in");
        return;
      }

      final String uid = user.uid;

      debugPrint("Opening Stripe payment for UID: $uid");

      // Add Firebase UID to the Stripe Payment Link
      final Uri paymentUrl = Uri.parse("$premiumUrl?client_reference_id=$uid");

      final bool launched = await launchUrl(
        paymentUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint("Could not open Stripe payment");
      }
    } catch (e) {
      debugPrint("Payment error: $e");
    }
  }
}
