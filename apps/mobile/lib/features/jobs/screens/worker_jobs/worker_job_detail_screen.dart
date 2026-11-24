import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_loaders.dart';
import '../../models/job_model.dart';
import '../../presentation/owner_jobs_notifier.dart';

class WorkerJobDetailScreen extends ConsumerWidget {
  final String jobId;

  const WorkerJobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final jobAsync = ref.watch(jobDetailProvider(jobId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.jobDetailsTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: strings.refresh,
            onPressed: () => ref.invalidate(jobDetailProvider(jobId)),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.perShiftLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    jobAsync.when(
                      data: (job) => Text(
                        '₹${job.wageAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.success),
                      ),
                      loading: () => const Text('...'),
                      error: (_, _) => const Text('-'),
                    ),
                  ],
                ),
              ),
              AppSpacing.hMd,
              Expanded(
                flex: 2,
                child: jobAsync.when(
                  data: (job) {
                    if (job.isExpired) {
                      return AppSecondaryButton(
                        label: strings.shiftExpired,
                        icon: Icons.history_toggle_off_rounded,
                        onPressed: null,
                      );
                    }

                    return AppPrimaryButton(
                      label: strings.applyNow,
                      icon: Icons.send_rounded,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dlgCtx) => AlertDialog(
                            title: Text(
                              strings.language == AppLanguage.hindi
                                  ? 'कार्यकर्ता आवेदन (Phase 7)'
                                  : 'Worker Application (Phase 7)',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            content: Text(
                              strings.language == AppLanguage.hindi
                                  ? 'कार्यकर्ता आवेदन, ऑन-साइट उपस्थिति सत्यापन (4-अंकीय चेक-इन कोड) एवं बुकिंग स्वीकृति प्रणाली सक्रिय है।'
                                  : 'Worker shift booking and attendance PIN check-in are active.',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dlgCtx),
                                child: Text(strings.ok),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: jobAsync.when(
        data: (job) => _buildJobBody(context, job, strings),
        loading: () => Center(child: AppLoader(message: strings.loadingProfile)),
        error: (e, _) => Center(child: Text('${strings.errorPrefix}$e')),
      ),
    );
  }

  Widget _buildJobBody(BuildContext context, JobModel job, AppStrings strings) {
    final isHindi = strings.language == AppLanguage.hindi;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Availability Status Banner
          _buildAvailabilityStatusCard(job, strings),
          AppSpacing.vMd,

          // Business Identity Card (Verified Organizer)
          AppCard(
            backgroundColor: AppColors.primary.withValues(alpha: 0.05),
            borderColor: AppColors.primary.withValues(alpha: 0.2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.businessName ?? (isHindi ? 'सत्यापित व्यवसाय' : 'Verified Business'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      AppSpacing.vXs,
                      Text(
                        '${job.businessLocality ?? job.locality}, ${job.city} • ${isHindi ? 'सत्यापित आयोजक' : 'Verified Host'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vMd,

          // Main Overview Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.categoryName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: job.isExpired
                            ? AppColors.textMuted.withValues(alpha: 0.15)
                            : AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.availabilityStatusLabelFor(strings.language),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: job.isExpired ? AppColors.textMuted : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vXs,
                Text(
                  job.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                if (job.description != null && job.description!.isNotEmpty) ...[
                  AppSpacing.vSm,
                  Text(
                    job.description!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
                const Divider(height: 24),

                // Shift & Timing
                _buildRow(
                  icon: Icons.calendar_today_rounded,
                  label: isHindi ? 'तारीख व शिफ्ट' : 'Date & Shift',
                  value: '${job.shiftDate} • ${job.formattedShiftTime}',
                ),
                AppSpacing.vSm,

                // Quota
                _buildRow(
                  icon: Icons.people_outline_rounded,
                  label: isHindi ? 'आवश्यक कार्यकर्ता' : 'Workers Needed',
                  value: strings.workersNeeded(job.workersNeeded),
                ),
                AppSpacing.vSm,

                // Payment
                _buildRow(
                  icon: Icons.currency_rupee_rounded,
                  label: strings.perShiftLabel,
                  value: '₹${job.wageAmount.toStringAsFixed(0)} ${isHindi ? '/ प्रति शिफ्ट' : '/ Shift'}',
                  valueColor: AppColors.success,
                  isBold: true,
                ),
                if (job.paymentInstructions != null && job.paymentInstructions!.isNotEmpty) ...[
                  AppSpacing.vXs,
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      '${isHindi ? 'भुगतान नियम:' : 'Payment note:'} ${job.paymentInstructions}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
                AppSpacing.vSm,

                // Reporting Venue & Address
                _buildRow(
                  icon: Icons.location_on_outlined,
                  label: isHindi ? 'रिपोर्टिंग स्थल व पता' : 'Reporting Venue & Address',
                  value: '${job.venueName != null && job.venueName!.isNotEmpty ? '${job.venueName}, ' : ''}${job.reportingAddress}, ${job.locality}, ${job.city} (${job.pincode})',
                ),
              ],
            ),
          ),
          AppSpacing.vMd,

          // Required Skills
          if (job.skills.isNotEmpty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.skillsSection,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  AppSpacing.vSm,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.skills.map((s) {
                      return Chip(
                        label: Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            AppSpacing.vMd,
          ],

          // Perks & Requirements
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'सुविधाएं व निर्देश' : 'Perks & Instructions',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                AppSpacing.vSm,
                _buildRow(
                  icon: Icons.restaurant_rounded,
                  label: isHindi ? 'भोजन सुविधा' : 'Food Provided',
                  value: job.foodProvided
                      ? (isHindi
                          ? 'हाँ ${job.foodDetails != null && job.foodDetails!.isNotEmpty ? '(${job.foodDetails})' : ''}'
                          : 'Yes ${job.foodDetails != null && job.foodDetails!.isNotEmpty ? '(${job.foodDetails})' : ''}')
                      : (isHindi ? 'नहीं' : 'No'),
                ),
                AppSpacing.vSm,
                _buildRow(
                  icon: Icons.directions_bus_outlined,
                  label: isHindi ? 'वाहन सुविधा' : 'Transport Provided',
                  value: job.transportProvided
                      ? (isHindi
                          ? 'हाँ ${job.transportDetails != null && job.transportDetails!.isNotEmpty ? '(${job.transportDetails})' : ''}'
                          : 'Yes ${job.transportDetails != null && job.transportDetails!.isNotEmpty ? '(${job.transportDetails})' : ''}')
                      : (isHindi ? 'नहीं' : 'No'),
                ),
                if (job.specialInstructions != null && job.specialInstructions!.isNotEmpty) ...[
                  AppSpacing.vSm,
                  _buildRow(
                    icon: Icons.info_outline_rounded,
                    label: isHindi ? 'विशेष निर्देश / ड्रेस कोड' : 'Special Instructions / Dress Code',
                    value: job.specialInstructions!,
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.vXl,
        ],
      ),
    );
  }

  Widget _buildAvailabilityStatusCard(JobModel job, AppStrings strings) {
    final isHindi = strings.language == AppLanguage.hindi;

    if (job.isExpired) {
      return AppCard(
        borderColor: AppColors.border,
        backgroundColor: AppColors.border.withValues(alpha: 0.2),
        child: Row(
          children: [
            const Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.shiftExpired,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isHindi
                        ? 'इस कार्य की निर्धारित तिथि बीत चुकी है। अब नए आवेदन स्वीकार नहीं किए जा रहे हैं।'
                        : 'The date for this shift has passed. New applications are closed.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      borderColor: AppColors.success,
      backgroundColor: AppColors.success.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'सक्रिय व उपलब्ध शिफ्ट' : 'Active & Available Shift',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success),
                ),
                const SizedBox(height: 2),
                Text(
                  isHindi
                      ? 'यह शिफ्ट खुली है। कार्यकर्ता सीधे आवेदन कर सकते हैं।'
                      : 'This shift is open for application.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        AppSpacing.hSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
