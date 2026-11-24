import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/app_navigation.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentNavIndex = 0;

  final _navItems = const [
    AppNavigationItem(
      label: 'डैशबोर्ड',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    AppNavigationItem(
      label: 'नौकरियां',
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt_rounded,
    ),
    AppNavigationItem(
      label: 'उपस्थिति',
      icon: Icons.pin_outlined,
      selectedIcon: Icons.pin_rounded,
    ),
    AppNavigationItem(
      label: 'प्रतिष्ठान',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Experience (व्यापारी)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Header Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'राजवाड़ा मैरिज लॉन',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppBadge.pending(label: 'पहला काम समीक्षाधीन'),
                    ],
                  ),
                  AppSpacing.vXs,
                  const Text(
                    'लंका, गाजीपुर • मैरिज हॉल / लॉन',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.vMd,
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'एडमिन अनुमोदन के बाद आगामी सभी नौकरियां स्वतः प्रकाशित होंगी।',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78350F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vLg,

            // Quick Action: Post New Job
            AppPrimaryButton(
              label: 'नई नौकरी पोस्ट करें (Post Requirement)',
              icon: Icons.add_circle_outline,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job creation workflow will be activated in Phase 5.'),
                  ),
                );
              },
            ),
            AppSpacing.vLg,

            // Live Duty Pass Gate Check-in Section
            const Text(
              'गेट उपस्थिति सत्यापन (Gate 4-Digit PIN Check-In)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.vSm,
            AppCard(
              borderColor: AppColors.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'कार्यकर्ता का 4-अंकों का ड्यूटी पास कोड दर्ज करें:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  AppSpacing.vSm,
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            '•••• (Enter 4-Digit Code)',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.hSm,
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('सत्यापित करें'),
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
