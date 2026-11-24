import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/app_loaders.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/attendance_repository.dart';
import '../models/booking_model.dart';
import '../presentation/attendance_providers.dart';

class WorkerBookingsScreen extends ConsumerStatefulWidget {
  const WorkerBookingsScreen({super.key});

  @override
  ConsumerState<WorkerBookingsScreen> createState() => _WorkerBookingsScreenState();
}

class _WorkerBookingsScreenState extends ConsumerState<WorkerBookingsScreen> {
  bool _isProcessing = false;

  void _checkIn(String bookingId, AppStrings strings) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(attendanceRepositoryProvider).workerCheckIn(bookingId);
      ref.invalidate(workerBookingsProvider('upcoming'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.checkInSuccessMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.errorPrefix}$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showCancelDialog(String bookingId, String jobTitle, AppStrings strings) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(
          strings.cancelBookingDialogTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.cancelBookingConfirmQuestion(jobTitle),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            AppSpacing.vMd,
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: strings.cancelBookingReasonLabel,
                hintText: strings.cancelBookingReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(strings.back),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.cancelBookingReasonRequired),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(dlgCtx);
              setState(() => _isProcessing = true);
              try {
                await ref.read(attendanceRepositoryProvider).cancelBooking(
                  bookingId: bookingId,
                  reason: reasonController.text.trim(),
                );
                ref.invalidate(workerBookingsProvider('upcoming'));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.cancelBookingSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${strings.errorPrefix}$e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
            child: Text(
              strings.yesCancel,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final bookingsAsync = ref.watch(workerBookingsProvider('upcoming'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          strings.upcomingBookingsScreenTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          const LanguageSelectorButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: strings.refresh,
            onPressed: () => ref.invalidate(workerBookingsProvider('upcoming')),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: EmptyStateWidget(
                  icon: Icons.event_available_rounded,
                  title: strings.noUpcomingBookingsTitle,
                  description: strings.noUpcomingBookingsDesc,
                  actionLabel: strings.viewAvailableJobsAction,
                  onAction: () => context.push('/worker/jobs'),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(workerBookingsProvider('upcoming')),
            child: ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: bookings.length,
              separatorBuilder: (_, _) => AppSpacing.vMd,
              itemBuilder: (context, index) {
                final b = bookings[index];
                return _buildBookingCard(context, b, strings);
              },
            ),
          );
        },
        loading: () => Center(child: AppLoader(message: strings.loadingBookings)),
        error: (e, _) => Center(child: Text('${strings.errorPrefix}$e')),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel b, AppStrings strings) {
    final isEligible = b.isCheckInEligible(DateTime.now());

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                b.categoryName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              _buildAttendanceBadge(b, strings),
            ],
          ),
          AppSpacing.vXs,
          Text(
            b.jobTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          AppSpacing.vXs,
          Text(
            '${strings.hostLabel}${b.businessName}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 20),

          // Shift date & time
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${b.shiftDate} • ${b.startTime}${strings.toTime}${b.endTime}${b.isOvernight ? strings.nightShiftTag : ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          AppSpacing.vXs,

          // Reporting Address
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${b.venueName != null ? '${b.venueName}, ' : ''}${b.reportingAddress}, ${b.locality}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          AppSpacing.vXs,

          // Agreed Wage
          Row(
            children: [
              const Icon(Icons.currency_rupee_rounded, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                strings.agreedWageLabel(b.agreedWage.toInt()),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
              ),
            ],
          ),
          AppSpacing.vSm,

          // Gate Duty Pass PIN Box
          if (b.checkinCode != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.dutyPassPinTitle,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
                      ),
                      Text(
                        strings.dutyPassGateInstruction,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  Text(
                    b.checkinCode!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            AppSpacing.vSm,
          ],

          // Actions: Check-in / Cancel
          if (!b.isCheckedIn && !b.isPresent && !b.isCompleted) ...[
            Row(
              children: [
                Expanded(
                  child: AppPrimaryButton(
                    label: _isProcessing
                        ? '...'
                        : (isEligible ? strings.checkInAtVenue : strings.checkInWindowWait),
                    icon: Icons.login_rounded,
                    onPressed: (_isProcessing || !isEligible) ? null : () => _checkIn(b.bookingId, strings),
                  ),
                ),
                AppSpacing.hSm,
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                  tooltip: strings.cancelBookingButton,
                  onPressed: _isProcessing ? null : () => _showCancelDialog(b.bookingId, b.jobTitle, strings),
                ),
              ],
            ),
          ] else if (b.isCheckedIn && !b.isPresent) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings.awaitingHostConfirmation,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceBadge(BookingModel b, AppStrings strings) {
    if (b.isCompleted) {
      return AppBadge.success(label: strings.statusCompleted);
    }
    if (b.isPresent) {
      return AppBadge.success(label: strings.statusPresent);
    }
    if (b.isCheckedIn) {
      return AppBadge.pending(label: strings.statusCheckedIn);
    }
    return AppBadge.neutral(label: strings.statusConfirmed);
  }
}
