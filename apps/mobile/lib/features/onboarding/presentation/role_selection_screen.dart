import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/localization/language_selector_widget.dart';
import '../../../core/utils/auth_helpers.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../auth/presentation/auth_state.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _nameController = TextEditingController();
  String? _selectedRole; // 'worker' or 'owner'

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleRoleSubmission() async {
    final role = _selectedRole;
    if (role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account type.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final fullName = _nameController.text.trim();
    if (fullName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name (at least 2 characters).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);
    final success = await notifier.assignInitialRole(
      role: role,
      fullName: fullName,
    );

    if (success && mounted) {
      if (role == 'worker') {
        context.go('/worker/home');
      } else {
        context.go('/owner/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(authNotifierProvider);
    final strings = ref.watch(stringsProvider);
    final phoneDisplay = AuthHelpers.extractPhoneDisplay(uiState.phone ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.accountTypeTitle),
        actions: [
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: strings.signOut,
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Verified Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppDimensions.roundedMedium,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    AppSpacing.hSm,
                    Expanded(
                      child: Text(
                        strings.verifiedMobile(phoneDisplay),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.vLg,

              Text(
                strings.chooseYourRole,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vXs,
              Text(
                strings.roleSelectionSubtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.vLg,

              // Name Input Field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: strings.fullNameLabel,
                  hintText: 'e.g. Ramesh Kumar',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              AppSpacing.vXl,

              Text(
                strings.selectAccountType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vMd,

              // Option 1: WORKER Card
              InkWell(
                onTap: () => setState(() => _selectedRole = 'worker'),
                borderRadius: AppDimensions.roundedLarge,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _selectedRole == 'worker'
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : AppColors.surface,
                    borderRadius: AppDimensions.roundedLarge,
                    border: Border.all(
                      color: _selectedRole == 'worker'
                          ? AppColors.primary
                          : AppColors.border,
                      width: _selectedRole == 'worker' ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.handshake_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      AppSpacing.hMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.workerRoleTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.workerRoleDesc,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _selectedRole == 'worker'
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: _selectedRole == 'worker'
                            ? AppColors.primary
                            : AppColors.border,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vMd,

              // Option 2: OWNER Card
              InkWell(
                onTap: () => setState(() => _selectedRole = 'owner'),
                borderRadius: AppDimensions.roundedLarge,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _selectedRole == 'owner'
                        ? AppColors.accent.withValues(alpha: 0.05)
                        : AppColors.surface,
                    borderRadius: AppDimensions.roundedLarge,
                    border: Border.all(
                      color: _selectedRole == 'owner'
                          ? AppColors.accent
                          : AppColors.border,
                      width: _selectedRole == 'owner' ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 32,
                          color: AppColors.accent,
                        ),
                      ),
                      AppSpacing.hMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.ownerRoleTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.ownerRoleDesc,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _selectedRole == 'owner'
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: _selectedRole == 'owner'
                            ? AppColors.accent
                            : AppColors.border,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              // Error banner if any
              if (uiState.errorMessage != null) ...[
                AppSpacing.vLg,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                      AppSpacing.hSm,
                      Expanded(
                        child: Text(
                          uiState.errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              AppSpacing.vXxl,

              // Submit & Proceed Button
              AppPrimaryButton(
                label: strings.saveAndContinue,
                isLoading: uiState.status == AuthStatus.loading,
                onPressed: _handleRoleSubmission,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
