import 'package:birds_app/global_language.dart';
import 'package:birds_app/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class AppColors {
  static const Color headerText = Color(0xFF2E1A47);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color secondaryPurple = Color(0xFF5E35B1);
  static const Color textBody = Color(0xFF2C3E50);
  static const Color textMuted = Color(0xFF616161);
}

class About_Us_Page extends StatefulWidget {
  const About_Us_Page({super.key});

  @override
  State<About_Us_Page> createState() => _About_Us_PageState();
}

class _About_Us_PageState extends State<About_Us_Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(
      begin: 0.0,
      end: -6.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  // Translation Helper matching BirdPage pattern
  Future<String> t(String text) async {
    if (text.trim().isEmpty) return "";
    try {
      return await TranslationService.translate(
        text: text,
        targetLang: currentLanguage.value,
      );
    } catch (_) {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCC8CFC), Color(0xFFF9F9F9)],
          ),
        ),
        child: SafeArea(
          // Listens to global language changes and automatically re-translates on switch
          child: ValueListenableBuilder<String>(
            valueListenable: currentLanguage,
            builder: (context, lang, child) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.headerText,
                            size: 20,
                          ),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: child,
                          ),
                          child: const Icon(
                            Icons.flutter_dash_rounded,
                            size: 38,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    Text(
                      "BirdVox AI",
                      style: GoogleFonts.fredoka(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerText,
                      ),
                    ),
                    _buildTranslatedText(
                      "Final Year Research Project • Faculty of Computing & IT",
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        color: AppColors.secondaryPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Initial Summary
                    _buildTranslatedText(
                      "BirdVox AI is an explainable audio-based machine learning platform designed to identify bird species through audio recordings, combining AI research with child-friendly educational engagement.",
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textBody,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Development Team Section Title
                    Text(
                      "Development Team",
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerText,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1. Jayasundara (Data Science)
                    _MemberItem(
                      imagePath: 'assets/images/samadi.jpeg',
                      initials: "JJ",
                      name: "D.M.S.Y. Jayasundara",
                      role: "Data Science",
                      department: "Department of Data Science",
                      t: t,
                    ),
                    const SizedBox(height: 18),

                    // 2. Rajaguru (Data Science)
                    _MemberItem(
                      imagePath: 'assets/images/saduni.png',
                      initials: "RR",
                      name: "I.W.S.C.R. Rajaguru",
                      role: "Data Science",
                      department: "Department of Data Science",
                      t: t,
                    ),
                    const SizedBox(height: 18),

                    // 3. Sahan Hansaja (Software Engineering)
                    _MemberItem(
                      imagePath: 'assets/images/sahan.jpeg',
                      initials: "SH",
                      name: "M.M.S. Hansaja",
                      role: "Software Engineering",
                      department: "Department of Software Engineering",
                      t: t,
                    ),
                    const SizedBox(height: 18),

                    // 4. Wijewardhana (Data Science)
                    _MemberItem(
                      imagePath: 'assets/images/deshani.jpeg',
                      initials: "MW",
                      name: "M.A.D.H. Wijewardhana",
                      role: "Data Science",
                      department: "Department of Data Science",
                      t: t,
                    ),

                    const SizedBox(height: 16),

                    // Supervisor Mention
                    _buildTranslatedText(
                      "Supervised by Dr. Chameera De Silva",
                      style: GoogleFonts.fredoka(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Research & Key Features Title
                    _buildTranslatedText(
                      "Research & Key Features",
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTranslatedText(
                      "Our research focuses on combining state-of-the-art audio signal processing with deep neural networks for accurate bird species identification. To ensure transparency, BirdVox AI integrates Explainable AI (Grad-CAM) to generate visual spectrographic heatmaps explaining neural decisions.\n\nTo ensure accessibility for diverse users and young learners, the app includes multi-language audio and text support with dynamic translation capabilities.",
                      style: GoogleFonts.fredoka(
                        fontSize: 13.5,
                        height: 1.55,
                        color: AppColors.textBody,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // University Context
                    Text(
                      "Sri Lanka Technological Campus (SLTC)",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTranslatedText(
                      "All team members are undergraduates from the Faculty of Computing & IT at Sri Lanka Technological Campus (SLTC). SLTC is a premier research-driven university in Sri Lanka dedicated to providing cutting-edge higher education in technology, engineering, and data science, fostering innovative interdisciplinary solutions.",
                      style: GoogleFonts.fredoka(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.textBody,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Footer
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Version 1.0.0",
                            style: GoogleFonts.fredoka(
                              fontSize: 12,
                              color: AppColors.secondaryPurple,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "© 2026 Sri Lanka Technological Campus (Pvt) Ltd",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper Widget for Async Translation Rendering with Skeleton Shimmer
  Widget _buildTranslatedText(String text, {required TextStyle style}) {
    return FutureBuilder<String>(
      future: t(text),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildTextShimmer();
        }
        return Text(snapshot.data!, style: style);
      },
    );
  }

  Widget _buildTextShimmer({double height = 14}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// Translated Team Member Item
class _MemberItem extends StatelessWidget {
  final String imagePath;
  final String initials;
  final String name;
  final String role;
  final String department;
  final Future<String> Function(String) t;

  const _MemberItem({
    required this.imagePath,
    required this.initials,
    required this.name,
    required this.role,
    required this.department,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Member Photo with Fallback
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFE1BEE7),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryPurple,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.fredoka(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headerText,
                ),
              ),
              FutureBuilder<String>(
                future: t(role),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? role,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
              FutureBuilder<String>(
                future: t(department),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? department,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
