enum Sex { male, female }

class Metabolism {
  // Mifflin-St Jeor
  static double bmr({
    required Sex sex,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return sex == Sex.male ? base + 5 : base - 161;
  }

  static double tdee(double bmr, ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary: return bmr * 1.2;
      case ActivityLevel.light:     return bmr * 1.375;
      case ActivityLevel.moderate:  return bmr * 1.55;
      case ActivityLevel.active:    return bmr * 1.725;
      case ActivityLevel.veryActive:return bmr * 1.9;
    }
  }
}

enum ActivityLevel { sedentary, light, moderate, active, veryActive }
