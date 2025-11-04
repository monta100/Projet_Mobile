import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const _keyLangCode = 'language_code';
  static const _keyCountryCode = 'country_code';

  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_keyLangCode);
    if (lang == null || lang.isEmpty) return null;
    final country = prefs.getString(_keyCountryCode);
    return Locale(lang, (country == null || country.isEmpty) ? null : country);
  }

  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLangCode, locale.languageCode);
    await prefs.setString(_keyCountryCode, locale.countryCode ?? '');
  }
}
