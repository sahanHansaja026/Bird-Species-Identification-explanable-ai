import 'package:birds_app/authentication/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────
class AppColors {
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color secondaryPurple = Color(0xFF7B1FA2);
  static const Color bgGradientStart = Color(0xFFE8DAEF);
  static const Color bgGradientEnd = Color(0xFFF4ECF7);
  static const Color cardBg = Colors.white;
  static const Color textHeader = Color(0xFF2E1A47);
  static const Color textBody = Color(0xFF37474F);
  static const Color textMuted = Color(0xFF78909C);
  static const Color validGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFFF5252);
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Dynamic Validation States
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasUppercase = false;

  late AnimationController _floatingCtrl;
  late Animation<double> _floatingAnim;

  @override
  void initState() {
    super.initState();

    // Floating logo animation
    _floatingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatingAnim = Tween<double>(
      begin: 0.0,
      end: -8.0,
    ).animate(CurvedAnimation(parent: _floatingCtrl, curve: Curves.easeInOut));

    // Live validation listeners
    nameController.addListener(_validateName);
    emailController.addListener(_validateEmail);
    passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _floatingCtrl.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // VALIDATION LOGIC
  // ─────────────────────────────────────────────
  void _validateName() {
    final name = nameController.text.trim();
    final nameParts = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final nameRegex = RegExp(r"^[a-zA-Z\s\.'-]+$");

    setState(() {
      _isNameValid = nameParts.length >= 2 && nameRegex.hasMatch(name);
    });
  }

  void _validateEmail() {
    final email = emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    setState(() {
      _isEmailValid = emailRegex.hasMatch(email);
    });
  }

  void _validatePassword() {
    final pwd = passwordController.text;

    setState(() {
      _hasMinLength = pwd.length >= 8;
      _hasNumber = RegExp(r'[0-9]').hasMatch(pwd);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(pwd);
    });
  }

  bool get _isFormValid =>
      _isNameValid &&
      _isEmailValid &&
      _hasMinLength &&
      _hasNumber &&
      _hasUppercase;

  // ─────────────────────────────────────────────
  // FIREBASE SIGNUP
  // ─────────────────────────────────────────────
  Future<void> signUpUser() async {
    if (!_isFormValid) {
      _showSnackBar("Please fill out all fields correctly.");
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      final user = userCredential.user!;

      // Update Firebase Auth display name
      await user.updateDisplayName(nameController.text.trim());

      // Save user information
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'full_name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create FREE subscription automatically
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'email': emailController.text.trim(),
            'plan': 'free',
            'active': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        _showSnackBar("Signup successful! Welcome aboard!");
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Signup failed");
    } catch (e) {
      _showSnackBar("An unexpected error occurred.");
      debugPrint(e.toString());
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.fredoka(fontSize: 14)),
        backgroundColor: AppColors.secondaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Mascot / Image
                Center(
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _floatingAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _floatingAnim.value),
                          child: child,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            "assets/images/signup.png",
                            width: 70,
                            height: 70,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.emoji_nature_rounded,
                              size: 60,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Join Serendib Chirps",
                            style: GoogleFonts.fredoka(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHeader,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.flutter_dash_rounded,
                            color: AppColors.primaryPurple,
                            size: 28,
                          ),
                        ],
                      ),
                      Text(
                        "Create your explorer account below",
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          color: AppColors.secondaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 1. Full Name Input Card
                _buildInputField(
                  label: "Full Name",
                  hint: "e.g. Maya Lin",
                  icon: Icons.face_rounded,
                  controller: nameController,
                  isValid: _isNameValid,
                  validationMsg: nameController.text.isEmpty
                      ? null
                      : (_isNameValid
                            ? "Looks great!"
                            : "Enter first & last name (letters only)"),
                ),

                const SizedBox(height: 16),

                // 2. Email Input Card
                _buildInputField(
                  label: "Email Address",
                  hint: "explorer@birds.com",
                  icon: Icons.alternate_email_rounded,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  isValid: _isEmailValid,
                  validationMsg: emailController.text.isEmpty
                      ? null
                      : (_isEmailValid
                            ? "Valid email!"
                            : "Enter a valid email address"),
                ),

                const SizedBox(height: 16),

                // 3. Password Input Card
                _buildInputField(
                  label: "Password",
                  hint: "Create a strong password",
                  icon: Icons.lock_outline_rounded,
                  controller: passwordController,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppColors.secondaryPurple,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Dynamic Password Checklist
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Password Strength Checklist",
                            style: GoogleFonts.fredoka(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHeader,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildCheckRule(
                        "At least 8 characters long",
                        _hasMinLength,
                        passwordController.text.isNotEmpty,
                      ),
                      _buildCheckRule(
                        "Includes numbers (0-9)",
                        _hasNumber,
                        passwordController.text.isNotEmpty,
                      ),
                      _buildCheckRule(
                        "Includes uppercase letter (A-Z)",
                        _hasUppercase,
                        passwordController.text.isNotEmpty,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Terms Notice
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    children: [
                      const TextSpan(
                        text: "By tapping Next, you agree to our ",
                      ),
                      TextSpan(
                        text: "BirdVox AI Terms & Conditions",
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Signup Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? signUpUser : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      disabledBackgroundColor: AppColors.primaryPurple
                          .withOpacity(0.4),
                      elevation: _isFormValid ? 6 : 0,
                      shadowColor: AppColors.primaryPurple.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Start Exploring",
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Redirect to Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: Text(
                        "Log In",
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // REUSABLE WIDGET BUILDERS
  // ─────────────────────────────────────────────
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    bool? isValid,
    String? validationMsg,
  }) {
    Color borderColor = Colors.transparent;
    if (validationMsg != null) {
      borderColor = isValid! ? AppColors.validGreen : AppColors.errorRed;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeader,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: GoogleFonts.fredoka(fontSize: 15, color: AppColors.textBody),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.fredoka(
                fontSize: 14,
                color: AppColors.textMuted.withOpacity(0.6),
              ),
              prefixIcon: Icon(icon, color: AppColors.secondaryPurple),
              suffixIcon:
                  suffixIcon ??
                  (validationMsg == null
                      ? null
                      : Icon(
                          isValid!
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: isValid
                              ? AppColors.validGreen
                              : AppColors.errorRed,
                        )),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (validationMsg != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              validationMsg,
              style: GoogleFonts.fredoka(
                fontSize: 11,
                color: isValid! ? AppColors.validGreen : AppColors.errorRed,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckRule(String text, bool isMet, bool hasTyped) {
    Color checkColor = Colors.grey.shade300;
    Color textColor = AppColors.textMuted;

    if (hasTyped) {
      if (isMet) {
        checkColor = AppColors.validGreen;
        textColor = AppColors.validGreen;
      } else {
        checkColor = AppColors.errorRed.withOpacity(0.8);
        textColor = AppColors.errorRed;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checkColor,
            ),
            child: Icon(
              isMet ? Icons.check_rounded : Icons.close_rounded,
              size: 12,
              color: hasTyped ? Colors.white : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              color: textColor,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
