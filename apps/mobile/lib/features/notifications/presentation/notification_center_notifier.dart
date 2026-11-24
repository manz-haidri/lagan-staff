import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../models/notification_item_model.dart';

class NotificationCenterState {
  final bool isLoading;
  final List<NotificationItemModel> notifications;
  final int unreadCount;
  final bool unreadOnlyFilter;
  final String? errorMessage;

  const NotificationCenterState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.unreadOnlyFilter = false,
    this.errorMessage,
  });

  NotificationCenterState copyWith({
    bool? isLoading,
    List<NotificationItemModel>? notifications,
    int? unreadCount,
    bool? unreadOnlyFilter,
    String? errorMessage,
  }) {
    return NotificationCenterState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadOnlyFilter: unreadOnlyFilter ?? this.unreadOnlyFilter,
      errorMessage: errorMessage,
    );
  }
}

final notificationCenterProvider =
    NotifierProvider<NotificationCenterNotifier, NotificationCenterState>(
  NotificationCenterNotifier.new,
);

class NotificationCenterNotifier extends Notifier<NotificationCenterState> {
  @override
  NotificationCenterState build() {
    Future.microtask(() => loadNotifications());
    return const NotificationCenterState();
  }

  /// Load or refresh notifications
  Future<void> loadNotifications({bool? unreadOnly}) async {
    final filter = unreadOnly ?? state.unreadOnlyFilter;
    state = state.copyWith(isLoading: true, unreadOnlyFilter: filter, errorMessage: null);

    final repository = ref.read(notificationRepositoryProvider);
    try {
      final res = await repository.fetchNotifications(unreadOnly: filter);
      final items = res['notifications'] as List<NotificationItemModel>;
      final unread = res['unread_count'] as int;

      state = state.copyWith(
        isLoading: false,
        notifications: items,
        unreadCount: unread,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications: $e',
      );
    }
  }

  /// Toggle unread filter
  void setUnreadFilter(bool unreadOnly) {
    if (state.unreadOnlyFilter == unreadOnly) return;
    loadNotifications(unreadOnly: unreadOnly);
  }

  /// Mark single notification as read
  Future<void> markAsRead(String id) async {
    final updated = state.notifications.map((n) {
      if (n.id == id && !n.isRead) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }
      return n;
    }).toList();

    final newUnreadCount = (state.unreadCount - 1).clamp(0, 9999);
    state = state.copyWith(notifications: updated, unreadCount: newUnreadCount);

    final repository = ref.read(notificationRepositoryProvider);
    await repository.markAsRead(id);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final updated = state.notifications.map((n) {
      return n.copyWith(isRead: true, readAt: DateTime.now());
    }).toList();

    state = state.copyWith(notifications: updated, unreadCount: 0);
    final repository = ref.read(notificationRepositoryProvider);
    await repository.markAllAsRead();
  }
}
