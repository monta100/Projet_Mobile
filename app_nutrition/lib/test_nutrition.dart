// ignore_for_file: avoid_print

import 'Services/nutrition_ai_service.dart';

void main() async {
  final service = NutritionAIService();
  final calories = await service.estimateCalories(
    "pasta with tomato sauce and cheese",
  );
  print("Calories estimées : $calories kcal");
}
