import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/app_loaders.dart';
import '../../data/job_repository.dart';
import '../../models/job_model.dart';
import '../../models/job_status.dart';
import '../../presentation/job_form_notifier.dart';
import '../../presentation/owner_jobs_notifier.dart';

class OwnerJobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const OwnerJobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<OwnerJobDetailScreen> createState() => _OwnerJobDetailScreenState();
}

class _OwnerJobDetailScreenState extends ConsumerState<OwnerJobDetailScreen> {
  bool _isCancelling = false;
  bool _isUpdating = false;

  void _showCancelDialog(BuildContext context, JobModel job) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('कार्य रद्द करें (Cancel Job)?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'क्या आप वाकई इस कार्य को रद्द करना चाहते हैं? रद्द करने के बाद यह कार्य कार्यकर्ताओं की सूची से तुरंत हटा दिया जाएगा।',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            AppSpacing.vMd,
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'रद्द करने का कारण (Reason)',
                hintText: 'उदा. कार्यक्रम स्थगित या तिथि परिवर्तित',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('वापस (No)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isCancelling = true);
              try {
                await ref.read(jobRepositoryProvider).cancelJob(
                  job.id,
                  reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                );
                ref.invalidate(jobDetailProvider(job.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('कार्य सफलतापूर्वक रद्द कर दिया गया।'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('त्रुटि: $e'), backgroundColor: AppColors.error),
                  );
                }
              } finally {
                if (mounted) setState(() => _isCancelling = false);
              }
            },
            child: const Text('हाँ, रद्द करें', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showUpdatePublishedDialog(BuildContext context, JobModel job) {
    final venueController = TextEditingController(text: job.venueName ?? '');
    final addressController = TextEditingController(text: job.reportingAddress);
    final localityController = TextEditingController(text: job.locality);
    final descController = TextEditingController(text: job.description ?? '');
    final instructionsController = TextEditingController(text: job.specialInstructions ?? '');
    final paymentController = TextEditingController(text: job.paymentInstructions ?? '');
    bool food = job.foodProvided;
    final foodDetailsController = TextEditingController(text: job.foodDetails ?? '');
    bool transport = job.transportProvided;
    final transportDetailsController = TextEditingController(text: job.transportDetails ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'प्रकाशित कार्य विवरण अपडेट करें',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const Text(
                  'लाइव कार्य के स्थल, पता व निर्देशों में सुरक्षित संशोधन करें। मानदेय व दिनांक बदलने हेतु नया कार्य पोस्ट करें।',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Divider(height: 24),

                TextField(
                  controller: venueController,
                  decoration: const InputDecoration(
                    labelText: 'स्थल / हॉल का नाम (Venue Name)',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.vSm,

                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'रिपोर्टिंग का पता (Reporting Address)*',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                AppSpacing.vSm,

                TextField(
                  controller: localityController,
                  decoration: const InputDecoration(
                    labelText: 'क्षेत्र / मुहल्ला (Locality)*',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.vSm,

                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'कार्य विवरण (Description)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                AppSpacing.vSm,

                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'विशेष निर्देश / ड्रेस कोड',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.vSm,

                TextField(
                  controller: paymentController,
                  decoration: const InputDecoration(
                    labelText: 'भुगतान निर्देश (Payment Instructions)',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.vSm,

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('भोजन सुविधा उपलब्ध', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: food,
                  onChanged: (v) => setSheetState(() => food = v),
                ),
                if (food) ...[
                  TextField(
                    controller: foodDetailsController,
                    decoration: const InputDecoration(
                      labelText: 'भोजन विवरण (उदा. दोपहर का भोजन व चाय)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  AppSpacing.vSm,
                ],

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('वाहन / पिकअप सुविधा', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: transport,
                  onChanged: (v) => setSheetState(() => transport = v),
                ),
                if (transport) ...[
                  TextField(
                    controller: transportDetailsController,
                    decoration: const InputDecoration(
                      labelText: 'वाहन विवरण (उदा. स्टेशन से पिकअप)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  AppSpacing.vSm,
                ],

                AppSpacing.vMd,
                AppPrimaryButton(
                  label: _isUpdating ? 'अपडेट हो रहा है...' : 'विवरण सुरक्षित करें (Save Updates)',
                  icon: Icons.check_circle_rounded,
                  onPressed: _isUpdating
                      ? null
                      : () async {
                          if (addressController.text.trim().isEmpty || localityController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('पता और क्षेत्र अनिवार्य हैं।'), backgroundColor: AppColors.error),
                            );
                            return;
                          }

                          Navigator.pop(sheetCtx);
                          setState(() => _isUpdating = true);

                          try {
                            await ref.read(jobRepositoryProvider).updatePublishedJob(
                              jobId: job.id,
                              venueName: venueController.text.trim().isEmpty ? null : venueController.text.trim(),
                              reportingAddress: addressController.text.trim(),
                              locality: localityController.text.trim(),
                              description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                              specialInstructions: instructionsController.text.trim().isEmpty ? null : instructionsController.text.trim(),
                              paymentInstructions: paymentController.text.trim().isEmpty ? null : paymentController.text.trim(),
                              foodProvided: food,
                              foodDetails: food && foodDetailsController.text.trim().isNotEmpty ? foodDetailsController.text.trim() : null,
                              transportProvided: transport,
                              transportDetails: transport && transportDetailsController.text.trim().isNotEmpty ? transportDetailsController.text.trim() : null,
                            );

                            ref.invalidate(jobDetailProvider(job.id));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('कार्य विवरण सफलतापूर्वक अपडेट कर दिया गया।'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('अपडेट विफल: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isUpdating = false);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.jobDetailsTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(jobDetailProvider(widget.jobId)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: jobAsync.when(
        data: (job) => _buildBody(context, job, strings),
        loading: () => Center(child: AppLoader(message: strings.loading)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JobModel job, AppStrings strings) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Notification Banner
          _buildStatusBanner(context, job),
          AppSpacing.vMd,

          // Main Job Overview Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.categoryName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    _buildStatusBadge(job, strings),
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
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
                const Divider(height: 24),

                // Shift & Timing
                _buildInfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'तारीख व शिफ्ट समय',
                  value: '${job.shiftDate} • ${job.formattedShiftTime}',
                ),
                AppSpacing.vSm,

                // Workers Quota
                _buildInfoRow(
                  icon: Icons.people_outline_rounded,
                  label: 'आवश्यक कार्यकर्ता',
                  value: '${job.workersNeeded} कार्यकर्ता आवश्यक (${job.workersConfirmed} पुष्ट)',
                ),
                AppSpacing.vSm,

                // Wage
                _buildInfoRow(
                  icon: Icons.currency_rupee_rounded,
                  label: 'मानदेय (Wage)',
                  value: job.formattedWage,
                  valueColor: AppColors.success,
                  isBold: true,
                ),
                if (job.paymentInstructions != null && job.paymentInstructions!.isNotEmpty) ...[
                  AppSpacing.vXs,
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      'भुगतान निर्देश: ${job.paymentInstructions}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
                AppSpacing.vSm,

                // Venue & Location
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'स्थल व पता',
                  value: '${job.venueName != null && job.venueName!.isNotEmpty ? '${job.venueName}, ' : ''}${job.reportingAddress}, ${job.locality}, ${job.city} (${job.pincode})',
                ),
              ],
            ),
          ),
          AppSpacing.vMd,

          // Required Skills Card
          if (job.skills.isNotEmpty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('आवश्यक हुनर / कौशल (Required Skills)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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

          // Perks & Requirements Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('सुविधाएं व निर्देश (Perks & Requirements)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                AppSpacing.vSm,
                _buildInfoRow(
                  icon: Icons.restaurant_rounded,
                  label: 'भोजन सुविधा',
                  value: job.foodProvided ? 'हाँ ${job.foodDetails != null ? '(${job.foodDetails})' : ''}' : 'नहीं',
                ),
                AppSpacing.vSm,
                _buildInfoRow(
                  icon: Icons.directions_bus_outlined,
                  label: 'वाहन सुविधा',
                  value: job.transportProvided ? 'हाँ ${job.transportDetails != null ? '(${job.transportDetails})' : ''}' : 'नहीं',
                ),
                if (job.specialInstructions != null && job.specialInstructions!.isNotEmpty) ...[
                  AppSpacing.vSm,
                  _buildInfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'विशेष निर्देश',
                    value: job.specialInstructions!,
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.vLg,

          // Action Buttons:
          // 0. Attendance Roster (Phase 7)
          if (job.status == JobStatus.published) ...[
            AppPrimaryButton(
              label: 'उपस्थिति रोस्टर देखें (Attendance Roster)',
              icon: Icons.how_to_reg_rounded,
              onPressed: () => context.push('/owner/attendance/${job.id}'),
            ),
            AppSpacing.vSm,
          ],

          // 1. For Published Jobs: Update Non-Critical Details
          if (job.status == JobStatus.published && !job.isExpired) ...[
            AppSecondaryButton(
              label: 'कार्य विवरण अपडेट करें (Update Details)',
              icon: Icons.edit_note_rounded,
              onPressed: () => _showUpdatePublishedDialog(context, job),
            ),
            AppSpacing.vSm,
          ],

          // 2. For Draft/Rejected: Full Wizard Edit
          if (job.status.isEditable) ...[
            AppSecondaryButton(
              label: 'कार्य संपादित करें (Edit Job)',
              icon: Icons.edit_note_rounded,
              onPressed: () {
                ref.read(jobFormNotifierProvider.notifier).loadExistingJob(job);
                context.push('/jobs/create');
              },
            ),
            AppSpacing.vSm,
          ],

          // 3. Cancel Job
          if (job.status.isCancellable) ...[
            AppSecondaryButton(
              label: _isCancelling ? 'रद्द हो रहा है...' : 'कार्य रद्द करें (Cancel Job)',
              icon: Icons.cancel_outlined,
              borderColor: AppColors.error,
              onPressed: _isCancelling ? null : () => _showCancelDialog(context, job),
            ),
            AppSpacing.vSm,
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, JobModel job) {
    if (job.status == JobStatus.pendingAdminApproval) {
      return AppCard(
        borderColor: AppColors.warning,
        backgroundColor: AppColors.warning.withValues(alpha: 0.08),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('प्रथम कार्य समीक्षाधीन है', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warning)),
                  SizedBox(height: 2),
                  Text('LaganStaff व्यवस्थापक द्वारा समीक्षा के बाद यह कार्य प्रकाशित किया जाएगा।', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (job.status == JobStatus.rejected) {
      return AppCard(
        borderColor: AppColors.error,
        backgroundColor: AppColors.error.withValues(alpha: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'कार्य अस्वीकृत: ${job.adminRejectionReason ?? 'विवरण अपूर्ण है।'}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error),
                  ),
                ),
              ],
            ),
            AppSpacing.vSm,
            AppPrimaryButton(
              label: 'सुधारें और पुनः सबमिट करें (Edit & Resubmit)',
              icon: Icons.edit_note_rounded,
              onPressed: () {
                ref.read(jobFormNotifierProvider.notifier).loadExistingJob(job);
                context.push('/jobs/create');
              },
            ),
          ],
        ),
      );
    }

    if (job.status == JobStatus.published) {
      if (job.isExpired) {
        return AppCard(
          borderColor: AppColors.border,
          backgroundColor: AppColors.border.withValues(alpha: 0.2),
          child: const Row(
            children: [
              Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('शिफ्ट तिथि समाप्त (Shift Expired)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    SizedBox(height: 2),
                    Text('इस कार्य की निर्धारित तिथि बीत चुकी है। यह कार्यकर्ताओं को उपलब्ध सूची में नहीं दिख रहा है।', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('कार्य लाइव है (Published)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                  SizedBox(height: 2),
                  Text('यह कार्य गाजीपुर के सभी सक्रिय कार्यकर्ताओं को दिख रहा है।', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (job.status == JobStatus.cancelled) {
      return AppCard(
        borderColor: AppColors.border,
        backgroundColor: AppColors.border.withValues(alpha: 0.3),
        child: Row(
          children: [
            const Icon(Icons.block_rounded, color: AppColors.textMuted, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('कार्य रद्द कर दिया गया है (Cancelled)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  if (job.cancellationReason != null)
                    Text('कारण: ${job.cancellationReason}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
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

  Widget _buildStatusBadge(JobModel job, AppStrings strings) {
    if (job.status == JobStatus.published && job.isExpired) {
      return AppBadge.neutral(label: strings.expiredStatus);
    }
    final label = job.status.displayNameFor(strings.language);
    switch (job.status) {
      case JobStatus.published:
        return AppBadge.success(label: label);
      case JobStatus.pendingAdminApproval:
        return AppBadge.pending(label: label);
      case JobStatus.draft:
        return AppBadge.neutral(label: label);
      case JobStatus.rejected:
        return AppBadge.error(label: label);
      case JobStatus.cancelled:
        return AppBadge.neutral(label: label);
      case JobStatus.filled:
        return AppBadge.success(label: label);
      case JobStatus.inProgress:
        return AppBadge.pending(label: label);
      case JobStatus.completed:
        return AppBadge.neutral(label: label);
    }
  }
}
