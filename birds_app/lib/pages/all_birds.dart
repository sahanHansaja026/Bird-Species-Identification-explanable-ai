import 'package:birds_app/pages/bird.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class All_Birds_List extends StatefulWidget {
  final bool isPremium;

  const All_Birds_List({super.key, this.isPremium = false});

  @override
  State<All_Birds_List> createState() => _All_Birds_ListState();
}

class _All_Birds_ListState extends State<All_Birds_List> {
  static const int pageSize = 20;

  final String defaultBirdImageUrl =
      'https://images.unsplash.com/photo-1444464666168-49d633b86797?auto=format&fit=crop&w=300&q=80';

  List<Map<String, dynamic>> birds = [];
  List<Map<String, dynamic>> filteredBirds = [];
  bool isPremiumUser = false;
  bool subscriptionLoading = true;

  // Pagination state tracking
  int currentPage = 1;
  bool loading = false;
  bool hasNextPage = true;
  final Map<int, DocumentSnapshot?> pageSnapshots = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadPage(1);
    loadSubscription();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadSubscription() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc = await FirebaseFirestore.instance
          .collection("subscriptions")
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        setState(() {
          isPremiumUser = data["plan"] == "premium";
          subscriptionLoading = false;
        });
      } else {
        setState(() {
          isPremiumUser = false;
          subscriptionLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        subscriptionLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      if (_searchQuery.isEmpty) {
        filteredBirds = List.from(birds);
      } else {
        filteredBirds = birds.where((bird) {
          final name = (bird['name'] ?? '').toString().toLowerCase();
          final sciName = (bird['scientific_name'] ?? '')
              .toString()
              .toLowerCase();
          return name.contains(_searchQuery) || sciName.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> loadPage(int page) async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    Query query = FirebaseFirestore.instance
        .collection("birds")
        .orderBy("name")
        .limit(pageSize);

    if (page > 1) {
      final prevLastDoc = pageSnapshots[page - 1];
      if (prevLastDoc != null) {
        query = query.startAfterDocument(prevLastDoc);
      }
    }

    try {
      QuerySnapshot snap = await query.get();

      if (snap.docs.isNotEmpty) {
        pageSnapshots[page] = snap.docs.last;

        List<Map<String, dynamic>> loadedBirds = snap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        setState(() {
          birds = loadedBirds;
          currentPage = page;
          hasNextPage = snap.docs.length == pageSize;
        });
      } else {
        setState(() {
          birds = [];
          hasNextPage = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading birds: $e");
    } finally {
      setState(() {
        loading = false;
        _onSearchChanged();
      });
    }
  }

  void _showLockedDialog(BuildContext context) {
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
                "Ask your teacher or parent to enable full access to explore this bird's facts!",
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
                  backgroundColor: const Color(0xFF9C27B0),
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
              // Custom Creative AppBar & Header
              _buildHeader(),

              // Animated Card List or Skeleton Loader
              Expanded(
                child: loading
                    ? _buildSkeletonList()
                    : filteredBirds.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        itemCount: filteredBirds.length,
                        itemBuilder: (context, index) {
                          return _AnimatedBirdCard(
                            index: index,
                            bird: filteredBirds[index],
                            isPremiumUser: isPremiumUser,
                            defaultImageUrl: defaultBirdImageUrl,
                            onTapLocked: () => _showLockedDialog(context),
                            onTapBird: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BirdPage(
                                    birdId: filteredBirds[index]['id'],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),

              // Page Controls for Pagination
              if (_searchQuery.isEmpty) _buildPaginationControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Back Arrow Button
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
                  const SizedBox(width: 8),

                  // App/Screen Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.12),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF9C27B0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title Text
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "BirdVox AI",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E1A47),
                        ),
                      ),
                      Text(
                        "Discover & Learn Species",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5E35B1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Page Indicator Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: Color(0xFF9C27B0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Page $currentPage",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E1A47),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Field Widget
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search birds by name...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9C27B0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3E5F5),
              foregroundColor: const Color(0xFF9C27B0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: (currentPage > 1 && !loading)
                ? () => loadPage(currentPage - 1)
                : null,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: const Text("Previous"),
          ),
          Text(
            "Page $currentPage",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E1A47),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: (hasNextPage && !loading)
                ? () => loadPage(currentPage + 1)
                : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            label: const Text("Next"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.purple.shade200,
          ),
          const SizedBox(height: 12),
          Text(
            "No birds found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Try adjusting your search terms",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  //Expanded
  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 90,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        color: Colors.purple.shade50,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 10,
                        color: Colors.purple.shade50,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Animated Card Component
class _AnimatedBirdCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> bird;
  final bool isPremiumUser;
  final String defaultImageUrl;
  final VoidCallback onTapLocked;
  final VoidCallback onTapBird;

  const _AnimatedBirdCard({
    required this.index,
    required this.bird,
    required this.isPremiumUser,
    required this.defaultImageUrl,
    required this.onTapLocked,
    required this.onTapBird,
  });

  @override
  State<_AnimatedBirdCard> createState() => _AnimatedBirdCardState();
}

class _AnimatedBirdCardState extends State<_AnimatedBirdCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Staggered entrance animation delay based on card list position
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool locked =
        widget.bird['subscription'] != "free" && !widget.isPremiumUser;

    String imageUrl = widget.defaultImageUrl;
    if (widget.bird['images'] != null &&
        (widget.bird['images'] as List).isNotEmpty &&
        widget.bird['images'][0].toString().startsWith('http')) {
      imageUrl = widget.bird['images'][0];
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: _visible ? 1.0 : 0.0,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 350),
        padding: _visible
            ? const EdgeInsets.only(bottom: 14)
            : const EdgeInsets.only(bottom: 30),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: locked ? widget.onTapLocked : widget.onTapBird,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: Colors.purple.shade50,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            widget.defaultImageUrl,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bird['name'] ?? 'Unknown Bird',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.bird['scientific_name'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: locked
                          ? const Color(0xFFFFF3CD)
                          : const Color(0xFFF3E5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      locked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                      color: locked
                          ? const Color(0xFFD97706)
                          : const Color(0xFF9C27B0),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
