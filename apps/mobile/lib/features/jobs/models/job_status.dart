import '../../../core/localization/app_language.dart';

enum JobStatus {
  draft,
  pendingAdminApproval,
  published,
  filled,
  inProgress,
  completed,
  cancelled,
  rejected;

  static JobStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'draft':
        return JobStatus.draft;
      case 'pending_admin_approval':
        return JobStatus.pendingAdminApproval;
      case 'published':
        return JobStatus.published;
      case 'filled':
        return JobStatus.filled;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      case 'cancelled':
        return JobStatus.cancelled;
      case 'rejected':
        return JobStatus.rejected;
      default:
        return JobStatus.draft;
    }
  }

  String get toDbValue {
    switch (this) {
      case JobStatus.draft:
        return 'draft';
      case JobStatus.pendingAdminApproval:
        return 'pending_admin_approval';
      case JobStatus.published:
        return 'published';
      case JobStatus.filled:
        return 'filled';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.cancelled:
        return 'cancelled';
      case JobStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName => displayNameFor(AppLanguage.english);

  String displayNameFor(AppLanguage language) {
    switch (this) {
      case JobStatus.draft:
        return switch (language) {
          AppLanguage.hindi => 'ड्राफ्ट',
          AppLanguage.hinglish => 'Draft',
          AppLanguage.english => 'Draft',
        };
      case JobStatus.pendingAdminApproval:
        return switch (language) {
          AppLanguage.hindi => 'समीक्षाधीन',
          AppLanguage.hinglish => 'Pending Review',
          AppLanguage.english => 'Pending Review',
        };
      case JobStatus.published:
        return switch (language) {
          AppLanguage.hindi => 'प्रकाशित',
          AppLanguage.hinglish => 'Live',
          AppLanguage.english => 'Live',
        };
      case JobStatus.filled:
        return switch (language) {
          AppLanguage.hindi => 'स्थान भरे',
          AppLanguage.hinglish => 'Filled',
          AppLanguage.english => 'Filled',
        };
      case JobStatus.inProgress:
        return switch (language) {
          AppLanguage.hindi => 'प्रगति पर',
          AppLanguage.hinglish => 'In Progress',
          AppLanguage.english => 'In Progress',
        };
      case JobStatus.completed:
        return switch (language) {
          AppLanguage.hindi => 'संपन्न',
          AppLanguage.hinglish => 'Completed',
          AppLanguage.english => 'Completed',
        };
      case JobStatus.cancelled:
        return switch (language) {
          AppLanguage.hindi => 'रद्द',
          AppLanguage.hinglish => 'Cancelled',
          AppLanguage.english => 'Cancelled',
        };
      case JobStatus.rejected:
        return switch (language) {
          AppLanguage.hindi => 'अस्वीकृत',
          AppLanguage.hinglish => 'Rejected',
          AppLanguage.english => 'Rejected',
        };
    }
  }

  String label([AppLanguage language = AppLanguage.english]) => displayNameFor(language);

  bool get isEditable =>
      this == JobStatus.draft ||
      this == JobStatus.rejected ||
      this == JobStatus.pendingAdminApproval ||
      this == JobStatus.published;

  bool get isCancellable =>
      this == JobStatus.draft ||
      this == JobStatus.pendingAdminApproval ||
      this == JobStatus.published;
}
