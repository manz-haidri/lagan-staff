import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/notification_item_model.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../notification_route.dart';
import '../presentation/notification_center_notifier.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final unreadOnly = _tabController.index == 1;
        ref
            .read(notificationCenterProvider.notifier)
            .setUnreadFilter(unreadOnly);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationCenterProvider.notifier).loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime dateTime, AppStrings strings) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return strings.timeJustNow;
    } else if (difference.inMinutes < 60) {
      return strings.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return strings.timeHoursAgo(difference.inHours);
    } else if (difference.inDays == 1) {
      return strings.timeYesterday;
    } else if (difference.inDays < 7) {
      return strings.timeDaysAgo(difference.inDays);
    } else {
      return DateFormat('dd MMM, hh:mm a').format(dateTime);
    }
  }

  IconData _getEventIcon(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.newJob:
        return Icons.work_outline;
      case NotificationEventType.bookingConfirmed:
        return Icons.check_circle_outline;
      case NotificationEventType.shiftReminder:
        return Icons.alarm;
      case NotificationEventType.jobCancelled:
        return Icons.cancel_outlined;
      case NotificationEventType.applicationReceived:
        return Icons.assignment_ind_outlined;
      case NotificationEventType.applicationApproved:
        return Icons.verified_outlined;
      case NotificationEventType.applicationRejected:
        return Icons.block_outlined;
      case NotificationEventType.other:
        return Icons.notifications_none;
    }
  }

  Color _getIconColor(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.newJob:
        return AppColors.accent;
      case NotificationEventType.bookingConfirmed:
      case NotificationEventType.applicationApproved:
        return AppColors.success;
      case NotificationEventType.shiftReminder:
        return const Color(0xFFD97706);
      case NotificationEventType.jobCancelled:
      case NotificationEventType.applicationRejected:
        return AppColors.error;
      case NotificationEventType.applicationReceived:
        return AppColors.primary;
      case NotificationEventType.other:
        return AppColors.textSecondary;
    }
  }

  void _handleNotificationTap(NotificationItemModel item) {
    if (!item.isRead) {
      ref.read(notificationCenterProvider.notifier).markAsRead(item.id);
    }

    final route = notificationRoute(item.entityType, item.entityId,
        ref.read(authNotifierProvider).userProfile?.primaryRole,
        jobId: item.data['job_id']?.toString(), event: item.eventType.toDbString());
    if (route != '/notifications') context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final state = ref.watch(notificationCenterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          strings.notificationCenterTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          const LanguageSelectorButton(),
          IconButton(
            tooltip: strings.markAllAsReadTooltip,
            icon: const Icon(Icons.done_all, color: AppColors.primary),
            onPressed: state.unreadCount > 0
                ? () {
                    ref
                        .read(notificationCenterProvider.notifier)
                        .markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.allMarkedAsReadMessage),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
          ),
          IconButton(
            tooltip: strings.notificationSettingsTooltip,
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              context.push('/settings/notifications');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: strings.tabAll),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.tabUnread),
                  if (state.unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(notificationCenterProvider.notifier)
            .loadNotifications(),
        color: AppColors.primary,
        child: state.isLoading && state.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      EmptyStateWidget(
                        icon: Icons.notifications_off_outlined,
                        title: strings.noNotificationsTitle,
                        description: strings.noNotificationsDesc,
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: state.notifications.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final item = state.notifications[index];
                      return InkWell(
                        onTap: () => _handleNotificationTap(item),
                        child: Container(
                          color: item.isRead
                              ? Colors.transparent
                              : AppColors.primary.withValues(alpha: 0.04),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getIconColor(item.eventType)
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getEventIcon(item.eventType),
                                  color: _getIconColor(item.eventType),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: item.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatRelativeTime(item.createdAt, strings),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.body,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: item.isRead
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
