import 'package:google_generative_ai/google_generative_ai.dart';
import '../config.dart';

class GeminiAIService {
  static final GeminiAIService _instance = GeminiAIService._internal();
  factory GeminiAIService() => _instance;
  GeminiAIService._internal();

  late final GenerativeModel _model;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('Debug: Initializing Gemini AI Service');
      
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: AppConfig.geminiApiKey,
      );
      
      _isInitialized = true;
      print('Debug: Gemini AI Service initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing Gemini AI Service: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<String> getBudgetAdvice({
    required double currentWeight,
    required double targetWeight,
    required int trainingWeeks,
    required int sessionsPerWeek,
    required double gymCost,
    required double dailyFoodBudget,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      print('Debug: Preparing to generate budget advice');

      final prompt = '''
      En tant qu'expert en fitness et nutrition, fournis des conseils personnalisés pour l'optimisation du budget avec ces détails :
      - Poids actuel : $currentWeight kg
      - Poids cible : $targetWeight kg (${targetWeight > currentWeight ? 'gain' : 'perte'} de ${(targetWeight - currentWeight).abs().toStringAsFixed(2)} kg)
      - Durée d'entraînement : $trainingWeeks semaines
      - Fréquence d'entraînement : $sessionsPerWeek séances par semaine
      - Coût mensuel gym : \$$gymCost
      - Budget alimentaire quotidien : \$$dailyFoodBudget

      Fournis 3 conseils spécifiques pour :
      1. Optimiser le budget alimentaire tout en répondant aux besoins nutritionnels
      2. Tirer le meilleur parti de l'abonnement gym
      3. Économiser sur les suppléments ou l'équipement si nécessaire

      Formate la réponse en points et reste concis. RÉPONDS EN FRANÇAIS.
      ''';

      print('Debug: Sending prompt to Gemini API');
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        print('Debug: Received empty response from Gemini API');
        return 'Impossible de générer des conseils pour le moment. Veuillez réessayer.';
      }

      print('Debug: Successfully generated advice');
      return response.text!;
    } catch (e, stackTrace) {
      print('Error generating budget advice: $e');
      print('Stack trace: $stackTrace');
      return '''
Erreur lors de la génération des conseils. Veuillez vérifier :
1. Votre connexion internet
2. La validité de la clé API
3. Les limites de quota quotidien

Détails techniques : ${e.toString()}
''';
    }
  }

  Future<String> getCustomMealPlan({
    required double currentWeight,
    required double targetWeight,
    required double dailyFoodBudget,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      print('Debug: Preparing to generate meal plan');

      final prompt = '''
      Crée un plan de repas économique en tenant compte de :
      - Poids actuel : $currentWeight kg
      - Poids cible : $targetWeight kg
      - Budget alimentaire quotidien : \$$dailyFoodBudget

      Fournis un exemple de plan de repas d'une journée qui :
      1. Respecte le budget quotidien
      2. Soutient l'objectif de ${targetWeight > currentWeight ? 'prise' : 'perte'} de poids
      3. Inclut des aliments nutritifs et abordables
      4. Liste le coût estimé par repas

      Reste concis et pratique. RÉPONDS EN FRANÇAIS.
      ''';

      print('Debug: Sending meal plan prompt to Gemini API');
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        print('Debug: Received empty meal plan response from Gemini API');
        return 'Impossible de générer un plan de repas pour le moment. Veuillez réessayer.';
      }

      print('Debug: Successfully generated meal plan');
      return response.text!;
    } catch (e, stackTrace) {
      print('Error generating meal plan: $e');
      print('Stack trace: $stackTrace');
      return '''
Erreur lors de la génération du plan de repas. Veuillez vérifier :
1. Votre connexion internet
2. La validité de la clé API
3. Les limites de quota quotidien

Détails techniques : ${e.toString()}
''';
    }
  }
}