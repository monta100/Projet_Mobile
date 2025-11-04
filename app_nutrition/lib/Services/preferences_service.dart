import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  /// 🕒 Sauvegarde le dernier repas (nom + heure)
  static Future<void> saveLastMeal(String mealName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastMealName', mealName);
    await prefs.setString('lastMealTime', DateTime.now().toIso8601String());
  }

  static Future<String?> getLastMealName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastMealName');
  }

  static Future<DateTime?> getLastMealTime() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('lastMealTime');
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// 🕒 Définit l'heure du dernier repas
  static Future<void> setLastMealTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastMealTime', time.toIso8601String());
  }

  /// 🍽️ Gère le nombre de repas par jour
  static Future<void> incrementMealCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    int count = prefs.getInt('mealCount') ?? 0;
    await prefs.setInt('mealCount', count + 1);
  }

  static Future<int> getMealCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    return prefs.getInt('mealCount') ?? 0;
  }

  /// 🍽️ Récupère le nombre de repas aujourd'hui
  static Future<int> getMealCountToday() async {
    return await getMealCount();
  }

  /// 😴 Enregistre et lit l’humeur
  static Future<void> saveMood(String mood) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userMood', mood);
  }

  static Future<String?> getMood() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userMood');
  }

  /// 😴 Récupère l'humeur de l'utilisateur
  static Future<String?> getUserMood() async {
    return await getMood();
  }

  /// ❤️ Enregistre les préférences alimentaires
  static Future<void> saveDiet(String diet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userDiet', diet);
  }

  static Future<String?> getDiet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userDiet');
  }

  /// 🔁 Réinitialise compteur chaque jour
  static Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final lastReset = prefs.getString('lastResetDate');
    if (lastReset != today) {
      await prefs.setInt('mealCount', 0);
      await prefs.setString('lastResetDate', today);
    }
  }

  /// 🔄 Réinitialise le compteur de repas si un nouveau jour commence
  static Future<void> resetMealCountIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
  }
}
