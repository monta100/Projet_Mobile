// ignore_for_file: avoid_print
import '../Services/openrouter_service.dart';
import '../Services/repas_service.dart';
import '../Services/recette_service.dart';
import '../Entites/repas.dart';
import '../Entites/recette.dart';

class NutriBotBrain {
  final OpenRouterService _openRouter = OpenRouterService();
  final RepasService _repasService = RepasService();
  final RecetteService _recetteService = RecetteService();

  String? _lastIntent; // "repas" / "recette" / "discussion"
  String? _lastSuggestion;
  String? _lastRecipeDetails;

  /// 🎯 Réponse intelligente
  Future<String> process(String userText) async {
    final text = userText.toLowerCase();

    // --- 1. Salutation ---
    if (text.contains("bonjour") || text.contains("salut")) {
      return "👋 Hey ! Heureux de te revoir 😄. On cuisine quoi aujourd’hui ?";
    }

    // --- 2. Demande d’un repas ---
    if (text.contains("repas") || text.contains("manger")) {
      _lastIntent = "repas";
      final idea = await _openRouter.processUserMessage(
          "Propose trois idées de repas équilibrés avec calories dans un ton amical et humain, pas en JSON.");
      _lastSuggestion = "Repas suggéré";
      return "🍽️ Voici ce que je te propose 👇\n\n$idea\n\nLequel te tente le plus ? 😋";
    }

    // --- 3. Choix d’un plat simple (burger, salade, etc.) ---
    if (_lastIntent == "repas" &&
        (text.contains("burger") ||
            text.contains("salade") ||
            text.contains("poulet") ||
            text.contains("riz") ||
            text.contains("tajine") ||
            text.contains("pâtes"))) {
      _lastSuggestion = userText;
      return "😋 Miam ! Le **${userText}** a l’air délicieux ! Tu veux que je l’ajoute à ton ${_momentDeJournee()} ?";
    }

    // --- 4. Confirmation d’ajout de repas ---
    if (_lastIntent == "repas" &&
        (text.contains("ajoute") ||
            text.contains("ajouter") ||
            text.contains("oui") ||
            text.contains("vas-y"))) {
      if (_lastSuggestion != null) {
        await _repasService.insertRepas(Repas(
          type: _momentDeJournee(),
          date: DateTime.now(),
          nom: _lastSuggestion!,
          caloriesTotales: 650,
          utilisateurId: 1,
        ));
        final repasName = _lastSuggestion!;
        _lastSuggestion = null;
        return "💪 C’est noté ! J’ai ajouté **$repasName** à ton ${_momentDeJournee()} 🍊";
      } else {
        return "Dis-moi juste le nom du repas à ajouter 😄";
      }
    }

    // --- 5. L’utilisateur veut une recette ---
    if (text.contains("recette") || text.contains("préparer") || text.contains("cuisine")) {
      _lastIntent = "recette";
      final idea = await _openRouter.processUserMessage(
          "Propose une recette tunisienne ou méditerranéenne avec son nom et une courte description amicale.");
      final details = await _openRouter.processUserMessage(
          "Décris étape par étape comment préparer la recette suivante : $idea. Utilise un ton humain et chaleureux.");
      _lastSuggestion = idea.split('\n').first.trim();
      _lastRecipeDetails = details;

      return "🍳 Super idée ! Voici la recette de **${_lastSuggestion}** 👇\n\n$details\n\nSouhaites-tu que je l’enregistre dans ton carnet ? 😍";
    }

    // --- 6. Ajout d’une recette existante ---
    if ((_lastIntent == "recette" && (text.contains("ajoute") || text.contains("ajouter"))) ||
        text.contains("ajouter cette recette")) {
      if (_lastSuggestion != null && _lastRecipeDetails != null) {
        await _recetteService.insertRecette(Recette(
          nom: _lastSuggestion!,
          description: _lastRecipeDetails!,
          calories: 400,
          publie: 0,
          imageUrl: null,
          utilisateurId: 1,
        ));
        final recipeName = _lastSuggestion!;
        _lastSuggestion = null;
        _lastRecipeDetails = null;
        return "🥰 Parfait ! J’ai ajouté ta recette **$recipeName** à ton carnet de cuisine 🍴";
      } else {
        return "Hmm je ne vois pas de recette en mémoire 🤔 veux-tu que je t’en propose une nouvelle ?";
      }
    }

    // --- 7. Refus ---
    if (text.contains("non") || text.contains("pas maintenant")) {
      return "Aucun souci 😌. On garde ça pour plus tard. Tu veux juste discuter un peu ?";
    }

    // --- 8. Discussion libre ---
    if (text.contains("merci")) {
      return "Avec plaisir 🧡. Je suis toujours là pour papoter ou t’aider à bien manger 😄";
    }
    if (text.contains("fatigué")) {
      return "💤 Tu devrais essayer un smoothie banane-avoine, c’est plein d’énergie douce 🍌💪";
    }

    // --- 9. Fallback général ---
    final generic = await _openRouter.processUserMessage(userText);
    return "🤗 $generic";
  }

  /// 🕒 Déterminer le moment du jour
  String _momentDeJournee() {
    final hour = DateTime.now().hour;
    if (hour < 11) return "petit-déjeuner";
    if (hour < 17) return "déjeuner";
    return "dîner";
  }
}
