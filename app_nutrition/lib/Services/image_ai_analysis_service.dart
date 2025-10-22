// Fonction top-level pour compute()
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🔧 Classe pour passer les paramètres à l'isolate
class ImageAnalysisParams {
  final String imagePath;
  final String apiKey;

  ImageAnalysisParams({required this.imagePath, required this.apiKey});
}

// Fonction top-level pour compute() - reçoit la clé API en paramètre
Future<String> analyzeImageInIsolate(ImageAnalysisParams params) async {
  final file = File(params.imagePath);
  return await ImageAIAnalysisService.analyzeImageWithKey(file, params.apiKey);
}

class ImageAIAnalysisService {
  // 🔒 Clé API chargée depuis les variables d'environnement
  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Méthode instance qui utilise la clé depuis dotenv
  Future<String> analyzeImage(File imageFile) async {
    return analyzeImageWithKey(imageFile, apiKey);
  }

  // Méthode statique qui reçoit la clé en paramètre (pour les isolates)
  static Future<String> analyzeImageWithKey(File imageFile, String apiKey) async {
    if (apiKey.isEmpty) {
      return "❌ Clé API Gemini manquante. Vérifiez votre fichier .env";
    }

    try {
      // 🤖 Utilise gemini-2.0-flash-exp (modèle expérimental le plus récent)
      final model = GenerativeModel(model: 'gemini-2.0-flash-exp', apiKey: apiKey);

      final prompt = TextPart(
        "Analyse cette image. Décris les aliments ou ingrédients visibles, "
        "puis estime les calories approximatives. "
        "Réponds en une phrase naturelle, conviviale et claire — exemple : "
        "'Je vois du riz et du poulet, environ 600 kcal.'",
      );

      final imageBytes = await imageFile.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      return response.text ?? "Aucune réponse détectée.";
      
    } catch (e) {
      print("❌ Erreur analyse image : $e");
      
      final errorString = e.toString();
      
      // Messages d'erreur clairs selon le type d'erreur
      if (errorString.contains('503') || errorString.contains('overloaded')) {
        return "⚠️ Le serveur Gemini AI est temporairement surchargé. "
               "Veuillez réessayer dans quelques minutes.";
      }
      
      if (errorString.contains('429') || errorString.contains('quota')) {
        return "⚠️ Quota API dépassé. Attendez quelques minutes ou vérifiez votre clé API.";
      }
      
      if (errorString.contains('401') || errorString.contains('403') || 
          errorString.contains('API key')) {
        return "❌ Clé API invalide. Vérifiez votre clé Gemini dans le fichier .env";
      }
      
      return "Erreur lors de l'analyse de l'image.";
    }
  }
}
