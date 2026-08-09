import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get uid => FirebaseAuth.instance.currentUser!.uid;

  /// Create subscription if it doesn't exist
  static Future<void> initializeSubscription() async {
    final doc = _db.collection("subscriptions").doc(uid);

    if (!(await doc.get()).exists) {
      await doc.set({
        "userId": uid,
        "email": FirebaseAuth.instance.currentUser?.email,
        "plan": "free",
        "active": true,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }
  }

  /// Update subscription
  static Future<void> updatePlan(String plan) async {
    await _db.collection("subscriptions").doc(uid).update({
      "plan": plan,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// Get current plan
  static Future<String> getPlan() async {
    final doc = await _db.collection("subscriptions").doc(uid).get();

    if (!doc.exists) {
      await initializeSubscription();
      return "free";
    }

    return doc.data()?["plan"] ?? "free";
  }

  /// Stream plan changes
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamPlan() {
    return _db.collection("subscriptions").doc(uid).snapshots();
  }
}