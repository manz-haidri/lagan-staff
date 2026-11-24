import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  bool _isCheckingConnection = false;
  String _connectionStatus = 'Initialized (Supabase Client Ready)';

  Future<void> _checkReachability() async {
    setState(() => _isCheckingConnection = true);
    final isReachable = await SupabaseService.checkEndpointReachability();
    if (mounted) {
      setState(() {
        _isCheckingConnection = false;
        _connectionStatus = isReachable
            ? 'Endpoint Reachable (ap-south-1 Connected)'
            : 'Unreachable (Check Internet or Supabase URL)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.vLg,

              // Brand Hero
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.vMd,
              const Text(
                'LaganStaff',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              AppSpacing.vXs,
              const Text(
                'लगनस्टाफ • गाजीपुर स्टाफिंग नेटवर्क',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AppSpacing.vXl,

              // Supabase BaaS Connection Indicator Card
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      size: 24,
                      color: SupabaseService.isInitialized
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    AppSpacing.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Supabase BaaS Configuration',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _connectionStatus,
                            style: TextStyle(
                              fontSize: 11,
                              color: SupabaseService.isInitialized
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _isCheckingConnection
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: _checkReachability,
                      tooltip: 'Test Endpoint Reachability',
                    ),
                  ],
                ),
              ),
              AppSpacing.vXl,

              // Section: Role-Based Module Experiences (Phase 1 Prototypes)
              const Text(
                'Role-Based Experiences (Phase 1)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vSm,

              // Option 1: Worker Module
              AppCard(
                onTap: () => context.push('/worker/dashboard'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.handshake_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    AppSpacing.hMd,
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Worker Module Experience',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'वेटर, कैटरिंग हेल्पर, सफाईकर्मी अनुभव',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.border),
                  ],
                ),
              ),
              AppSpacing.vMd,

              // Option 2: Owner Module
              AppCard(
                onTap: () => context.push('/owner/dashboard'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.accent,
                        size: 28,
                      ),
                    ),
                    AppSpacing.hMd,
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Owner Module Experience',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'मैरिज लॉन, कैटरर, टेंट हाउस मालिक अनुभव',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.border),
                  ],
                ),
              ),
              AppSpacing.vXl,

              // Action Buttons
              AppPrimaryButton(
                label: 'फोन व 4-अंकों का पिन लॉगिन (Phone + PIN Login)',
                onPressed: () => context.push('/login'),
              ),
              AppSpacing.vMd,
              AppSecondaryButton(
                label: 'भूमिका चयन (Select Role Screen)',
                onPressed: () => context.push('/select-role'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
