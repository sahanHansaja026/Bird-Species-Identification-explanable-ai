import 'package:birds_app/quiz/question.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyQuizStart extends StatefulWidget {
  const MyQuizStart({super.key});

  @override
  State<MyQuizStart> createState() => _MyQuizStartState();
}

class _MyQuizStartState extends State<MyQuizStart>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onStartTap() {
    _bounceController.forward().then((_) {
      _bounceController.reverse().then((_) {
        // Navigate directly to the Bird Audio Quiz Questions Page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BirdQuizPage()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Formal White to Light Purple Linear Background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF3E5F5), // Soft, professional light purple
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top App Bar Back Button Row
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.purple.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF320B3C),
                      size: 18,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),

                const Spacer(flex: 1),

                // Subtitle Header Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1BEE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SCHOOL JUNIOR QUIZ',
                    style: GoogleFonts.inriaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6A1B9A),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Main Heading
                Text(
                  'Can You Guess\nThe Bird?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSans(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF320B3C),
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 12),

                // Description Paragraph
                Text(
                  'Listen closely to the audio clip and select the correct bird from the options. Perfect for learning together!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSans(
                    fontSize: 16,
                    color: const Color(0xFF5C5C5C),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),

                const Spacer(flex: 1),

                // Informational Stats Rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFormalStatChip('5 Questions'),
                    const SizedBox(width: 12),
                    _buildFormalStatChip('10s / Question'),
                  ],
                ),

                const Spacer(flex: 2),

                // Premium Interactive START Button
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _bounceAnimation.value,
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: _onStartTap,
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFAB47BC), // Creative Light Purple
                            Color(0xFF7B1FA2), // Deeper Formal Purple
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B1FA2).withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Start Learning Quiz',
                          style: GoogleFonts.inriaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Subtle Parent/Child hint text
                Text(
                  "Designed for students and parents",
                  style: GoogleFonts.inriaSans(
                    fontSize: 13,
                    color: const Color(0xFF7B7B7B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget for clean, icon-less informational cards
  Widget _buildFormalStatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1BEE7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inriaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4A148C),
        ),
      ),
    );
  }
}
