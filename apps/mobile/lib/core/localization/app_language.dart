enum AppLanguage {
  english(
    code: 'en',
    label: 'English',
    nativeLabel: 'English',
    badge: 'EN',
  ),
  hindi(
    code: 'hi',
    label: 'Hindi',
    nativeLabel: 'हिन्दी',
    badge: 'हि',
  ),
  hinglish(
    code: 'hinglish',
    label: 'Hinglish',
    nativeLabel: 'Hinglish',
    badge: 'Hin',
  );

  final String code;
  final String label;
  final String nativeLabel;
  final String badge;

  const AppLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.badge,
  });

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'hi':
        return AppLanguage.hindi;
      case 'hinglish':
        return AppLanguage.hinglish;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }
}
