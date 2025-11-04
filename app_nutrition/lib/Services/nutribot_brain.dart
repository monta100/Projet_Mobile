// ignore_for_file: avoid_print, unused_field, dead_code, prefer_final_fields, unnecessary_brace_in_string_interps, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/openrouter_service.dart';
import '../Services/repas_service.dart';
import '../Services/recette_service.dart';
import '../Services/ingredient_service.dart';
import '../Entites/repas.dart';
import '../Entites/recette.dart';
import '../Entites/ingredient.dart';
import 'preferences_service.dart';

class NutriBotBrain {
  final OpenRouterService _openRouter = OpenRouterService();
  final RepasService _repasService = RepasService();
  final RecetteService _recetteService = RecetteService();
  final IngredientService _ingredientService = IngredientService();

  String? _lastIntent; // "repas" | "recette" | null
  String? _lastSuggestion; // nom recette
  String? _lastRecipeDetails; // description / étapes
  double? _lastCalories; // kcal recette
  List<Map<String, dynamic>>? _lastIngredients;
  List<String> _mealOptions = [];

  Future<String> process(String userText) async {
    final text = _normalizeText(userText.toLowerCase().trim());

    // 17) —— Proposer une recette à partir d'une liste d'ingrédients ——
    if (_containsAny(text, [
          "recette avec",
          "que puis-je faire avec",
          "que puis je faire avec",
          "idee avec",
          "j'ai comme ingredients",
          "jai comme ingredients",
          "j'ai",
          "jai",
        ]) &&
        text.contains("ingredient")) {
      // Extraction simple des ingrédients après "avec" ou "ingredients"
      String ingredientsList = "";
      final reg = RegExp(r'(?:avec|ingredients?)(.*)', caseSensitive: false);
      final match = reg.firstMatch(userText.toLowerCase());
      if (match != null && match.group(1) != null) {
        ingredientsList = match
            .group(1)!
            .replaceAll(RegExp(r'[:\.]'), '')
            .trim();
      } else {
        // fallback: tout après "j'ai" ou "jai"
        final reg2 = RegExp(r"j('ai|ai)\s+(.*)", caseSensitive: false);
        final match2 = reg2.firstMatch(userText.toLowerCase());
        if (match2 != null && match2.group(1) != null) {
          ingredientsList = match2
              .group(1)!
              .replaceAll(RegExp(r'[:\.]'), '')
              .trim();
        }
      }
      if (ingredientsList.isEmpty) {
        return "Merci de préciser la liste d'ingrédients, par exemple : 'Recette avec tomates, riz, poulet'.";
      }

      // Appel direct à openrouter_service pour obtenir la recette
      final prompt =
          "Propose une recette originale et détaillée à partir uniquement des ingrédients suivants : $ingredientsList. "
          "Réponds uniquement avec un objet JSON valide, sans aucun texte avant ou après. "
          "Le JSON doit avoir les clés suivantes: 'nom' (string), 'description' (string), 'calories' (nombre), 'ingredients' (un tableau d'objets avec 'nom', 'quantite', 'unite', 'calories'), et 'imageUrl' (string, une URL d'image libre de droit du plat ou null si indisponible). "
          "La recette doit utiliser un maximum de ces ingrédients et être appétissante.";

      final raw = await _openRouter.processUserMessage(
        prompt,
        structured: true,
      );
      var parsed = _tryParseAndFormatRecipeResponse(raw, userText: userText);
      if (parsed != null) return parsed;

      // Fallback texte brut
      return "Voici une idée de recette avec tes ingrédients :\n\n$raw";
    }

    // 1. Priorité : demande explicite de recette (avant humeur ou temps repas)
    if (_containsAny(text, [
      "recette",
      "preparer",
      "cuisine",
      "comment faire",
    ])) {
      _lastIntent = "recette";

      // Prompt amélioré : demander au moins 7 ingrédients
      final raw = await _openRouter.processUserMessage(
        "IMPORTANT: Réponds uniquement avec un objet JSON valide, sans aucun texte avant ou après. "
        "Crée une recette détaillée pour '${userText}'. "
        "Le JSON doit avoir les clés suivantes: 'nom' (string), 'description' (string), 'calories' (nombre), 'ingredients' (un tableau d'objets avec 'nom', 'quantite', 'unite', 'calories'), et 'imageUrl' (string, une URL d'image libre de droit du plat ou null si indisponible). "
        "La liste d'ingrédients doit être riche et variée (au moins 7 ingrédients différents, avec quantités et unités précises).",
        structured: true,
      );

      var parsed = _tryParseAndFormatRecipeResponse(raw, userText: userText);
      if (parsed != null) return parsed;

      // Fallback IA : on génère description et ingrédients séparément
      // 1. Extraire le nom demandé
      String nom = "Recette inconnue";
      final reg = RegExp(r'recette\s+([\w\s-]+)', caseSensitive: false);
      final match = reg.firstMatch(userText.toLowerCase());
      if (match != null && match.group(1) != null) {
        nom = match.group(1)!.trim();
      } else {
        nom = userText.trim();
      }
      // 2. Générer description
      final desc = await _openRouter.processUserMessage(
        "Donne une description appétissante et détaillée d'une recette de $nom en une phrase.",
        structured: false,
      );
      // 3. Générer ingrédients
      final ingText = await _openRouter.processUserMessage(
        "Liste les ingrédients nécessaires pour une recette de $nom sous forme de liste à puces ou de tableau JSON.",
        structured: false,
      );
      // 4. Parse ingrédients (liste à puces OU tableau JSON mal formé)
      List<Map<String, dynamic>> ingredients = [];
      // Cas 1 : objets JSON mal formés (ex: {"nom""Tortillas",...})
      final objectMatches = RegExp(r'\{([^}]+)\}').allMatches(ingText);
      if (objectMatches.isNotEmpty) {
        for (final m in objectMatches) {
          var obj = m.group(1)!;
          // Correction des faux JSON : remplace "nom""Tortillas" par "nom":"Tortillas"
          obj = obj.replaceAllMapped(
            RegExp(r'"([a-zA-Z_]+)""'),
            (match) => '"${match.group(1)}":"',
          );
          // Ajoute les virgules manquantes entre les champs
          obj = obj.replaceAll(RegExp(r'"\s*,'), '",');
          // Sépare les champs
          final fields = obj.split(',');
          String nom = '';
          double quantite = 1.0;
          String unite = '';
          double calories = 0.0;
          for (final f in fields) {
            final kv = f.split(':');
            if (kv.length < 2) continue;
            final key = kv[0]
                .replaceAll(RegExp(r'["]'), '')
                .trim()
                .toLowerCase();
            final val = kv[1].replaceAll(RegExp(r'["]'), '').trim();
            if (key == 'nom')
              nom = val;
            else if (key == 'quantite')
              quantite = double.tryParse(val) ?? 1.0;
            else if (key == 'unite')
              unite = val;
            else if (key == 'calories')
              calories = double.tryParse(val) ?? 0.0;
          }
          if (nom.isNotEmpty) {
            ingredients.add({
              'nom': nom,
              'quantite': quantite,
              'unite': unite,
              'calories': calories,
            });
          }
        }
      }
      // Cas 2 : liste à puces ou lignes simples
      if (ingredients.isEmpty) {
        final bulletLines = ingText
            .split('\n')
            .where((l) => l.trim().startsWith('-') || l.trim().startsWith('*'))
            .toList();
        final stopWords = [
          'nom',
          'quantite',
          'unite',
          'piece',
          'g',
          'kg',
          'ml',
          'l',
          'cuillère',
          'cuillere',
          'sachet',
          'tablette',
          'tranche',
          'portion',
        ];
        for (final l in bulletLines) {
          var cleaned = l.replaceFirst(RegExp(r'^[-*]\s*'), '').trim();
          if (cleaned.isEmpty) continue;
          final lower = cleaned.toLowerCase();
          if (stopWords.contains(lower)) continue;
          // Extraction avancée : "4 pièces de Tortillas" ou "Tortillas (4 pièces)"
          final regex1 = RegExp(
            r'^(\d+[\.,]?\d*)\s*([a-zA-Zéèêûîôàçù]+)\s+de\s+(.+)$',
          );
          final regex2 = RegExp(
            r'^(.+)\s*\((\d+[\.,]?\d*)\s*([a-zA-Zéèêûîôàçù]+)\)$',
          );
          double quantite = 1.0;
          String unite = '';
          String nom = cleaned;
          final m1 = regex1.firstMatch(cleaned);
          final m2 = regex2.firstMatch(cleaned);
          if (m1 != null) {
            quantite =
                double.tryParse(m1.group(1)!.replaceAll(',', '.')) ?? 1.0;
            unite = m1.group(2) ?? '';
            nom = m1.group(3) ?? cleaned;
          } else if (m2 != null) {
            nom = m2.group(1) ?? cleaned;
            quantite =
                double.tryParse(m2.group(2)!.replaceAll(',', '.')) ?? 1.0;
            unite = m2.group(3) ?? '';
          }
          ingredients.add({
            'nom': nom.trim(),
            'quantite': quantite,
            'unite': unite,
            'calories': 0.0,
          });
        }
      }
      // 5. Ajout en base
      // Extraction de l'image si présente dans la réponse IA
      String? imageUrl;
      final imageMatch = RegExp(
        r'(https?://[^\s)]+\.(jpg|jpeg|png|webp|gif))',
        caseSensitive: false,
      ).firstMatch(ingText);
      if (imageMatch != null) {
        imageUrl = imageMatch.group(1);
      }
      final recette = Recette(
        nom: nom,
        description: desc.trim(),
        calories: _estimerCalories(nom),
        publie: 1,
        imageUrl: imageUrl, // Ajout de l'image IA si trouvée
        utilisateurId: 3, // Fixé pour test
      );
      final recetteId = await _recetteService.insertRecette(recette);
      for (final ing in ingredients) {
        await _ingredientService.insertIngredient(
          Ingredient(
            nom: ing['nom'],
            quantite: ing['quantite'],
            unite: ing['unite'],
            calories: ing['calories'],
            recetteId: recetteId,
          ),
        );
      }
      _resetContext();
      return "Excellent choix ! Votre recette **$nom** a bien été ajoutée. Vous pouvez la consulter dans votre carnet de recettes.";
    }

    // 0) Salutation
    if (text.contains("bonjour") || text.contains("salut")) {
      return "👋 Salut c est Snacky 🍊 Que veux tu faire aujourd hui ?";
    }

    // Prioritize date-based queries
    final dateRegExp = RegExp(
      r"(hier|aujourd'hui|([0-9]{1,2})[/-]([0-9]{1,2})[/-]([0-9]{2,4}))",
    );
    if (dateRegExp.hasMatch(text) &&
        (_containsAny(text, [
          "mange",
          "repas",
          "calorie",
          "calories",
          "total",
        ]))) {
      DateTime date;
      if (text.contains("hier")) {
        date = DateTime.now().subtract(const Duration(days: 1));
      } else if (text.contains("aujourd'hui")) {
        date = DateTime.now();
      } else {
        final match = dateRegExp.firstMatch(text);
        if (match != null && match.group(2) != null && match.group(3) != null) {
          final day = int.parse(match.group(2)!);
          final month = int.parse(match.group(3)!);
          final year = match.group(4) != null && match.group(4)!.length == 4
              ? int.parse(match.group(4)!)
              : DateTime.now().year;
          date = DateTime(year, month, day);
        } else {
          return "Je n'ai pas compris la date. Reformule ta question.";
        }
      }
      // Fetch meals for the date
      final repasList = await _repasService.getRepasByDate(date);
      if (repasList.isEmpty) {
        return "Aucun repas trouvé pour cette date.";
      }
      final totalCalories = repasList.fold<double>(
        0.0,
        (sum, r) => sum + r.caloriesTotales,
      );
      final repasDetails = repasList
          .map((r) => "- ${r.nom} (${r.caloriesTotales} kcal)")
          .join("\n");
      return "Voici tes repas du ${date.day}/${date.month}/${date.year} :\n$repasDetails\n\nTotal : $totalCalories kcal";
    }

    // 2) —— Contexte RECETTE prioritaire quand l'utilisateur dit "ajouter" ——
    if (_lastIntent == "recette" &&
        (_containsAny(text, [
          "ajouter la",
          "ajoute la",
          "ajouter cette recette",
          "ajouter recette",
          "ajoute recette",
          "oui",
          "vas y",
        ]))) {
      if (_lastSuggestion != null) {
        final recette = Recette(
          nom: _lastSuggestion!,
          description: _lastRecipeDetails ?? "",
          calories: _lastCalories ?? 400,
          publie: 1,
          imageUrl: null,
          utilisateurId: 3, // Fixé pour test
        );
        await _recetteService.insertRecette(recette);
        _resetContext();
        return "Excellent choix ! Votre recette **${recette.nom}** a bien été ajoutée. Vous pouvez la consulter dans votre carnet de recettes.";
      }

      // 🔸 Proposer automatiquement une recette si aucune n'est en mémoire
      final suggestion = await _openRouter.processUserMessage(
        "Propose une recette simple et rapide à ajouter au carnet de recettes. Donne uniquement le nom de la recette.",
        structured: false,
      );
      if (suggestion.isNotEmpty) {
        _lastSuggestion = suggestion;
        return "Je n'ai pas de recette en mémoire. Que pensez-vous de cette suggestion : **$suggestion** ?";
      }

      return "Je n'ai pas de recette en mémoire. Voulez-vous que je vous en propose une ?";
    }

    // Réponse contextuelle après la question sur l'humeur
    final agreeWords = [
      "oui",
      "vas y",
      "vasy",
      "vas-y",
      "ok",
      "daccord",
      "d'accord",
      "go",
      "let's go",
      "c'est parti",
      "allez",
      "on y va",
      "ça marche",
      "ca marche",
      "entendu",
      "bien sur",
      "bien sûr",
      "je veux",
      "je veux bien",
    ];
    if (agreeWords.any(
          (w) =>
              text.replaceAll("'", "").replaceAll("-", " ").trim() ==
              w.replaceAll("'", "").replaceAll("-", " ").trim(),
        ) &&
        _lastIntent == null) {
      final mood = await PreferencesService.getMood();
      if (mood != null && mood.isNotEmpty) {
        // Proposer un repas adapté à l'humeur via l'IA
        String prompt =
            "Propose une idée de repas ou collation adaptée à une personne qui se sent $mood aujourd'hui. Donne une courte description, les calories et la liste des ingrédients (nom, quantité, unité). Formate la réponse en texte lisible, pas en JSON.";
        final idea = await _openRouter.processUserMessage(
          prompt,
          structured: false,
        );
        return "Voici une suggestion adaptée à ton humeur ($mood) :\n\n$idea\n\nSi tu veux une autre idée ou des conseils, dis-le moi !";
      } else {
        return "Je suis là pour répondre à toutes tes questions sur la nutrition et la santé. N'hésite pas à me demander des conseils ou des informations !";
      }
    }

    // 2) —— Ajout d’un repas (jamais si on vient d’une recette) ——
    if (_isMealAddSentence(text)) {
      final typeRepas = _detectTypeRepas(text);
      final nomRepas = _extraireNomRepas(text);

      if (nomRepas.isNotEmpty && !_looksLikeGenericVerb(nomRepas)) {
        final repas = Repas(
          type: typeRepas,
          date: DateTime.now(),
          nom: nomRepas,
          caloriesTotales: _estimerCalories(nomRepas),
          utilisateurId: 3, // Fixé pour test
        );
        await _repasService.insertRepas(repas);

        // 🔸 Mise à jour de la mémoire Snacky
        await PreferencesService.setLastMealTime(DateTime.now());
        await PreferencesService.incrementMealCount();

        return "✅ J’ai ajouté ton repas : **$nomRepas** dans *$typeRepas* (${repas.caloriesTotales} kcal).";
      }
      return "Je n'ai pas compris le plat, peux-tu reformuler ?";
    }

    // 3) —— Suggestions de repas
    if ((text.contains("repas") ||
            text.contains("idee") ||
            text.contains("suggestion")) &&
        !_containsAny(text, ["jai", "mange", "ajoute", "ajouter"])) {
      _lastIntent = "repas";
      String moment = _momentDeJournee();
      String prompt =
          "Propose une idée de plat équilibré pour $moment avec une courte description, les calories et la liste des ingrédients (nom, quantité, unité). Formate la réponse en texte lisible, pas en JSON.";
      final idea = await _openRouter.processUserMessage(
        prompt,
        structured: false,
      );
      // Affichage élégant, pas d'ajout en base
      return "✨ Idée de plat pour le $moment :\n\n$idea\n\nTu veux la recette complète ou une autre suggestion ?";
    }

    // 🔍 Recherche intelligente de recette selon les ingrédients disponibles
    if (_containsAny(text, [
      "avec",
      "j ai",
      "jai",
      "il me reste",
      "j ai que",
      "que puis je cuisiner",
      "que faire avec",
      "je veux cuisiner avec",
    ])) {
      final prompt =
          """
Tu es Snacky 🍊, un assistant culinaire expert et bienveillant.
L'utilisateur dispose des ingrédients suivants : $userText.

Ta mission :
1️⃣ Propose une recette équilibrée, simple et délicieuse à base de ces ingrédients.
2️⃣ Fournis :
   - 🍽️ Le nom du plat
   - 📝 Une courte description (1 à 2 phrases max)
   - 🔥 Les calories estimées (approximatives)
   - 🧂 La liste d’ingrédients (avec nom, quantité, unité)
   - 👨‍🍳 Les étapes de préparation (3 à 5 étapes numérotées avec emojis)
3️⃣ Si les ingrédients sont limités, complète avec des suggestions simples.
4️⃣ Formate tout en texte clair, sans JSON.
5️⃣ Termine par : "Souhaites-tu que je l’ajoute à ton carnet de recettes ? 🍴"
""";

      final response = await _openRouter.processUserMessage(
        prompt,
        structured: false,
      );

      return "🍳 Voici une idée de recette avec ce que tu as :\n\n$response";
    }

    // 4) —— Demande de RECETTE (on parse et on formate proprement)
    if (_containsAny(text, [
      "recette",
      "preparer",
      "cuisine",
      "comment faire",
    ])) {
      _lastIntent = "recette";

      final raw = await _openRouter.processUserMessage(
        "IMPORTANT: Réponds uniquement avec un objet JSON valide, sans aucun texte avant ou après. "
        "Crée une recette détaillée pour '${userText}'. "
        "Le JSON doit avoir les clés suivantes: 'nom' (string), 'description' (string), 'calories' (nombre), 'ingredients' (un tableau d'objets avec 'nom', 'quantite', 'unite', 'calories'), et 'imageUrl' (string, une URL d'image libre de droit du plat ou null si indisponible).",
        structured: true,
      );

      var parsed = _tryParseAndFormatRecipeResponse(raw, userText: userText);
      if (parsed != null) return parsed;

      // Fallback IA : on génère description et ingrédients séparément
      // 1. Extraire le nom demandé
      String nom = "Recette inconnue";
      final reg = RegExp(r'recette\s+([\w\s-]+)', caseSensitive: false);
      final match = reg.firstMatch(userText.toLowerCase());
      if (match != null && match.group(1) != null) {
        nom = match.group(1)!.trim();
      } else {
        nom = userText.trim();
      }
      // 2. Générer description
      final desc = await _openRouter.processUserMessage(
        "Donne une description appétissante et détaillée d'une recette de $nom en une phrase.",
        structured: false,
      );
      // 3. Générer ingrédients
      final ingText = await _openRouter.processUserMessage(
        "Liste les ingrédients nécessaires pour une recette de $nom sous forme de liste à puces ou de tableau JSON.",
        structured: false,
      );
      // 4. Parse ingrédients (liste à puces OU tableau JSON mal formé)
      List<Map<String, dynamic>> ingredients = [];
      // Cas 1 : objets JSON mal formés (ex: {"nom""Tortillas",...})
      final objectMatches = RegExp(r'\{([^}]+)\}').allMatches(ingText);
      if (objectMatches.isNotEmpty) {
        for (final m in objectMatches) {
          var obj = m.group(1)!;
          // Correction des faux JSON : remplace "nom""Tortillas" par "nom":"Tortillas"
          obj = obj.replaceAllMapped(
            RegExp(r'"([a-zA-Z_]+)""'),
            (match) => '"${match.group(1)}":"',
          );
          // Ajoute les virgules manquantes entre les champs
          obj = obj.replaceAll(RegExp(r'"\s*,'), '",');
          // Sépare les champs
          final fields = obj.split(',');
          String nom = '';
          double quantite = 1.0;
          String unite = '';
          double calories = 0.0;
          for (final f in fields) {
            final kv = f.split(':');
            if (kv.length < 2) continue;
            final key = kv[0]
                .replaceAll(RegExp(r'["]'), '')
                .trim()
                .toLowerCase();
            final val = kv[1].replaceAll(RegExp(r'["]'), '').trim();
            if (key == 'nom')
              nom = val;
            else if (key == 'quantite')
              quantite = double.tryParse(val) ?? 1.0;
            else if (key == 'unite')
              unite = val;
            else if (key == 'calories')
              calories = double.tryParse(val) ?? 0.0;
          }
          if (nom.isNotEmpty) {
            ingredients.add({
              'nom': nom,
              'quantite': quantite,
              'unite': unite,
              'calories': calories,
            });
          }
        }
      }
      // Cas 2 : liste à puces ou lignes simples
      if (ingredients.isEmpty) {
        final bulletLines = ingText
            .split('\n')
            .where((l) => l.trim().startsWith('-') || l.trim().startsWith('*'))
            .toList();
        final stopWords = [
          'nom',
          'quantite',
          'unite',
          'piece',
          'g',
          'kg',
          'ml',
          'l',
          'cuillère',
          'cuillere',
          'sachet',
          'tablette',
          'tranche',
          'portion',
        ];
        for (final l in bulletLines) {
          var cleaned = l.replaceFirst(RegExp(r'^[-*]\s*'), '').trim();
          if (cleaned.isEmpty) continue;
          final lower = cleaned.toLowerCase();
          if (stopWords.contains(lower)) continue;
          // Extraction avancée : "4 pièces de Tortillas" ou "Tortillas (4 pièces)"
          final regex1 = RegExp(
            r'^(\d+[\.,]?\d*)\s*([a-zA-Zéèêûîôàçù]+)\s+de\s+(.+)$',
          );
          final regex2 = RegExp(
            r'^(.+)\s*\((\d+[\.,]?\d*)\s*([a-zA-Zéèêûîôàçù]+)\)$',
          );
          double quantite = 1.0;
          String unite = '';
          String nom = cleaned;
          final m1 = regex1.firstMatch(cleaned);
          final m2 = regex2.firstMatch(cleaned);
          if (m1 != null) {
            quantite =
                double.tryParse(m1.group(1)!.replaceAll(',', '.')) ?? 1.0;
            unite = m1.group(2) ?? '';
            nom = m1.group(3) ?? cleaned;
          } else if (m2 != null) {
            nom = m2.group(1) ?? cleaned;
            quantite =
                double.tryParse(m2.group(2)!.replaceAll(',', '.')) ?? 1.0;
            unite = m2.group(3) ?? '';
          }
          ingredients.add({
            'nom': nom.trim(),
            'quantite': quantite,
            'unite': unite,
            'calories': 0.0,
          });
        }
      }
      // 5. Ajout en base
      // Extraction de l'image si présente dans la réponse IA
      String? imageUrl;
      final imageMatch = RegExp(
        r'(https?://[^\s)]+\.(jpg|jpeg|png|webp|gif))',
        caseSensitive: false,
      ).firstMatch(ingText);
      if (imageMatch != null) {
        imageUrl = imageMatch.group(1);
      }
      final recette = Recette(
        nom: nom,
        description: desc.trim(),
        calories: _estimerCalories(nom),
        publie: 1,
        imageUrl: imageUrl, // Ajout de l'image IA si trouvée
        utilisateurId: 3, // Fixé pour test
      );
      final recetteId = await _recetteService.insertRecette(recette);
      for (final ing in ingredients) {
        await _ingredientService.insertIngredient(
          Ingredient(
            nom: ing['nom'],
            quantite: ing['quantite'],
            unite: ing['unite'],
            calories: ing['calories'],
            recetteId: recetteId,
          ),
        );
      }
      _resetContext();
      return "Excellent choix ! Votre recette **$nom** a bien été ajoutée. Vous pouvez la consulter dans votre carnet de recettes.";
    }

    // 5) —— Etapes de preparation
    if (_lastIntent == "recette" &&
        _containsAny(text, ["etape", "oui", "vas y", "montre"])) {
      if (_lastSuggestion != null) {
        final steps = await _openRouter.processUserMessage(
          "Explique les etapes pour preparer ${_lastSuggestion} au format numerote clair avec emojis de cuisine",
          structured: false,
        );
        _lastRecipeDetails = steps;
        return "🍽️ Voici les etapes pour **${_lastSuggestion}** 👇\n\n${_formatEtapes(steps)}\n\nDis simplement *ajouter la* pour l enregistrer";
      }
    }

    // 0b) ——— Questions sur repas ou calories d'une date ———
    final dateReg = RegExp(
      r"(hier|aujourd'hui|([0-9]{1,2})[/-]([0-9]{1,2})[/-]([0-9]{2,4}))",
    );
    if (dateReg.hasMatch(text) &&
        (_containsAny(text, [
          "mange",
          "repas",
          "calorie",
          "calories",
          "total",
        ]))) {
      DateTime date;
      if (text.contains("hier")) {
        date = DateTime.now().subtract(const Duration(days: 1));
      } else if (text.contains("aujourd'hui")) {
        date = DateTime.now();
      } else {
        final match = dateReg.firstMatch(text);
        if (match != null && match.group(2) != null && match.group(3) != null) {
          final day = int.parse(match.group(2)!);
          final month = int.parse(match.group(3)!);
          final year = match.group(4) != null && match.group(4)!.length == 4
              ? int.parse(match.group(4)!)
              : DateTime.now().year;
          date = DateTime(year, month, day);
        } else {
          return "Je n'ai pas compris la date. Reformule ta question.";
        }
      }
      // Récupère les repas de la date
      final repasList = await _repasService.getRepasByDate(date);
      if (repasList.isEmpty) {
        return "Aucun repas trouvé pour cette date.";
      }
      final totalCalories = repasList.fold<double>(
        0.0,
        (sum, r) => sum + r.caloriesTotales,
      );
      final repasDetails = repasList
          .map((r) => "- ${r.nom} (${r.caloriesTotales} kcal)")
          .join("\n");
      return "Voici tes repas du ${date.day}/${date.month}/${date.year} :\n$repasDetails\n\nTotal : $totalCalories kcal";
    }

    // 6) —— Refus
    if (_containsAny(text, ["non", "pas maintenant"])) {
      _resetContext();
      return "Pas de souci on garde ca pour plus tard";
    }

    // 7) —— Vérifications contextuelles (seulement si aucune autre logique n'a répondu)

    // 🔹 Vérifier le temps depuis le dernier repas
    final lastMeal = await PreferencesService.getLastMealTime();
    if (lastMeal != null) {
      final hoursSinceLastMeal = DateTime.now().difference(lastMeal).inHours;
      print("Heures depuis le dernier repas : $hoursSinceLastMeal");
      if (hoursSinceLastMeal >= 6) {
        return "😋 Ça fait plus de 6h depuis ton dernier repas ! Tu veux que je te propose une idée pour ${_momentDeJournee()} ?";
      }
    }

    // 🔹 Vérifier si l'utilisateur a déjà bien mangé aujourd'hui
    final mealsToday = await PreferencesService.getMealCountToday();
    if (mealsToday >= 3 && text.contains("repas")) {
      return "Tu as déjà bien mangé aujourd'hui 🍽️, je te suggère juste un petit snack ou une boisson légère.";
    }

    // 8) —— Fallback IA générique
    final generic = await _openRouter.processUserMessage(
      userText,
      structured: false,
    );
    // Si la réponse est du JSON, reformater pour l'utilisateur
    final parsed = _tryParseAndFormatRecipeResponse(generic);
    if (parsed != null) return parsed;
    return generic;
  }

  // ============ Helpers de logique ============

  bool _isMealAddSentence(String t) {
    // phrases du type "j ai mange ...", "jai pris ...", "manger ...", etc.
    final hasVerb = _containsAny(t, [
      "jai mange",
      "j ai mange",
      "jai pris",
      "j ai pris",
      "manger",
      "mange",
    ]);
    final isNotRecipeCtx = _lastIntent != "recette" && !t.contains("recette");
    // ne pas déclencher pour "ajouter la" etc.
    final notAddRecipe = !_containsAny(t, [
      "ajouter la",
      "ajoute la",
      "ajouter recette",
      "ajouter cette recette",
    ]);
    return hasVerb && isNotRecipeCtx && notAddRecipe;
  }

  bool _containsAny(String text, List<String> needles) {
    for (final n in needles) {
      if (text.contains(n)) return true;
    }
    return false;
  }

  bool _looksLikeGenericVerb(String s) {
    final x = s.trim();
    return x.isEmpty ||
        x == "ajouter" ||
        x == "ajoute" ||
        x == "manger" ||
        x == "mange" ||
        x == "repas" ||
        x == "la" ||
        x == "le";
  }

  // Parse un JSON recette (même cassé), formate en paragraphe, et enregistre en mémoire (pas en DB)
  String? _tryParseAndFormatRecipeResponse(
    String response, {
    String? userText,
  }) {
    String txt = response
        .replaceAll('""', '"')
        .replaceAll("”", '"')
        .replaceAll("“", '"')
        .trim();

    // Essai de parsing JSON
    try {
      final start = txt.indexOf("{");
      final end = txt.lastIndexOf("}");
      if (start == -1 || end == -1)
        throw const FormatException("No JSON object found");

      final jsonPart = txt.substring(start, end + 1);
      final Map<String, dynamic> r = jsonDecode(jsonPart);

      final nom = (r["nom"] ?? "Recette").toString();
      final description = (r["description"] ?? "Pas de description").toString();
      final calories = (r["calories"] ?? 0).toDouble();
      final ingredients = List<Map<String, dynamic>>.from(
        r["ingredients"] ?? [],
      );
      final imageUrl = r["imageUrl"]?.toString();

      _lastSuggestion = nom;
      _lastRecipeDetails = description;
      _lastCalories = calories;
      _lastIngredients = ingredients;

      // Affichage avec image si présente
      String imageSection = imageUrl != null && imageUrl.isNotEmpty
          ? "\n![Image du plat]($imageUrl)\n"
          : "";

      return "Résumé de la recette :\n- Nom : $nom\n- Description : $description\n- Calories : ${calories.toStringAsFixed(0)}\n$imageSection- Ingrédients : ${ingredients.isNotEmpty ? ingredients.map((i) => i['nom']).join(', ') : 'Aucun'}\n- Pour voir les étapes ou ajouter, dites 'oui' ou 'ajouter la'.";
    } catch (_) {
      // Fallback amélioré : on tente de générer description et ingrédients si manquants
      return null; // On gère ce cas dans process
    }
  }

  // ============ Mise en forme / NLP ============

  String _formatEtapes(String details) {
    final lines = details.split(RegExp(r'\n+'));
    String out = "";
    int i = 1;
    for (final raw in lines) {
      final l = raw.trim();
      if (l.isEmpty) continue;
      out += "$i️⃣  $l\n";
      i++;
    }
    return out.trim().isEmpty ? details : out.trim();
  }

  // Détecte le type de repas
  String _detectTypeRepas(String text) {
    if (text.contains("matin") || text.contains("petit"))
      return "petit dejeuner";
    if (text.contains("dejeuner") || text.contains("midi")) return "dejeuner";
    if (text.contains("diner") || text.contains("soir")) return "diner";
    if (text.contains("collation") || text.contains("gouter"))
      return "collation";
    return _momentDeJournee();
  }

  String _momentDeJournee() {
    final h = DateTime.now().hour;
    if (h < 11) return "petit dejeuner";
    if (h < 17) return "dejeuner";
    return "diner";
  }

  // Extrait proprement le nom du plat après le verbe
  String _extraireNomRepas(String text) {
    // Enlève les verbes d'action et ce qui précède pour isoler la partie intéressante
    String cleanedText = text
        .replaceFirst(RegExp(r'.*\b(mange|manger|pris|avale|consomme)\b'), '')
        .trim();

    // Si le remplacement n'a rien donné (pas de verbe trouvé), on repart du texte original
    if (cleanedText.isEmpty || cleanedText == text) {
      cleanedText = text;
    }

    // Enlève les mots contextuels et les articles
    final stopWords = RegExp(
      r'\b(petit dejeuner|dejeuner|diner|collation|matin|midi|soir|dans|a|au|aux|ce|cette|un|une|le|la|les|du|de|des|mon|ma|mes)\b',
      caseSensitive: false,
    );
    cleanedText = cleanedText.replaceAll(stopWords, '');

    // Nettoyage final: enlève la ponctuation et les espaces multiples
    cleanedText = cleanedText
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleanedText;
  }

  double _estimerCalories(String nom) {
    final n = nom.toLowerCase();
    if (n.contains("burger")) return 800;
    if (n.contains("pizza")) return 900;
    if (n.contains("salade")) return 250;
    if (n.contains("omelette") || n.contains("omelet")) return 500;
    if (n.contains("poulet")) return 600;
    if (n.contains("pates") || n.contains("pasta")) return 700;
    if (n.contains("smoothie")) return 300;
    if (n.contains("couscous")) return 550;
    if (n.contains("tacos")) return 750;
    if (n.contains("soupe")) return 400;
    return 500;
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
    const a = 'àâäãåáèéêëìíîïòóôöõùúûüçñ';
    const b = 'aaaaaaeeeeiiiiooooouuuucn';
    var out = input;
    for (int i = 0; i < a.length; i++) {
      out = out.replaceAll(a[i], b[i]);
    }
    return out;
  }

  // ============ Gestion des préférences utilisateur ============

  Future<void> saveUserPreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getUserPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Exemple d'utilisation :
  void exampleUsage() async {
    await saveUserPreference('diet', 'vegetarian');
    String? diet = await getUserPreference('diet');
    print('User diet preference: $diet');
  }
}
