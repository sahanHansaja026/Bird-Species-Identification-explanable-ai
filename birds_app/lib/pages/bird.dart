import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:birds_app/global_language.dart';
import 'package:birds_app/services/translation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class AppColors {
  static const Color headerText = Color(0xFF2E1A47);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color secondaryPurple = Color(0xFF5E35B1);
  static const Color lightPurpleBg = Color(0xFFF3E5F5);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreenBg = Color(0xE8F5E9FF);
  static const Color textBody = Color(0xFF2C3E50);
  static const Color textMuted = Color(0xFF757575);
  static const Color cardShadow = Color(0x1A9C27B0);
}

// ─────────────────────────────────────────────
//  WIDGET
// ─────────────────────────────────────────────
class BirdPage extends StatefulWidget {
  final String birdId;

  const BirdPage({super.key, required this.birdId});

  @override
  State<BirdPage> createState() => _BirdPageState();
}

class _BirdPageState extends State<BirdPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isPremiumUser = false;
  bool _checkingSubscription = true;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _loadSubscription();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPlaying = false);
        _pulseCtrl.stop();
        _pulseCtrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadSubscription() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance
            .collection("subscriptions")
            .doc(uid)
            .get();

        if (doc.exists && doc.data()?["plan"] == "premium") {
          if (mounted) setState(() => _isPremiumUser = true);
        }
      }
    } catch (e) {
      debugPrint("Error fetching user subscription: $e");
    } finally {
      if (mounted) setState(() => _checkingSubscription = false);
    }
  }

  Future<void> _playSound(String url, bool isLocked) async {
    if (isLocked) {
      _showLockedDialog();
      return;
    }

    try {
      await _player.stop();
      await _player.play(UrlSource(url));
      if (mounted) {
        setState(() => _isPlaying = true);
        _pulseCtrl.repeat(reverse: true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to play audio track.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _stopSound() async {
    await _player.stop();
    if (mounted) {
      setState(() => _isPlaying = false);
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade300, width: 2),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 48,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Locked Species",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E1A47),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Ask your teacher or parent to enable full access to explore this bird's facts and sound clips!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  "Got it!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      backgroundColor: const Color(0xFFF9F8FD),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('birds')
            .doc(widget.birdId)
            .get(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting ||
              _checkingSubscription) {
            return _buildLoadingState();
          }

          // 2. Error State
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return _buildErrorState('Unable to load bird details.');
          }

          final bird = snapshot.data!.data() as Map<String, dynamic>?;

          if (bird == null) {
            return _buildErrorState('Bird record not found.');
          }

          // 3. Subscription Access Evaluation
          final bool isFreeBird = (bird['subscription'] ?? 'free') == 'free';
          final bool isLocked = !isFreeBird && !_isPremiumUser;

          final String birdName = bird['name'] ?? 'Unknown Bird';
          final String? soundUrl = bird['sound_url'];
          final List habitats = bird['habitats'] ?? [];
          final List diet = bird['diet'] ?? [];
          final List funFacts = bird['fun_facts'] ?? [];
          final String longDescription = bird['long_description'] ?? '';
          final List images = bird['images'] ?? [];
          final String? imageUrl = images.isNotEmpty ? images[0] : null;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom Animated App Bar & Header Image
              SliverAppBar(
                expandedHeight: 280.0,
                pinned: true,
                backgroundColor: AppColors.primaryPurple,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.headerText,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    birdName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black45, blurRadius: 8),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFCC8CFC),
                              AppColors.primaryPurple,
                            ],
                          ),
                        ),
                      ),
                      // Hero Image Frame with Blur if locked
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 40, bottom: 40),
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: 190,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  color:
                                                      AppColors.lightPurpleBg,
                                                  child: const Center(
                                                    child: CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation(
                                                            AppColors
                                                                .primaryPurple,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildFallbackImage(),
                                        )
                                      : _buildFallbackImage(),
                                ),
                                if (isLocked)
                                  Positioned.fill(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12,
                                      ),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.25),
                                        child: const Center(
                                          child: Icon(
                                            Icons.lock_rounded,
                                            size: 48,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Audio Player Button Section
                      if (soundUrl != null && soundUrl.isNotEmpty) ...[
                        _buildAudioButton(soundUrl, isLocked),
                        const SizedBox(height: 24),
                      ],

                      // Content Wrapped with Blur Filter if Locked
                      Stack(
                        children: [
                          Column(
                            children: [
                              // Description Section
                              if (longDescription.isNotEmpty) ...[
                                _buildDescriptionCard(longDescription),
                                const SizedBox(height: 20),
                              ],

                              // Habitats & Diet Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      title: "Live in",
                                      icon: Icons.park_rounded,
                                      iconColor: AppColors.accentGreen,
                                      bgColor: AppColors.lightGreenBg,
                                      items: habitats,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildInfoCard(
                                      title: "Diet",
                                      icon: Icons.restaurant_rounded,
                                      iconColor: const Color(0xFFE8863A),
                                      bgColor: const Color(0xFFFFF3E0),
                                      items: diet,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Fun Facts Section
                              _buildFunFactsCard(funFacts),
                            ],
                          ),

                          // Blur Filter Overlay for Details
                          if (isLocked)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    color: Colors.white.withOpacity(0.35),
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFFF3CD),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.workspace_premium_rounded,
                                              color: Color(0xFFD97706),
                                              size: 36,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            "Bird Details Locked",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color(0xFF2E1A47),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            "Ask your teacher or parent to unlock this species.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryPurple,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: _showLockedDialog,
                                            icon: const Icon(
                                              Icons.lock_open_rounded,
                                              size: 18,
                                            ),
                                            label: const Text("Unlock Access"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  AUDIO BUTTON
  // ─────────────────────────────────────────────
  Widget _buildAudioButton(String soundUrl, bool isLocked) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPlaying ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isLocked) {
              _showLockedDialog();
            } else {
              _isPlaying ? _stopSound() : _playSound(soundUrl, false);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLocked
                    ? [const Color(0xFFD97706), const Color(0xFFB45309)]
                    : _isPlaying
                    ? [const Color(0xFFFF5252), const Color(0xFFD32F2F)]
                    : [AppColors.primaryPurple, AppColors.secondaryPurple],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      (isLocked
                              ? Colors.amber.shade800
                              : _isPlaying
                              ? Colors.red
                              : AppColors.primaryPurple)
                          .withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLocked
                      ? Icons.lock_rounded
                      : _isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 12),
                FutureBuilder<String>(
                  future: t(
                    isLocked
                        ? "Unlock Bird Sound"
                        : _isPlaying
                        ? "Stop Sound"
                        : "Listen Bird Sound",
                  ),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ??
                          (isLocked
                              ? "Unlock Bird Sound"
                              : _isPlaying
                              ? "Stop Sound"
                              : "Listen Bird Sound"),
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  DESCRIPTION CARD
  // ─────────────────────────────────────────────
  Widget _buildDescriptionCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
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
                decoration: const BoxDecoration(
                  color: AppColors.lightPurpleBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.primaryPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "About Bird",
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.headerText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<String>(
            future: t(text),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildTextShimmer();
              }
              return Text(
                snapshot.data!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textBody,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  REUSABLE INFO CARD (HABITATS / DIET)
  // ─────────────────────────────────────────────
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required List items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
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
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FutureBuilder<String>(
                  future: t(title),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? title,
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headerText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              "No info available",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: FutureBuilder<String>(
                    future: t(e.toString()),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return _buildTextShimmer(height: 12);
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.fiber_manual_record,
                            size: 8,
                            color: iconColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              snapshot.data!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textBody,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FUN FACTS CARD
  // ─────────────────────────────────────────────
  Widget _buildFunFactsCard(List funFacts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFFB300),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              FutureBuilder<String>(
                future: t("Fun Facts"),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? "Fun Facts",
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.headerText,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (funFacts.isEmpty)
            Text(
              "No fun facts available",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            )
          else
            Column(
              children: funFacts.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: FutureBuilder<String>(
                    future: t(e.toString()),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return _buildTextShimmer();
                      }
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("💡 ", style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(
                                snapshot.data!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.textBody,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LOADING & ERROR STATES
  // ─────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryPurple),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Loading bird details...",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFallbackImage(height: 180),
                const SizedBox(height: 24),
                Text(
                  "Oops! Something went wrong",
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.headerText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage({double height = double.infinity}) {
    return Image.asset(
      'assets/images/error.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.lightPurpleBg,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 48,
            color: AppColors.primaryPurple,
          ),
        ),
      ),
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
