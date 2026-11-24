import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/app_loaders.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/attendance_repository.dart';
import '../models/booking_model.dart';
import '../presentation/attendance_providers.dart';

class OwnerAttendanceRosterScreen extends ConsumerStatefulWidget {
  final String jobId;

  const OwnerAttendanceRosterScreen({super.key, required this.jobId});

  @override
  ConsumerState<OwnerAttendanceRosterScreen> createState() => _OwnerAttendanceRosterScreenState();
}

class _OwnerAttendanceRosterScreenState extends ConsumerState<OwnerAttendanceRosterScreen> {
  bool _isProcessing = false;

  void _markAttendance(String bookingId, String status, AppStrings strings) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(attendanceRepositoryProvider).markAttendance(
        bookingId: bookingId,
        status: status,
      );
      ref.invalidate(ownerJobRosterProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.attendanceStatusUpdated), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.errorPrefix}$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _completeWork(String bookingId, AppStrings strings) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(attendanceRepositoryProvider).completeWork(bookingId: bookingId);
      ref.invalidate(ownerJobRosterProvider(widget.jobId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.workCompletedMarked), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.errorPrefix}$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showManualCheckInDialog(String bookingId, String workerName, AppStrings strings) {
    final noteController = TextEditingController();
    final isHindi = strings.language == AppLanguage.hindi;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(strings.manualCheckInTitle(workerName), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.manualCheckInDesc,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            AppSpacing.vMd,
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: isHindi ? 'कारण / टिप्पणी*' : 'Reason / Note*',
                hintText: isHindi ? 'उदा. कार्यकर्ता समय पर उपस्थित, फोन डिस्चार्ज' : 'E.g., Worker present on time, phone dead',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isHindi ? 'कारण लिखना आवश्यक है।' : 'Please enter a reason.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(dialogCtx);
              setState(() => _isProcessing = true);
              try {
                await ref.read(attendanceRepositoryProvider).markAttendance(
                  bookingId: bookingId,
                  status: 'present',
                  notes: noteController.text.trim(),
                );
                ref.invalidate(ownerJobRosterProvider(widget.jobId));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.manualAttendanceRecorded), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${strings.errorPrefix}$e'), backgroundColor: AppColors.error),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: Text(strings.markPresentButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final rosterAsync = ref.watch(ownerJobRosterProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(strings.attendanceRosterTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: strings.refresh,
            onPressed: () => ref.invalidate(ownerJobRosterProvider(widget.jobId)),
          ),
        ],
      ),
      body: rosterAsync.when(
        data: (data) => _buildBody(context, data, strings),
        loading: () => Center(child: AppLoader(message: strings.loadingRoster)),
        error: (e, _) => Center(child: Text('${strings.errorPrefix}$e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JobAttendanceRosterModel data, AppStrings strings) {
    final m = data.metrics;
    final isHindi = strings.language == AppLanguage.hindi;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Header Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.jobTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                AppSpacing.vXs,
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${data.shiftDate} • ${data.startTime}${strings.toTime}${data.endTime}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.vMd,

          // Metrics Grid Summary
          Text(isHindi ? 'उपस्थिति सारांश' : 'Attendance Summary', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          AppSpacing.vSm,
          Row(
            children: [
              _buildMetricTile(strings.totalWorkersLabel, '${m.totalConfirmed}', AppColors.primary),
              AppSpacing.hSm,
              _buildMetricTile(strings.checkedInLabel, '${m.checkedIn}', Colors.blue),
              AppSpacing.hSm,
              _buildMetricTile(strings.presentLabel, '${m.present}', AppColors.success),
            ],
          ),
          AppSpacing.vSm,
          Row(
            children: [
              _buildMetricTile(AttendanceStatus.absent.displayNameFor(strings.language), '${m.absent}', AppColors.error),
              AppSpacing.hSm,
              _buildMetricTile(AttendanceStatus.noShow.displayNameFor(strings.language), '${m.noShow}', Colors.deepPurple),
              AppSpacing.hSm,
              _buildMetricTile(strings.completedLabel, '${m.completed}', Colors.teal),
            ],
          ),
          AppSpacing.vLg,

          // Workers Roster List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isHindi ? 'कार्यकर्ता सूची' : 'Confirmed Workers', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              Text(
                '${data.roster.length}/${data.workersNeeded} ${isHindi ? 'पुष्ट' : 'confirmed'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
          AppSpacing.vSm,

          if (data.roster.isEmpty) ...[
            AppCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: EmptyStateWidget(
                  icon: Icons.people_outline_rounded,
                  title: isHindi ? 'कोई पुष्ट कार्यकर्ता नहीं' : 'No confirmed workers',
                  description: isHindi
                      ? 'इस कार्य के लिए फिलहाल कोई कार्यकर्ता पुष्ट नहीं है।'
                      : 'No confirmed workers for this job shift yet.',
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.roster.length,
              separatorBuilder: (_, _) => AppSpacing.vMd,
              itemBuilder: (context, index) {
                final worker = data.roster[index];
                return _buildWorkerCard(context, worker, strings);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext context, RosterWorkerModel worker, AppStrings strings) {
    final isHindi = strings.language == AppLanguage.hindi;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: worker.selfieUrl != null ? NetworkImage(worker.selfieUrl!) : null,
                child: worker.selfieUrl == null
                    ? const Icon(Icons.person_rounded, color: AppColors.primary)
                    : null,
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.fullName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    if (worker.mobileNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        worker.mobileNumber!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: worker.attendanceStatus.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  worker.attendanceStatus.displayNameFor(strings.language),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: worker.attendanceStatus.color),
                ),
              ),
            ],
          ),
          if (worker.skills.isNotEmpty) ...[
            AppSpacing.vSm,
            Wrap(
              spacing: 6,
              children: worker.skills.map((s) {
                return Chip(
                  label: Text(s, style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppColors.background,
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          const Divider(height: 20),

          // Check-in and Completion Status Rows
          if (worker.checkInAt != null) ...[
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${isHindi ? 'चेक-इन समय:' : 'Check-in Time:'} ${worker.checkInAt!.hour.toString().padLeft(2, '0')}:${worker.checkInAt!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            AppSpacing.vXs,
          ],
          if (worker.notes != null) ...[
            Text('${isHindi ? 'टिप्पणी:' : 'Note:'} ${worker.notes}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            AppSpacing.vXs,
          ],

          // Attendance Management Actions
          if (!worker.isCompleted) ...[
            AppSpacing.vSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!worker.isPresent) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.white),
                    label: Text(strings.presentLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    onPressed: _isProcessing ? null : () => _markAttendance(worker.bookingId, 'present', strings),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14, color: AppColors.error),
                    label: Text(AttendanceStatus.absent.displayNameFor(strings.language), style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
                    onPressed: _isProcessing ? null : () => _markAttendance(worker.bookingId, 'absent', strings),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: Colors.deepPurple),
                    ),
                    onPressed: _isProcessing ? null : () => _markAttendance(worker.bookingId, 'no_show', strings),
                    child: Text(AttendanceStatus.noShow.displayNameFor(strings.language), style: const TextStyle(color: Colors.deepPurple, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
                if (worker.isPresent) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.task_alt_rounded, size: 14, color: Colors.white),
                    label: Text(strings.completeJobButton, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    onPressed: _isProcessing ? null : () => _completeWork(worker.bookingId, strings),
                  ),
                ],
                if (!worker.isCheckedIn && !worker.isPresent) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.edit_note_rounded, size: 14),
                    label: Text(strings.manualCheckInButton, style: const TextStyle(fontSize: 11)),
                    onPressed: () => _showManualCheckInDialog(worker.bookingId, worker.fullName, strings),
                  ),
                ],
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 16, color: Colors.teal),
                  const SizedBox(width: 6),
                  Text(
                    isHindi ? 'कार्य सफलतापूर्वक संपन्न हो चुका है।' : 'Work completed successfully.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.teal),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
