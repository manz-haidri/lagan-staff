import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/localization/language_selector_widget.dart';
import '../presentation/notification_preferences_notifier.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final state = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final isHindi = strings.language == AppLanguage.hindi;

    ref.listen<NotificationPreferencesState>(notificationPreferencesProvider,
        (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          strings.notificationPreferencesTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Guidance Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tune_outlined,
                              color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi
                                      ? 'पुश सूचना नियंत्रण'
                                      : 'Push Notification Controls',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isHindi
                                      ? 'चुनें कि आपको किन घटनाओं की सूचनाएं इस फोन पर मिलनी चाहिए। सेटिंग्स तुरंत अपडेट होती हैं।'
                                      : 'Choose which event notifications to receive on this device. Updates sync immediately.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Category Toggles
                    Text(
                      isHindi ? 'सूचना श्रेणियां' : 'Notification Channels',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 1. New Job Alerts
                    _buildPreferenceTile(
                      icon: Icons.work_outline,
                      iconColor: AppColors.accent,
                      title: isHindi
                          ? 'नए कार्य की सूचनाएं'
                          : 'New Job Alerts',
                      subtitle: isHindi
                          ? 'जब आपकी कार्य श्रेणी या कौशल से संबंधित नया कार्य पोस्ट किया जाए।'
                          : 'When new shifts matching your skills are posted.',
                      value: state.preferences.newJobAlerts,
                      onChanged: (val) => notifier.toggleNewJobAlerts(val),
                    ),
                    const SizedBox(height: 12),

                    // 2. Application Updates
                    _buildPreferenceTile(
                      icon: Icons.assignment_ind_outlined,
                      iconColor: AppColors.primary,
                      title: isHindi
                          ? 'आवेदन अपडेट्स'
                          : 'Application Updates',
                      subtitle: isHindi
                          ? 'कार्यकर्ता आवेदन प्राप्त होने, स्वीकृत होने या अस्वीकृत होने पर सूचना।'
                          : 'Notifications when job applications are received or updated.',
                      value: state.preferences.applicationUpdates,
                      onChanged: (val) => notifier.toggleApplicationUpdates(val),
                    ),
                    const SizedBox(height: 12),

                    // 3. Booking Updates
                    _buildPreferenceTile(
                      icon: Icons.event_available_outlined,
                      iconColor: AppColors.success,
                      title: isHindi
                          ? 'बुकिंग एवं शिफ्ट सूचना'
                          : 'Booking Updates',
                      subtitle: isHindi
                          ? 'शिफ्ट की पुष्टि, बुकिंग निरस्तीकरण या स्थल परिवर्तन पर तत्काल अलर्ट।'
                          : 'Instant alerts for shift confirmations, cancellations, or venue changes.',
                      value: state.preferences.bookingUpdates,
                      onChanged: (val) => notifier.toggleBookingUpdates(val),
                    ),
                    const SizedBox(height: 12),

                    // 4. Shift Reminders
                    _buildPreferenceTile(
                      icon: Icons.alarm,
                      iconColor: const Color(0xFFD97706),
                      title: isHindi
                          ? 'ड्यूटी रिमाइंडर'
                          : 'Shift Reminders',
                      subtitle: isHindi
                          ? 'इवेंट/विवाह स्थल पर ड्यूटी शुरू होने से 24 घंटे और 2 घंटे पहले स्मरण।'
                          : 'Reminders 24 hours and 2 hours before the shift begins.',
                      value: state.preferences.shiftReminders,
                      onChanged: (val) => notifier.toggleShiftReminders(val),
                    ),

                    const SizedBox(height: 28),

                    // Important Security/System Note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFFB45309), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isHindi
                                  ? 'नोट: खाते की सुरक्षा, सत्यापन स्थिति एवं व्यवस्थापक संबंधी आपातकालीन अलर्ट कभी भी बंद नहीं किए जा सकते।'
                                  : 'Note: Account security and emergency administrative alerts cannot be disabled.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF92400E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (state.isSaving)
                  Container(
                    color: Colors.black.withValues(alpha: 0.15),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
