// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../Entites/repas.dart';
import '../Entites/recette.dart';
import '../Entites/ingredient.dart';
import 'repas_service.dart';
import 'recette_service.dart';
import 'ingredient_service.dart';

class OpenRouterService {
  // 🔒 Clé API chargée depuis les variables d'environnement
  String get apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  final String model = "openai/gpt-3.5-turbo";

  final _repasService = RepasService();
  final _recetteService = RecetteService();
  final _ingredientService = IngredientService();

  /// 🚀 Envoie le message a l IA et traite la reponse
  Future<String> processUserMessage(
    String message, {
    bool structured = false,
  }) async {
    final prompt =
        """
Tu es un assistant de nutrition simple et clair.
Quand l utilisateur te demande de creer un repas ou une recette,
reponds uniquement en JSON si possible selon ces formats:

Pour un repas:
{
  "type":"repas",
  "nom":"Dejeuner leger",
  "calories":650,
  "date":"2025-10-09",
  "type_repas":"Dejeuner"
}

Pour une recette:
{
  "type":"recette",
  "nom":"Salade tunisienne",
  "description":"Salade legere a base de tomates, oeufs et thon",
  "calories":250,
  "ingredients":[
    {"nom":"Tomate","quantite":2,"unite":"piece","calories":40},
    {"nom":"Thon","quantite":80,"unite":"g","calories":100}
  ]
}

Sinon, donne une reponse texte naturelle et conviviale.

Message utilisateur: "$message"
""";

    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    final body = jsonEncode({
      "model": model,
      "messages": [
        {"role": "system", "content": "Tu es un assistant expert en nutrition"},
        {"role": "user", "content": prompt},
      ],
      "temperature": structured ? 0.5 : 0.8,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 200) {
        print("Erreur IA ${response.statusCode}: ${response.body}");
        return "Erreur IA lors de la generation";
      }

      final data = jsonDecode(response.body);
      String content = data["choices"][0]["message"]["content"] ?? "";

      // Nettoyage du contenu pour eviter les phrases parasites
      content = content
          .replaceAll("Désolé", "")
          .replaceAll("Je ne peux pas", "")
          .replaceAll("je ne peux pas", "")
          .replaceAll(":", "")
          .trim();

      print("Reponse IA brute nettoyee: $content");

      // Extraction JSON
      final start = content.indexOf("{");
      final end = content.lastIndexOf("}");
      if (start != -1 && end != -1 && end > start) {
        var jsonPart = content.substring(start, end + 1);
        
        // 🔧 Correction du JSON malformé : ajouter les ":" manquants
        // Remplace "key""value" par "key": "value"
        jsonPart = jsonPart.replaceAllMapped(
          RegExp(r'"([^"]+)"\s*"'),
          (match) => '"${match.group(1)}": "',
        );
        
        // Remplace "key"[ par "key": [
        jsonPart = jsonPart.replaceAllMapped(
          RegExp(r'"([^"]+)"\s*\['),
          (match) => '"${match.group(1)}": [',
        );
        
        // Remplace "key"{ par "key": {
        jsonPart = jsonPart.replaceAllMapped(
          RegExp(r'"([^"]+)"\s*\{'),
          (match) => '"${match.group(1)}": {',
        );
        
        // Remplace "key"123 par "key": 123 (nombres)
        jsonPart = jsonPart.replaceAllMapped(
          RegExp(r'"([^"]+)"\s*(\d+)'),
          (match) => '"${match.group(1)}": ${match.group(2)}',
        );
        
        print("JSON après correction: $jsonPart");
        
        try {
          final Map<String, dynamic> parsed = jsonDecode(jsonPart);
          return await _handleStructuredResponse(parsed);
        } catch (e) {
          print("Erreur JSON parsing: $e");
          print("JSON qui a échoué: $jsonPart");
        }
      }

      // Si pas de JSON → texte normal
      return content;
    } catch (e) {
      print("Exception OpenRouter: $e");
      return "Erreur de connexion a l IA";
    }
  }

  /// 💾 Traite les reponses structurees et enregistre dans SQLite
  Future<String> _handleStructuredResponse(Map<String, dynamic> json) async {
    final type = json["type"]?.toString().toLowerCase();

    // --- Cas d un repas ---
    if (type == "repas") {
      final repas = Repas(
        type: json["type_repas"] ?? "Repas",
        date: DateTime.tryParse(json["date"] ?? "") ?? DateTime.now(),
        caloriesTotales: (json["calories"] != null)
            ? json["calories"].toDouble()
            : 500.0,
        nom: json["nom"] ?? "Repas sans nom",
        utilisateurId: 1,
      );

      await _repasService.insertRepas(repas);
      return "Repas ajoute: ${repas.nom} (${repas.caloriesTotales} kcal)";
    }

    // --- Cas d une recette ---
    if (type == "recette") {
      final recette = Recette(
        nom: json["nom"] ?? "Recette sans nom",
        description: json["description"] ?? "",
        calories: (json["calories"] != null)
            ? json["calories"].toDouble()
            : 500.0,
        publie: 1,
        imageUrl: null,
        utilisateurId: 1,
      );

      final recetteId = await _recetteService.insertRecette(recette);

      // Ajout des ingredients
      if (json["ingredients"] != null && json["ingredients"] is List) {
        for (final ing in json["ingredients"]) {
          final ingredient = Ingredient(
            nom: ing["nom"] ?? "Ingredient",
            quantite: (ing["quantite"] ?? 0).toDouble(),
            unite: ing["unite"] ?? "",
            calories: (ing["calories"] ?? 0).toDouble(),
            recetteId: recetteId,
          );
          await _ingredientService.insertIngredient(ingredient);
        }
      }

      return "Recette ajoutee: ${recette.nom} (${recette.calories} kcal)";
    }

    return "Reponse non reconnue: ${json.toString()}";
  }
}
