import 'package:birds_app/admin.dart';
import 'package:birds_app/audio/recode.dart';
import 'package:birds_app/authentication/login.dart';
import 'package:birds_app/global_language.dart';
import 'package:birds_app/pages/abut_us.dart';
import 'package:birds_app/pages/home.dart';
import 'package:birds_app/pages/privacy.dart';
import 'package:birds_app/pages/subscripion.dart';
import 'package:birds_app/quiz/start.dart';
import 'package:birds_app/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, String> translations = {};

  final List<String> menuItems = [
    "Home",
    "Record Bird Sound",
    "Questions & answers",
    "Subscription",
    "About us",
    "Privacy Policy",
    "Admin Only",
  ];

  @override
  void initState() {
    super.initState();
    _loadTranslations(currentLanguage.value);
    // Listen for language changes
    currentLanguage.addListener(() {
      _loadTranslations(currentLanguage.value);
    });
  }

  void _loadTranslations(String lang) async {
    Map<String, String> t = await TranslationService.preloadTranslations(
      menuItems,
      lang,
    );
    setState(() {
      translations = t;
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            padding: EdgeInsets.zero,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -20,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper: SemiCircleClipper(),
                    child: Container(
                      height: 100,
                      color: const Color.fromARGB(255, 188, 8, 185),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage("assets/images/appicon.jpeg"),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: const Text(
                    "Serendib Chirps",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Language selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ValueListenableBuilder(
                  valueListenable: currentLanguage,
                  builder: (context, value, _) {
                    return Radio<String>(
                      value: "en",
                      groupValue: value,
                      onChanged: (val) {
                        currentLanguage.value = val!;
                      },
                    );
                  },
                ),
                const Text("English"),
                const SizedBox(width: 16),
                ValueListenableBuilder(
                  valueListenable: currentLanguage,
                  builder: (context, value, _) {
                    return Radio<String>(
                      value: "si",
                      groupValue: value,
                      onChanged: (val) {
                        currentLanguage.value = val!;
                      },
                    );
                  },
                ),
                const Text("සිංහල"),
              ],
            ),
          ),

          const Divider(),

          // Menu items
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(translations["Home"] ?? "Home"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: Text(
              translations["Record Bird Sound"] ?? "Record Bird Sound",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AudioRecordPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: Text(
              translations["Questions & answers"] ?? "Questions & answers",
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyQuizStart()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.paid),
            title: Text(translations["Subscription"] ?? "Subscription"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SubscriptionPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text(translations["About us"] ?? "About us"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => About_Us_Page()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: Text(translations["Privacy Policy"] ?? "Privacy Policy"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: Text(translations["Admin Only"] ?? "Admin Only"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Admin()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

// Semi-circle header
class SemiCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width / 2, size.height * 2, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
