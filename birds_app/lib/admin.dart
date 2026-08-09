import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Admin());
}

class Admin extends StatelessWidget {
  const Admin({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BirdListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BirdListPage extends StatefulWidget {
  const BirdListPage({super.key});

  @override
  State<BirdListPage> createState() => _BirdListPageState();
}

class _BirdListPageState extends State<BirdListPage> {
  List<Map<String, dynamic>> birds = [];
  String status = "Loading...";

  @override
  void initState() {
    super.initState();
    getBirds();
  }

  Future<void> getBirds() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("birds")
          .get();

      setState(() {
        birds = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        status = "✅ Loaded ${birds.length} birds";
      });
    } catch (e) {
      setState(() {
        status = "❌ Error loading data";
      });
      print("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Birds"), centerTitle: true),

      body: birds.isEmpty
          ? Center(child: Text(status, style: const TextStyle(fontSize: 18)))
          : ListView.builder(
              itemCount: birds.length,
              itemBuilder: (context, index) {
                final bird = birds[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: Image.network(
                      bird['main_image'] ?? "",
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported);
                      },
                    ),
                    title: Text(bird['name'] ?? "No Name"),
                    subtitle: Text(
                      bird['short_description'] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
