// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Entites/repas.dart';
import '../Entites/recette.dart';
import '../Entites/ingredient.dart';
import 'repas_service.dart';
import 'recette_service.dart';
import 'ingredient_service.dart';

class OpenRouterService {
  // 🔑 Ta clé API OpenRouter
  final String apiKey =
      "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";

  // 🧠 Choix du modèle IA
  final String model = "openai/gpt-3.5-turbo";

  // Services SQLite
  final _repasService = RepasService();
  final _recetteService = RecetteService();
  final _ingredientService = IngredientService();

  /// 🚀 Envoie un message à l’IA et traite la réponse
  Future<String> processUserMessage(
    String message, {
    bool structured = false,
  }) async {
    final prompt =
        """
Tu es un assistant de nutrition intelligent.
Quand l’utilisateur te demande de créer un repas ou une recette, 
réponds UNIQUEMENT en JSON structuré selon le cas :

➡ Pour un repas :
{
  "type":"repas",
  "nom":"Déjeuner léger",
  "calories":650,
  "date":"2025-10-09",
  "type_repas":"Déjeuner"
}

➡ Pour une recette :
{
  "type":"recette",
  "nom":"Salade tunisienne",
  "description":"Salade légère à base de tomates, œufs et thon",
  "calories":250,
  "ingredients":[
    {"nom":"Tomate","quantite":2,"unite":"pièce","calories":40},
    {"nom":"Thon","quantite":80,"unite":"g","calories":100}
  ]
}

Sinon, réponds simplement par du texte normal (conseils nutrition, motivation...).

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
        {
          "role": "system",
          "content": structured
              ? "Réponds en JSON strictement valide quand c'est possible."
              : "Tu es un assistant expert en nutrition.",
        },
        {"role": "user", "content": prompt},
      ],
      "temperature": 0.7,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode != 200) {
        print("Erreur IA ${response.statusCode}: ${response.body}");
        return "Erreur lors de la génération.";
      }

      final data = jsonDecode(response.body);
      final content = data["choices"][0]["message"]["content"] ?? "";
      print("Réponse IA brute: $content");

      // Essaie d’extraire un JSON valide
      final start = content.indexOf("{");
      final end = content.lastIndexOf("}");
      if (start != -1 && end != -1 && end > start) {
        final jsonPart = content.substring(start, end + 1);
        try {
          final Map<String, dynamic> parsed = jsonDecode(jsonPart);
          return await _handleStructuredResponse(parsed);
        } catch (e) {
          print("Erreur JSON parsing: $e");
        }
      }

      // Sinon, simple texte
      return content;
    } catch (e) {
      print("Exception OpenRouter: $e");
      return "Erreur de connexion à l’IA.";
    }
  }

  /// 💾 Interprète la réponse JSON et enregistre dans SQLite
  Future<String> _handleStructuredResponse(Map<String, dynamic> json) async {
    final type = json["type"]?.toString().toLowerCase();

    if (type == "repas") {
      final repas = Repas(
        type: json["type_repas"] ?? "Repas",
        date: DateTime.parse(json["date"] ?? DateTime.now().toIso8601String()),
        caloriesTotales: (json["calories"] ?? 0).toDouble(),
        nom: json["nom"] ?? "Repas sans nom",
        utilisateurId: 1,
      );
      await _repasService.insertRepas(repas);
      return "🍽️ Repas enregistré : ${repas.nom} (${repas.caloriesTotales} kcal)";
    }

    if (type == "recette") {
      final recette = Recette(
        nom: json["nom"] ?? "Recette sans nom",
        description: json["description"] ?? "",
        calories: (json["calories"] ?? 0).toDouble(),
        publie: 1,
        imageUrl: null,
        utilisateurId: 1,
      );
      final recetteId = await _recetteService.insertRecette(recette);

      // Ajout des ingrédients s’ils existent
      if (json["ingredients"] != null && json["ingredients"] is List) {
        for (final ing in json["ingredients"]) {
          final ingredient = Ingredient(
            nom: ing["nom"],
            quantite: (ing["quantite"] ?? 0).toDouble(),
            unite: ing["unite"] ?? "",
            calories: (ing["calories"] ?? 0).toDouble(),
            recetteId: recetteId,
          );
          await _ingredientService.insertIngredient(ingredient);
        }
      }

      return "🥗 Recette enregistrée : ${recette.nom} (${recette.calories} kcal)";
    }

    return "Réponse non reconnue : ${json.toString()}";
  }
}
