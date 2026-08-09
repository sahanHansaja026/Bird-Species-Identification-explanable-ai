import 'package:birds_app/services/payment_service.dart';
import 'package:birds_app/services/subscription_service.dart';
import 'package:flutter/material.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  // Selected plan state for interactive preview before updating
  String selectedPlanToggle = "premium";

  @override
  void initState() {
    super.initState();
    SubscriptionService.initializeSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: SubscriptionService.streamPlan(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String currentPlan = (data["plan"] ?? "free").toLowerCase();

          return Container(
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
                  // Top Custom App Bar
                  _buildHeader(context),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          // Hero Banner
                          _buildHeroSection(),
                          const SizedBox(height: 20),

                          // Current Plan Status Card
                          _buildCurrentPlanBadge(currentPlan),
                          const SizedBox(height: 24),

                          // Interactive Plan Selection Cards
                          _buildPlanSelector(currentPlan),
                          const SizedBox(height: 24),

                          // Feature Highlights
                          _buildFeaturesList(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // Action Button Area at Bottom
                  _buildActionButton(currentPlan),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Header Widget
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
            "BirdVox Subscription",
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

  // Hero Image / Icon Header
  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
            Icons.workspace_premium_rounded,
            size: 56,
            color: Color(0xFFD97706),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Unlock Full Bird Experience",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E1A47),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Access locked species, detailed facts & advanced AI tools.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // Current Plan Status Indicator
  Widget _buildCurrentPlanBadge(String currentPlan) {
    final bool isPremium = currentPlan == "premium";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFFFFF8E1) : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium ? Colors.amber.shade400 : Colors.purple.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPremium ? Icons.stars_rounded : Icons.info_outline_rounded,
            color: isPremium
                ? const Color(0xFFD97706)
                : const Color(0xFF9C27B0),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            "Active Status: ${currentPlan.toUpperCase()}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPremium
                  ? const Color(0xFFB45309)
                  : const Color(0xFF6A1B9A),
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Plan Options Switcher
  Widget _buildPlanSelector(String currentPlan) {
    return Row(
      children: [
        // Free Card
        Expanded(
          child: _buildPlanCard(
            planKey: "free",
            title: "Free",
            price: "\$0",
            subtitle: "Basic Access",
            isCurrent: currentPlan == "free",
          ),
        ),
        const SizedBox(width: 14),
        // Premium Card
        Expanded(
          child: _buildPlanCard(
            planKey: "premium",
            title: "Premium",
            price: "\$01.00",
            subtitle: "per month",
            isCurrent: currentPlan == "premium",
            isPopular: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String planKey,
    required String title,
    required String price,
    required String subtitle,
    required bool isCurrent,
    bool isPopular = false,
  }) {
    final bool isSelected = selectedPlanToggle == planKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlanToggle = planKey;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF9C27B0)
                    : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.purple.withOpacity(0.18)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: isSelected ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E1A47),
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? const Color(0xFF9C27B0)
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E1A47),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Current Plan",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: -10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "RECOMMENDED",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // onpress
  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Plan Comparison",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E1A47),
            ),
          ),
          const SizedBox(height: 14),
          _buildFeatureRow(
            "Explore basic species list",
            isFree: true,
            isPremium: true,
          ),
          _buildFeatureRow(
            "Search & Filter species",
            isFree: true,
            isPremium: true,
          ),
          _buildFeatureRow(
            "Unlock Premium Bird Species",
            isFree: false,
            isPremium: true,
          ),
          _buildFeatureRow(
            "High-Res Photo & Audio Gallery",
            isFree: false,
            isPremium: true,
          ),
          _buildFeatureRow(
            "Ad-free Bird Learning Experience",
            isFree: false,
            isPremium: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    String feature, {
    required bool isFree,
    required bool isPremium,
  }) {
    final bool activeForSelected = selectedPlanToggle == "premium"
        ? isPremium
        : isFree;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: activeForSelected
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activeForSelected ? Icons.check_rounded : Icons.close_rounded,
              size: 14,
              color: activeForSelected
                  ? Colors.green.shade700
                  : Colors.red.shade400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 13,
                color: activeForSelected
                    ? const Color(0xFF2E1A47)
                    : Colors.grey,
                fontWeight: activeForSelected
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dynamic Button at bottom
  Widget _buildActionButton(String currentPlan) {
    final bool isSamePlan = selectedPlanToggle == currentPlan;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSamePlan
                ? Colors.grey.shade400
                : const Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isSamePlan ? 0 : 3,
          ),
          onPressed: isSamePlan
              ? null
              : () async {
                  if (selectedPlanToggle == "premium") {
                    await PaymentService.openPayment();
                  } else {
                    await SubscriptionService.updatePlan("free");
                  }
                },
          child: Text(
            isSamePlan
                ? "Current Active Plan"
                : "Switch to ${selectedPlanToggle.toUpperCase()}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
