import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  // Check whether feedback popup should show
  static Future<bool> shouldShowFeedback() async {
    final user = FirebaseAuth.instance.currentUser;

    print("AUTH USER EMAIL: ${user?.email}");
    print("AUTH USER UID: ${user?.uid}");

    if (user == null || user.email == null) {
      print("No logged in user");
      return false;
    }

    // Find Firestore user document using email
    final query = await FirebaseFirestore.instance
        .collection("users")
        .where("email", isEqualTo: user.email)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      print("User document not found by email");

      return false;
    }

    final userData = query.docs.first.data();

    print("USER DATA: $userData");

    // If feedbackCompleted field does not exist,
    // it automatically becomes false
    bool feedbackCompleted = userData['feedbackCompleted'] ?? false;

    print("FEEDBACK COMPLETED: $feedbackCompleted");

    if (feedbackCompleted) {
      print("Feedback already submitted");

      return false;
    }

    // Get signup date

    if (userData['createdAt'] == null) {
      print("Created date missing");

      return false;
    }

    Timestamp createdAt = userData['createdAt'];

    DateTime signupDate = createdAt.toDate();

    int daysPassed = DateTime.now().difference(signupDate).inDays;

    print("SIGNUP DATE: $signupDate");
    print("DAYS PASSED: $daysPassed");

    // Show feedback after 7 days

    if (daysPassed >= 7) {
      print("SHOW FEEDBACK");

      return true;
    }

    print("WAITING FOR 7 DAYS");

    return false;
  }

  // Save parent feedback

  static Future<void> saveFeedback({
    required int rating,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      print("NO USER");
      return;
    }

    print("START SAVING FEEDBACK");
    print("EMAIL: ${user.email}");
    print("RATING: $rating");
    print("COMMENT: $comment");

    try {
      // Save feedback
      DocumentReference feedbackRef = await FirebaseFirestore.instance
          .collection("feedback")
          .add({
            "userId": user.uid,
            "email": user.email,
            "rating": rating,
            "comment": comment,
            "createdAt": Timestamp.now(),
          });

      print("FEEDBACK CREATED ID: ${feedbackRef.id}");

      // Find user document

      final query = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: user.email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({"feedbackCompleted": true});

        print("USER UPDATED");
      } else {
        print("USER DOC NOT FOUND");
      }
    } catch (e) {
      print("SAVE FEEDBACK ERROR: $e");

      rethrow;
    }
  }
}
