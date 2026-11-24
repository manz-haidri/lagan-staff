import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/app_navigation.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  int _currentNavIndex = 0;

  final _navItems = const [
    AppNavigationItem(
      label: 'होम (Home)',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    AppNavigationItem(
      label: 'काम (Jobs)',
      icon: Icons.work_outline_rounded,
      selectedIcon: Icons.work_rounded,
    ),
    AppNavigationItem(
      label: 'ड्यूटी पास',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge_rounded,
    ),
    AppNavigationItem(
      label: 'प्रोफाइल',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Experience (कार्यकर्ता)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            AppCard(
              backgroundColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'नमस्ते, कार्यकर्ता साथी',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppBadge.success(label: 'सक्रिय (Active)'),
                    ],
                  ),
                  AppSpacing.vSm,
                  const Text(
                    'गाजीपुर और निकटवर्ती क्षेत्रों में दैनिक काम के अवसर।',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vLg,

            // Section Header
            const Text(
              'उपलब्ध नौकरियां (Available Shifts Preview)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.vSm,

            // Mock Job Card 1
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '10 वेटर्स की आवश्यकता',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppBadge.pending(label: 'तत्काल (Urgent)'),
                    ],
                  ),
                  AppSpacing.vXs,
                  const Text(
                    'राजवाड़ा मैरिज लॉन • लंका, गाजीपुर',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.vSm,
                  const Divider(color: AppColors.border),
                  AppSpacing.vSm,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'कल, शाम 5:00 बजे',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Text(
                        '₹650 / शिफ्ट',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.vMd,

            // Mock Job Card 2
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '4 हलवाई हेल्पर',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppBadge.neutral(label: 'कैटरिंग'),
                    ],
                  ),
                  AppSpacing.vXs,
                  const Text(
                    'शाही दावत कैटरर्स • महुआबाग, गाजीपुर',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.vSm,
                  const Divider(color: AppColors.border),
                  AppSpacing.vSm,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '25 नवम्बर, सुबह 8:00 बजे',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Text(
                        '₹750 / शिफ्ट',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: (index) => setState(() => _currentNavIndex = index),
        items: _navItems,
      ),
    );
  }
}
