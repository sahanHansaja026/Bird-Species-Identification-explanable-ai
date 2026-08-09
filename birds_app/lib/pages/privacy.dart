import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 204, 140, 252),
              Color.fromARGB(255, 249, 249, 249),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header App Bar
              _buildHeader(context),

              // Policy Content List
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Banner Icon & Title
                      _buildHeroSection(),
                      const SizedBox(height: 20),

                      // Effective Date Tag
                      _buildEffectiveDateTag(),
                      const SizedBox(height: 20),

                      // Privacy Content Sections
                      _buildPolicyCard(
                        icon: Icons.shield_outlined,
                        title: "1. Overview & Commitment",
                        content:
                            "Welcome to BirdVox AI. Your privacy is fundamental to us. This Privacy Policy explains how we collect, use, store, and protect your information when you interact with our mobile application and services.",
                      ),

                      _buildPolicyCard(
                        icon: Icons.data_usage_rounded,
                        title: "2. Information We Collect",
                        content:
                            "• Account Data: Email address and authentication status via Google or Firebase Auth.\n"
                            "• Usage Data: Information about species viewed, search queries, and subscription status (Free vs. Premium).\n"
                            "• Media Data: Photos or audio recordings uploaded temporarily for bird identification features.",
                      ),

                      _buildPolicyCard(
                        icon: Icons.stars_rounded,
                        title: "3. Subscription & Billing Data",
                        content:
                            "We do not process or store payment credentials directly on our servers. All subscription transactions (including Free and Premium upgrades) are securely handled through standard platform store systems (Google Play / Apple App Store).",
                      ),

                      _buildPolicyCard(
                        icon: Icons.lock_outline_rounded,
                        title: "4. Data Security & Storage",
                        content:
                            "We implement robust technical and organizational security measures using Google Firebase infrastructure to protect your personal information against unauthorized access, loss, or alteration.",
                      ),

                      _buildPolicyCard(
                        icon: Icons.family_restroom_rounded,
                        title: "5. Children's Privacy",
                        content:
                            "BirdVox AI is designed as an educational tool for all ages. We do not knowingly harvest personal identifiers from children without consent from a parent or guardian.",
                      ),

                      _buildPolicyCard(
                        icon: Icons.contact_support_outlined,
                        title: "6. Contact Us",
                        content:
                            "If you have questions, feedback, or data privacy requests regarding this Privacy Policy, please reach out to our team at support@birdvox.ai.",
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Bar Widget
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.purple.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2E1A47),
              size: 20,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 12),
          const Text(
            "Privacy Policy",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E1A47),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Image Banner
  Widget _buildHeroSection() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.privacy_tip_rounded,
              size: 48,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Your Data & Privacy",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E1A47),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "How we handle and protect your information",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  // Effective Date Badge
  Widget _buildEffectiveDateTag() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF9C27B0)),
          SizedBox(width: 6),
          Text(
            "Last Updated: July 2026",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E1A47),
            ),
          ),
        ],
      ),
    );
  }

  // Section Card Builder
  Widget _buildPolicyCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF9C27B0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E1A47),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
