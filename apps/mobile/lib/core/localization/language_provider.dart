import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';

const String _kLanguageStorageKey = 'laganstaff_selected_language';

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    _loadPersistedLanguage();
    return AppLanguage.english; // Default is English per user requirement
  }

  Future<void> _loadPersistedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_kLanguageStorageKey);
      if (savedCode != null) {
        state = AppLanguage.fromCode(savedCode);
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguageStorageKey, language.code);
    } catch (_) {}
  }
}

final appLanguageProvider =
    NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return AppStrings(lang);
});

