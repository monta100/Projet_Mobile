// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
// Imports supprimés (persistance déléguée à NutriBotBrain)

class OpenRouterService {
  // 🔑 Ta clé API OpenRouter
  final String apiKey =
      "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";

  // 🧠 Choix du modèle IA
  final String model = "openai/gpt-3.5-turbo";

  // Plus de persistance directe ici; NutriBotBrain gère l'insertion après confirmation.

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

      // IMPORTANT: Ne pas insérer en base ici. On renvoie tel quel pour que
      // NutriBotBrain décide quand et comment parser/ajouter (confirmation requise).
      return content;
    } catch (e) {
      print("Exception OpenRouter: $e");
      return "Erreur de connexion à l’IA.";
    }
  }

  // Ancienne logique d'insertion directe supprimée : la persistance est gérée
  // par NutriBotBrain après confirmation de l'utilisateur.
}
