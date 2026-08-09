import 'package:birds_app/pages/all_birds.dart';
import 'package:birds_app/authentication/login.dart';
import 'package:birds_app/pages/bird.dart';
import 'package:birds_app/components/app_drawer.dart';
import 'package:birds_app/feedback/feedback_dialog.dart';
import 'package:birds_app/services/feedback_service.dart';
import 'package:birds_app/global_language.dart' show currentLanguage;
import 'package:birds_app/audio/recode.dart';
import 'package:birds_app/services/translation_service.dart';
import 'package:birds_app/audio/upload.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String debugText = "Checking Birds...";
  List<Map<String, dynamic>> birds = [];

  final PageController _controller = PageController(viewportFraction: 0.8);
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    getBirds();

    checkFeedback();
  }

  void checkFeedback() async {
    bool show = await FeedbackService.shouldShowFeedback();

    print("FEEDBACK STATUS: $show");

    if (show) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          print("SHOWING FEEDBACK POPUP");
          showFeedbackDialog(context);
        }
      });
    }
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<String> t(String text) async {
    return await TranslationService.translate(
      text: text,
      targetLang: currentLanguage.value,
    );
  }

  Future<void> getBirds() async {
    try {
      final snap = await FirebaseFirestore.instance.collection("birds").get();

      List<Map<String, dynamic>> allBirds = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Shuffle birds randomly
      allBirds.shuffle();

      // Take only first 5 birds
      final randomBirds = allBirds.take(5).toList();

      setState(() {
        birds = randomBirds;
        debugText = "📦 Birds: ${birds.length}";
      });
    } catch (e) {
      setState(() {
        debugText = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(180),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Row(
              children: [
                Image.asset(
                  "assets/images/homebird.png",
                  width: 150,
                  height: 150,
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsetsGeometry.only(bottom: 80, right: 10),
                  child: Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Image.asset(
                        "assets/images/menu.png",
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      drawer: const AppDrawer(),

      // ================= SCROLLABLE BODY =================
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

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 120),

              // ===== HEADER TEXT =====
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Discover More",
                        style: GoogleFonts.inriaSans(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("Explore nature wildlife birds and"),
                      const Text("their sounds"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // ===== BUTTONS =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD6D900),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AudioRecordPage(), // your page class
                        ),
                      );
                    },
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text("Record Audio"),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD6D900),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UploadSound(), // your page class
                        ),
                      );
                    },
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("Upload Bird Sound"),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Text(
                      "Featured Birds",
                      style: GoogleFonts.fredoka(fontSize: 22),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => All_Birds_List(),
                          ),
                        );
                      },
                      child: const Text("see all"),
                    ),
                  ],
                ),
              ),

              // ===== PAGEVIEW + ANIMATION =====
              SizedBox(
                height: 400,
                child: birds.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : PageView.builder(
                        controller: _controller,
                        itemCount: birds.length,
                        physics: const ClampingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            currentIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              double value = 0;

                              if (_controller.position.haveDimensions) {
                                value = index - (_controller.page ?? 0);
                              } else {
                                value = index.toDouble();
                              }

                              value = value.clamp(-1.0, 1.0);

                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(value * 0.8),
                                alignment: Alignment.center,
                                child: child,
                              );
                            },
                            child: _buildBirdCard(context, birds[index]),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 15),

              // ===== DOT INDICATOR =====
              if (birds.isNotEmpty)
                Center(
                  child: AnimatedSmoothIndicator(
                    activeIndex: currentIndex,
                    count: birds.length,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Colors.black,
                      dotColor: Colors.grey,
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= BIRD CARD =================
Widget _buildBirdCard(BuildContext context, Map bird) {
  Future<String> t(String text) async {
    return await TranslationService.translate(
      text: text,
      targetLang: currentLanguage.value,
    );
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 10),
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 60),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF9EC1D4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const SizedBox(height: 60),

              Text(
                bird['name'] ?? '',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                bird['scientific_name'] ?? '',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              FutureBuilder<String>(
                future: t(bird['short_description'] ?? ""),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  return Text(
                    snapshot.data!,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inriaSans(
                      fontSize: 13,
                      color: const Color.fromARGB(211, 83, 83, 83),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BirdPage(birdId: bird['id']),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6D900),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text("Learn More >"),
                ),
              ),
            ],
          ),
        ),

        CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(
            (bird['images'] != null && bird['images'].isNotEmpty)
                ? bird['images'][0]
                : "https://via.placeholder.com/150",
          ),
        ),
      ],
    ),
  );
}
