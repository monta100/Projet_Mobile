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
      As a fitness and nutrition expert, provide personalized advice for budget optimization with these details:
      - Current weight: $currentWeight kg
      - Target weight: $targetWeight kg (${targetWeight > currentWeight ? 'gain' : 'loss'} of ${(targetWeight - currentWeight).abs()} kg)
      - Training duration: $trainingWeeks weeks
      - Training frequency: $sessionsPerWeek sessions per week
      - Monthly gym cost: \$$gymCost
      - Daily food budget: \$$dailyFoodBudget

      Please provide 3 specific tips to:
      1. Optimize the food budget while meeting nutritional needs
      2. Get the most value from the gym membership
      3. Save money on supplements or equipment if needed

      Format the response in bullet points and keep it concise.
      ''';

      print('Debug: Sending prompt to Gemini API');
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        print('Debug: Received empty response from Gemini API');
        return 'Unable to generate advice at this moment. Please try again.';
      }

      print('Debug: Successfully generated advice');
      return response.text!;
    } catch (e, stackTrace) {
      print('Error generating budget advice: $e');
      print('Stack trace: $stackTrace');
      return '''
Error generating advice. Please check:
1. Your internet connection
2. API key validity
3. Daily quota limits

Technical details: ${e.toString()}
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
      Create a budget-friendly meal plan considering:
      - Current weight: $currentWeight kg
      - Target weight: $targetWeight kg
      - Daily food budget: \$$dailyFoodBudget

      Provide a one-day sample meal plan that:
      1. Fits within the daily budget
      2. Supports the weight ${targetWeight > currentWeight ? 'gain' : 'loss'} goal
      3. Includes affordable, nutritious foods
      4. Lists estimated cost per meal

      Keep the response concise and practical.
      ''';

      print('Debug: Sending meal plan prompt to Gemini API');
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        print('Debug: Received empty meal plan response from Gemini API');
        return 'Unable to generate meal plan at this moment. Please try again.';
      }

      print('Debug: Successfully generated meal plan');
      return response.text!;
    } catch (e, stackTrace) {
      print('Error generating meal plan: $e');
      print('Stack trace: $stackTrace');
      return '''
Error generating meal plan. Please check:
1. Your internet connection
2. API key validity
3. Daily quota limits

Technical details: ${e.toString()}
''';
    }
  }
}