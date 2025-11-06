// ignore_for_file: use_super_parameters, library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import '../Theme/app_colors.dart' as theme_colors;
import '../Services/nutribot_brain.dart';
import '../Widgets/recipe_card.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotRepasScreen extends StatefulWidget {
  const ChatbotRepasScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotRepasScreen> createState() => _ChatbotRepasScreenState();
}

class _ChatbotRepasScreenState extends State<ChatbotRepasScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  final NutriBotBrain _brain = NutriBotBrain();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeaking = false;
  bool _isTyping = false;
  bool _showGuide = false; // Indicateur pour afficher le guide

  late AnimationController _waveController;

  final List<String> _examplePrompts = [
    "Donner une recette de burger",
    "Bienfaits des carottes ? 🥕",
    "Idée de plat sucré 🍰",
    "J'ai mangé une salade ce midi",
    "J'ai du poulet et du riz",
    "Quels repas pour demain ?",
  ];

  @override
  void initState() {
    super.initState();
    _greetUser();
    _initVoice();
    _checkFirstLaunch();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initVoice() async {
    // 🔊 Langue & tonalité
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setPitch(1.1); // ton un peu plus enjoué
    await _flutterTts.setSpeechRate(0.6); // plus lent et fluide
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    // 🔄 États (animation du micro)
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _simulateVoice() async {
    await _flutterTts.stop();
    await _flutterTts.speak(
      "Hey salut toi 👋 ! "
      "Moi, c’est Snacky, ton coach nutrition et bonne humeur 🍊. "
      "Je suis là pour t’aider à bien manger, à te sentir au top, "
      "et à rendre chaque repas un vrai moment de plaisir 😋. "
      "Alors dis-moi… tu veux une idée de plat équilibré, ou une recette gourmande aujourd’hui ? 👨‍🍳",
    );
  }

  Future<void> _greetUser() async {
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _messages.add({
        "sender": "bot",
        "text":
            "👋 Salut ! Moi c’est **Snacky 🍊**, ton pote nutrition et cuisine 😄.\nJe peux te proposer des repas, t’écrire des recettes, ou juste discuter un peu 🍵.\nAlors, tu veux cuisiner ou manger quoi aujourd’hui ? 👨‍🍳",
      });
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        "sender": "user",
        "text": text,
        "id": DateTime.now().toString(),
      });
      _controller.clear();
      _isTyping = true;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });

    final response = await _brain.process(text);

    if (response.startsWith("RECIPE_CARD::")) {
      try {
        final jsonString = response.replaceFirst("RECIPE_CARD::", "");
        final recipeData = jsonDecode(jsonString);

        if (recipeData is Map<String, dynamic> && recipeData.isNotEmpty) {
          setState(() {
            _isTyping = false;
            _messages.add({
              "sender": "bot",
              "text": response,
              "id": DateTime.now().toString(),
            });
          });
        } else {
          throw Exception("Données de recette invalides");
        }
      } catch (e) {
        setState(() {
          _isTyping = false;
          _messages.add({
            "sender": "bot",
            "text":
                "Désolé, je n'ai pas pu charger la recette. Réessayez plus tard.",
            "id": DateTime.now().toString(),
          });
        });
      }
    } else {
      setState(() {
        _isTyping = false;
        _messages.add({
          "sender": "bot",
          "text": response,
          "id": DateTime.now().toString(),
        });
      });
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      setState(() => _showGuide = true);
      await prefs.setBool('isFirstLaunch', false);
    }
  }

  void _toggleGuide() {
    setState(() => _showGuide = !_showGuide);
  }

  Widget _buildGuideOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: FadeIn(
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Bienvenue sur Snacky 🍊",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Votre assistant personnel pour une meilleure nutrition.\n"
                    "Posez des questions, demandez des recettes et suivez vos repas.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _toggleGuide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme_colors.AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "C'est parti !",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 12, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(),
              const SizedBox(width: 5),
              _dot(delay: 200),
              const SizedBox(width: 5),
              _dot(delay: 400),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot({int delay = 0}) {
    return FadeInUp(
      from: 3,
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: delay),
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: theme_colors.AppColors.primaryColor.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// 🌊 Halo animé autour du micro
  Widget _buildAnimatedHalo() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final scale = 1 + 0.2 * math.sin(_waveController.value * 2 * math.pi);
        final opacity =
            0.4 + 0.3 * math.sin(_waveController.value * 2 * math.pi);
        return Transform.scale(
          scale: _isSpeaking ? scale : 1.0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme_colors.AppColors.primaryColor.withOpacity(
                    _isSpeaking ? opacity : 0,
                  ),
                  blurRadius: _isSpeaking ? 20 : 0,
                  spreadRadius: _isSpeaking ? 6 : 0,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: IconButton(
        tooltip: "Faire parler Snacky",
        icon: Icon(
          _isSpeaking ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
          color: const Color(0xFF4A4A4A),
          size: 26,
        ),
        onPressed: _simulateVoice,
      ),
    );
  }

  Widget _buildExamplePrompts() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: const Color(0xFFFDF8F4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: _examplePrompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: GestureDetector(
                onTap: () {
                  _controller.text = prompt;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme_colors.AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        toolbarHeight: 70,
        title: Row(
          children: const [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFFFF0E5),
              child: Text("🍊", style: TextStyle(fontSize: 22)),
            ),
            SizedBox(width: 12),
            Text(
              "Snacky",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: Color(0xFF4A4A4A),
              size: 24,
            ),
            tooltip: "Guide",
            onPressed: _toggleGuide,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _buildAnimatedHalo(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🟧 Contenu principal du chat (sans RefreshIndicator)
          Column(
            children: [
              _buildExamplePrompts(), // 🌟 Barre d'exemples de prompts
              Expanded(
                child: ListView.builder(
                  key: ValueKey(_messages.length),
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _messages.length) {
                      return _buildTypingIndicator();
                    }

                    final msg = _messages[index];
                    final isUser = msg["sender"] == "user";

                    // 🧩 Cas spécial : carte de recette
                    if (msg["sender"] == "bot" &&
                        msg["text"]!.startsWith("RECIPE_CARD::")) {
                      final jsonString = msg["text"]!.replaceFirst(
                        "RECIPE_CARD::",
                        "",
                      );
                      final recipeData = jsonDecode(jsonString);
                      recipeData["description"] ??=
                          "Description non disponible.";

                      return FadeInUp(
                        key: ValueKey(msg["id"]),
                        duration: const Duration(milliseconds: 300),
                        child: RecipeCard(recipeData: recipeData),
                      );
                    }

                    final bgColor = isUser
                        ? theme_colors.AppColors.primaryColor
                        : Colors.white;
                    final textColor = isUser ? Colors.white : Colors.black87;
                    final radius = BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isUser ? 22 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 22),
                    );

                    return FadeInUp(
                      key: ValueKey(msg["id"]),
                      duration: const Duration(milliseconds: 350),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isUser)
                            const Padding(
                              padding: EdgeInsets.only(right: 10.0, bottom: 4),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFFFFF0E5),
                                child: Text(
                                  "🍊",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: radius,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                msg["text"] ?? "",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 💬 Champ d’entrée utilisateur
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.lightbulb_outline,
                          color: theme_colors.AppColors.primaryColor,
                          size: 26,
                        ),
                        tooltip: "Idée de plat",
                        onPressed: () async {
                          setState(() {
                            _isTyping = true;
                          });
                          final response = await _brain.process(
                            "suggestion de plat",
                          );
                          setState(() {
                            _isTyping = false;
                            _messages.add({"sender": "bot", "text": response});
                          });
                          Future.delayed(const Duration(milliseconds: 200), () {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent + 200,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            );
                          });
                        },
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "Dis quelque chose à Snacky...",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: theme_colors.AppColors.primaryColor,
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 🟣 Guide d’accueil (overlay)
          if (_showGuide) _buildGuideOverlay(),
        ],
      ),
    );
  }
}
