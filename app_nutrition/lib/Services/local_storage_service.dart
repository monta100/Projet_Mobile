import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _plansKey = 'saved_plans';

  Future<List<Map<String, dynamic>>> getSavedPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_plansKey) ?? <String>[];
    return rawList
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList(growable: false);
  }

  Future<void> addPlan(Map<String, dynamic> plan) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_plansKey) ?? <String>[];
    rawList.add(jsonEncode(plan));
    await prefs.setStringList(_plansKey, rawList);
  }

  Future<void> clearPlans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_plansKey);
  }
}


