// ignore_for_file: avoid_print

import 'dart:convert';
import '../Services/openrouter_service.dart';
import '../Services/repas_service.dart';
import '../Services/recette_service.dart';
import '../Entites/repas.dart';
import '../Entites/recette.dart';

class NutriBotBrain {
  final OpenRouterService _openRouter = OpenRouterService();
  final RepasService _repasService = RepasService();
  final RecetteService _recetteService = RecetteService();

  String? _lastIntent;
  String? _lastSuggestion;
  String? _lastRecipeDetails;
  double? _lastCalories;
  List<Map<String, dynamic>>? _lastIngredients;
  List<String> _mealOptions = [];

  Future<String> process(String userText) async {
    final text = _normalizeText(userText.toLowerCase().trim());

    // 👋 Salutation
    if (text.contains("bonjour") || text.contains("salut")) {
      return "👋 Salut ! Moi c est **Snacky 🍊**, ton coach nutrition et cuisine. Que veux tu faire aujourd hui ?";
    }

    // 🍽️ Ajout de repas existant
    if (text.contains("jai mange") ||
        text.contains("j ai mange") ||
        text.contains("jai pris") ||
        text.contains("j ai pris") ||
        text.contains("ajoute") ||
        text.contains("ajouter") ||
        text.contains("ajout")) {
      final typeRepas = _detectTypeRepas(text);
      final nomRepas = _extraireNomRepas(text);

      if (nomRepas.isNotEmpty) {
        final repas = Repas(
          type: typeRepas,
          date: DateTime.now(),
          nom: nomRepas,
          caloriesTotales: _estimerCalories(nomRepas),
          utilisateurId: 1,
        );
        await _repasService.insertRepas(repas);
        return "✅ Repas ajoute : **$nomRepas** dans *$typeRepas* (${repas.caloriesTotales} kcal)";
      } else {
        return "Je nai pas compris le plat 😅 Peux tu reformuler (ex : j ai mange une pizza a midi)";
      }
    }

    // 🍱 Suggestions de repas
    if ((text.contains("repas") ||
            text.contains("idee") ||
            text.contains("suggestion")) &&
        !(text.contains("jai") ||
            text.contains("mange") ||
            text.contains("ajoute"))) {
      _lastIntent = "repas";

      final idea = await _openRouter.processUserMessage(
        "Propose trois idees de repas equilibres petit dejeuner dejeuner diner avec calories",
        structured: true,
      );

      _mealOptions = _extraireRepasDepuisTexte(idea);
      return "Voici quelques idees 👇\n${_mealOptions.join("\n")}\nLequel veux tu que j ajoute ?";
    }

    // 👨‍🍳 Recherche de recette — affichage en paragraphe
    if (text.contains("recette") ||
        text.contains("preparer") ||
        text.contains("cuisine")) {
      _lastIntent = "recette";

      final response = await _openRouter.processUserMessage(
        "Cree une recette detaillee basee sur ${userText} au format JSON avec nom, description, calories et ingredients.",
        structured: true,
      );

      String jsonCandidate = response
          .replaceAll('""', '"')
          .replaceAll("”", '"')
          .replaceAll("“", '"')
          .trim();

      if (jsonCandidate.contains("{") && jsonCandidate.contains("}")) {
        try {
          final start = jsonCandidate.indexOf("{");
          final end = jsonCandidate.lastIndexOf("}");
          final jsonPart = jsonCandidate.substring(start, end + 1);

          final Map<String, dynamic> recetteJson = jsonDecode(jsonPart);

          final nom = recetteJson["nom"] ?? "Recette sans nom";
          final description =
              recetteJson["description"] ?? "Pas de description";
          final calories = (recetteJson["calories"] ?? 0).toDouble();
          final ingredients = List<Map<String, dynamic>>.from(
            recetteJson["ingredients"] ?? [],
          );

          // Sauvegarde temporaire pour ajout
          _lastSuggestion = nom;
          _lastRecipeDetails = description;
          _lastCalories = calories;
          _lastIngredients = ingredients;

          // Mise en forme paragraphe
          String ingredientsText = ingredients.isEmpty
              ? "Aucun ingrédient spécifié."
              : ingredients
                    .map(
                      (ing) =>
                          "- ${ing["nom"] ?? "?"} (${ing["quantite"] ?? "?"} ${ing["unite"] ?? ""} – ${ing["calories"] ?? 0} kcal)",
                    )
                    .join("\n");

          return "🥗 **$nom (${calories.toStringAsFixed(0)} kcal)**\n$description\n\n**Ingrédients :**\n$ingredientsText\n\nSouhaites tu que je l ajoute a ton carnet ?";
        } catch (e) {
          print("Erreur parsing JSON: $e");
        }
      }

      return "Voici une idee de recette : ${response.replaceAll(RegExp(r'[\{\}\[\]\"]'), '')}";
    }

    // 📖 Enregistrement ou ajout d'une recette
    if (_lastIntent == "recette" &&
        (text.contains("ajouter la") ||
            text.contains("ajoute la") ||
            text.contains("ajouter cette recette") ||
            text.contains("oui") ||
            text.contains("vas y"))) {
      if (_lastSuggestion != null) {
        final recette = Recette(
          nom: _lastSuggestion!,
          description: _lastRecipeDetails ?? "",
          calories: _lastCalories ?? 400,
          publie: 1,
          imageUrl: null,
          utilisateurId: 1,
        );

        await _recetteService.insertRecette(recette);
        _resetContext();

        return "✅ Recette ajoutee avec succes : **${recette.nom}** (${recette.calories} kcal)";
      } else {
        return "Je nai pas de recette en memoire 😅 veux tu que je t en propose une ?";
      }
    }

    // ❌ Refus
    if (text.contains("non") || text.contains("pas maintenant")) {
      _resetContext();
      return "Pas de souci 😌 on garde ca pour plus tard.";
    }

    // Réponse libre IA
    final generic = await _openRouter.processUserMessage(
      userText,
      structured: false,
    );
    return generic;
  }

  // 🕒 Moment du jour
  String _momentDeJournee() {
    final hour = DateTime.now().hour;
    if (hour < 11) return "petit dejeuner";
    if (hour < 17) return "dejeuner";
    return "diner";
  }

  // 🔍 Type de repas
  String _detectTypeRepas(String text) {
    if (text.contains("matin") || text.contains("petit"))
      return "petit dejeuner";
    if (text.contains("dejeuner") || text.contains("midi")) return "dejeuner";
    if (text.contains("diner") || text.contains("soir")) return "diner";
    if (text.contains("collation") || text.contains("gouter"))
      return "collation";
    return _momentDeJournee();
  }

  // 🍔 Extraction propre du nom du repas
  String _extraireNomRepas(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(
          RegExp(
            r'\b(jai|mange|pris|ajoute|repas|mes|mon|ma|le|la|les|un|une|du|de|dans|a|au|aux|ce|cette|soir|matin|midi)\b',
          ),
          '',
        )
        .trim();
    return cleaned;
  }

  // 🔥 Calories estimées
  double _estimerCalories(String nom) {
    final n = nom.toLowerCase();
    if (n.contains("burger")) return 800;
    if (n.contains("pizza")) return 900;
    if (n.contains("salade")) return 250;
    if (n.contains("poulet")) return 600;
    if (n.contains("pates") || n.contains("pasta")) return 700;
    if (n.contains("smoothie")) return 300;
    if (n.contains("couscous")) return 550;
    if (n.contains("tacos")) return 750;
    return 500;
  }

  // 🧩 Extraction de plusieurs repas
  List<String> _extraireRepasDepuisTexte(String texte) {
    final lines = texte.split('\n');
    return lines
        .where((line) => line.trim().isNotEmpty && line.contains("nom"))
        .map((line) => line.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim())
        .toList();
  }

  int? _detectChoiceIndex(String text) {
    if (text.contains("1")) return 0;
    if (text.contains("2")) return 1;
    if (text.contains("3")) return 2;
    return null;
  }

  void _resetContext() {
    _lastIntent = null;
    _lastSuggestion = null;
    _lastRecipeDetails = null;
    _lastCalories = null;
    _lastIngredients = null;
    _mealOptions.clear();
  }

  String _normalizeText(String input) {
    const accents = 'àâäãåáèéêëìíîïòóôöõùúûüçñ';
    const sansAccents = 'aaaaaaeeeeiiiiooooouuuucn';
    var output = input;
    for (int i = 0; i < accents.length; i++) {
      output = output.replaceAll(accents[i], sansAccents[i]);
    }
    return output;
  }
}
