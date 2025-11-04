// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

class NutritionAIService {
  static const String _baseUrl = 'api.spoonacular.com';
  static const String _apiKey = '1f6fa3aff2334e7fb4254f735eb58d5b'; // 🔑 ta clé API

  /// Retourne le nombre de calories estimé pour un plat donné
  Future<double> estimateCalories(String dishName) async {
    if (dishName.trim().isEmpty) return 0;

    try {
      final uri = Uri.https(
        _baseUrl,
        '/recipes/guessNutrition',
        {
          'title': dishName,
          'apiKey': _apiKey,
        },
      );

      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['calories'] != null && data['calories']['value'] != null) {
          return (data['calories']['value'] as num).toDouble();
        }
      } else {
        print('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur NutritionAIService: $e');
    }

    // 🔁 Fallback local si API échoue
    return 0.0;
  }

  /// Si l’API ne répond pas, on renvoie une estimation locale
}
