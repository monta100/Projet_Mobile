import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../journal/models/health_record.dart';
import '../../journal/data/journal_repository.dart';
import '../../modules/profile/profile_page.dart'; // for height/weight providers

class AiTip {
  final String title;
  final String body;
  final String category; // ex: Sommeil, Glycémie, Tension…
  final int priority; // 1=info, 2=à surveiller, 3=important
  AiTip(this.title, this.body, this.category, this.priority);
}
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(); // or however you instantiate your repository
});
final aiDoctorProvider = FutureProvider.autoDispose<List<AiTip>>((ref) async {
  // get latest records from DB
  final repo = ref.read(journalRepositoryProvider);
  final records = await repo.fetchAll();

  // optional: user profile for BMI
  final heightCm = ref.read(heightProvider); // from profile_page.dart
  final weightKg = ref.read(weightProvider);
  final bmi = (heightCm > 0) ? weightKg / pow(heightCm / 100.0, 2) : null;

  return AiDoctor.analyze(records, bmi: bmi);
});

class AiDoctor {
  static List<AiTip> analyze(List<HealthRecord> records, {double? bmi}) {
    final tips = <AiTip>[];

    // group helpers
    T? lastValue<T extends num>(HealthMetricType type, String key) {
      for (final r in records.reversed) {
        if (r.type == type && r.values.containsKey(key)) {
          return r.values[key] as T;
        }
      }
      return null;
    }

    // --- TENSION ARTERIELLE ---
    final sys = lastValue<num>(HealthMetricType.bloodPressure, 'systolic');
    final dia = lastValue<num>(HealthMetricType.bloodPressure, 'diastolic');
    if (sys != null && dia != null) {
      if (sys >= 140 || dia >= 90) {
        tips.add(AiTip(
          'Tension élevée',
          "Votre dernière mesure est ${sys.toStringAsFixed(0)}/${dia.toStringAsFixed(0)} mmHg.\n"
          "• Limitez le sel, priorisez fruits/légumes.\n"
          "• 30 min d’activité modérée/jour.\n"
          "• Hydratez-vous régulièrement.\n"
          "• Si >140/90 de façon répétée, consultez.",
          'Tension', 3));
      } else if (sys >= 130 || dia >= 85) {
        tips.add(AiTip(
          'Tension à surveiller',
          "Mesure récente: ${sys.toStringAsFixed(0)}/${dia.toStringAsFixed(0)} mmHg.\n"
          "• Réduisez aliments ultra-transformés.\n"
          "• 150 min d’activité/semaine.\n"
          "• Re-mesurez 3x cette semaine (matin/soir).",
          'Tension', 2));
      } else {
        tips.add(AiTip(
          'Bonne tension',
          "Votre tension est dans la norme.\n"
          "• Gardez vos habitudes d’activité et d’hydratation.\n"
          "• Contrôlez 1×/semaine.",
          'Tension', 1));
      }
    }

    // --- GLYCÉMIE (à jeun, repère général) ---
    final glu = lastValue<num>(HealthMetricType.glucose, 'value');
    if (glu != null) {
      if (glu >= 126) {
        tips.add(AiTip(
          'Glycémie élevée à jeun',
          "Dernière valeur: ${glu.toStringAsFixed(0)} mg/dL.\n"
          "• Priorisez fibres (légumes, légumineuses), évitez sucres rapides.\n"
          "• Marchez 10–15 min après les repas.\n"
          "• Consultez si valeurs élevées répétées.",
          'Glycémie', 3));
      } else if (glu >= 100) {
        tips.add(AiTip(
          'Glycémie à surveiller',
          "Dernière valeur: ${glu.toStringAsFixed(0)} mg/dL.\n"
          "• Fractionnez les glucides dans la journée.\n"
          "• Ajoutez protéines au petit-déjeuner.\n"
          "• Suivi 2–3×/semaine.",
          'Glycémie', 2));
      } else {
        tips.add(AiTip(
          'Bonne stabilité glycémique',
          "Valeur dans la plage normale.\n"
          "• Continuez fibres, protéines, marche post-repas.",
          'Glycémie', 1));
      }
    }

    // --- SOMMEIL ---
    final sleepH = lastValue<num>(HealthMetricType.sleep, 'hours');
    if (sleepH != null) {
      if (sleepH < 6) {
        tips.add(AiTip(
          'Sommeil insuffisant',
          "Dernière nuit: ${sleepH.toStringAsFixed(1)} h.\n"
          "• Couchez-vous à heure fixe, limitez écrans 60 min avant.\n"
          "• Évitez caféine après 16h.\n"
          "• Objectif: 7–9 h.",
          'Sommeil', 3));
      } else if (sleepH < 7) {
        tips.add(AiTip(
          'Sommeil à améliorer',
          "Dernière nuit: ${sleepH.toStringAsFixed(1)} h.\n"
          "• Routine calme, pièce sombre/fraîche.\n"
          "• Essayez d’augmenter de +30 min.",
          'Sommeil', 2));
      } else {
        tips.add(AiTip(
          'Bon sommeil',
          "Sommeil adéquat, continuez vos habitudes.\n"
          "• Stabilisez l’horaire d’endormissement.",
          'Sommeil', 1));
      }
    }

    // --- POIDS / BMI ---
    if (bmi != null && bmi.isFinite) {
      if (bmi >= 30) {
        tips.add(AiTip(
          'Priorité perte de poids',
          "IMC ≈ ${bmi.toStringAsFixed(1)}.\n"
          "• Déficit léger: -300 à -500 kcal/j.\n"
          "• 150–300 min d’activité/semaine + renfo 2×.\n"
          "• Suivi hebdo poids + tour de taille.",
          'Poids', 3));
      } else if (bmi >= 25) {
        tips.add(AiTip(
          'Surpoids modéré',
          "IMC ≈ ${bmi.toStringAsFixed(1)}.\n"
          "• Réduisez boissons sucrées, +légumes, +protéines.\n"
          "• 8–10k pas/jour.",
          'Poids', 2));
      } else if (bmi < 18.5) {
        tips.add(AiTip(
          'IMC bas',
          "IMC ≈ ${bmi.toStringAsFixed(1)}.\n"
          "• Augmentez apports protéiques & caloriques de qualité.\n"
          "• Consultez si fatigue/perte d’appétit.",
          'Poids', 2));
      } else {
        tips.add(AiTip(
          'IMC normal',
          "IMC ≈ ${bmi.toStringAsFixed(1)}.\n"
          "• Maintenez équilibre: protéines, fibres, hydratation.",
          'Poids', 1));
      }
    }

    // --- FRÉQUENCE CARDIAQUE AU REPOS ---
    final hr = lastValue<num>(HealthMetricType.heartRate, 'value');
    if (hr != null) {
      if (hr > 90) {
        tips.add(AiTip(
          'Fréquence cardiaque élevée au repos',
          "Dernière valeur: ${hr.toStringAsFixed(0)} bpm.\n"
          "• Respiration 4-7-8, marche douce quotidienne.\n"
          "• Vérifiez caféine/stress/sommeil.",
          'Cardio', 2));
      } else if (hr < 50) {
        tips.add(AiTip(
          'Fréquence cardiaque basse',
          "Dernière valeur: ${hr.toStringAsFixed(0)} bpm.\n"
          "• OK chez sportifs. Si vertiges/fatigue → avis médical.",
          'Cardio', 1));
      } else {
        tips.add(AiTip(
          'Rythme au repos normal',
          "Poursuivez activité régulière et bonne hygiène de vie.",
          'Cardio', 1));
      }
    }

    // tri par priorité desc (3→1)
    tips.sort((a, b) => b.priority.compareTo(a.priority));
    return tips;
  }
}
