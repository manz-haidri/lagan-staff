import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../models/notification_preferences_model.dart';

class NotificationPreferencesState {
  final bool isLoading;
  final bool isSaving;
  final NotificationPreferencesModel preferences;
  final String? errorMessage;
  final String? successMessage;

  const NotificationPreferencesState({
    this.isLoading = false,
    this.isSaving = false,
    this.preferences = const NotificationPreferencesModel(),
    this.errorMessage,
    this.successMessage,
  });

  NotificationPreferencesState copyWith({
    bool? isLoading,
    bool? isSaving,
    NotificationPreferencesModel? preferences,
    String? errorMessage,
    String? successMessage,
  }) {
    return NotificationPreferencesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      preferences: preferences ?? this.preferences,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferencesState>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier extends Notifier<NotificationPreferencesState> {
  @override
  NotificationPreferencesState build() {
    Future.microtask(() => loadPreferences());
    return const NotificationPreferencesState();
  }

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final repository = ref.read(notificationRepositoryProvider);
    try {
      final prefs = await repository.fetchPreferences();
      state = state.copyWith(
        isLoading: false,
        preferences: prefs,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load preferences: $e',
      );
    }
  }

  Future<void> updatePreferences(NotificationPreferencesModel newPrefs) async {
    final oldPrefs = state.preferences;
    state = state.copyWith(
      preferences: newPrefs,
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );

    final repository = ref.read(notificationRepositoryProvider);
    try {
      final success = await repository.updatePreferences(newPrefs);
      if (success) {
        state = state.copyWith(
          isSaving: false,
          successMessage: 'सूचना प्राथमिकताएं सुरक्षित की गईं (Preferences updated)',
        );
      } else {
        // Rollback
        state = state.copyWith(
          preferences: oldPrefs,
          isSaving: false,
          errorMessage: 'Failed to save preferences. Reverted.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        preferences: oldPrefs,
        isSaving: false,
        errorMessage: 'Error saving preferences: $e',
      );
    }
  }

  Future<void> toggleNewJobAlerts(bool value) async {
    final updated = state.preferences.copyWith(newJobAlerts: value);
    await updatePreferences(updated);
  }

  Future<void> toggleApplicationUpdates(bool value) async {
    final updated = state.preferences.copyWith(applicationUpdates: value);
    await updatePreferences(updated);
  }

  Future<void> toggleBookingUpdates(bool value) async {
    final updated = state.preferences.copyWith(bookingUpdates: value);
    await updatePreferences(updated);
  }

  Future<void> toggleShiftReminders(bool value) async {
    final updated = state.preferences.copyWith(shiftReminders: value);
    await updatePreferences(updated);
  }
}
