import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangKey = 'app_language';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('fr');

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, locale.languageCode);
  }

  Future<bool> isLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kLangKey);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
