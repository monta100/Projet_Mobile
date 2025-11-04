// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

/// ✅ Service IA pour générer automatiquement une image de recette
/// à partir de son nom ("Pizza" → photo de pizza).
/// Utilise l’API officielle Unsplash (avec clé d’accès).
class ImageAIService {
  static const _accessKey = 'XlGuylOmXX3V35ksVoBjCnqsw5P9Es_cXoyuFU19rOY';

  Future<String?> generateImage(String recipeName) async {
    try {
      final query = Uri.encodeComponent('$recipeName food dish');
      final url =
          'https://api.unsplash.com/photos/random?query=$query&client_id=$_accessKey&orientation=squarish&count=1';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['urls'] != null) {
          // ✅ On récupère la meilleure qualité disponible
          return data[0]['urls']['regular'] ??
              data[0]['urls']['small'] ??
              data[0]['urls']['thumb'];
        }
      } else {
        print('❌ Erreur Unsplash (${response.statusCode})');
      }
    } catch (e) {
      print('⚠️ Erreur API Unsplash: $e');
    }

    // 🔁 Fallback : image par défaut
    return 'https://img.freepik.com/free-vector/flat-design-food-background_23-2149134010.jpg';
  }
}
