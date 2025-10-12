// ignore_for_file: use_super_parameters, library_private_types_in_public_api, unused_element, unused_field

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../Services/openrouter_service.dart';
import '../Theme/app_colors.dart' as theme_colors;
import '../Services/nutribot_brain.dart';
import '../Widgets/recipe_card.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  final OpenRouterService _openRouter = OpenRouterService();
  final NutriBotBrain _brain = NutriBotBrain();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeaking = false;
  bool _isTyping = false;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _greetUser();
    _initVoice();

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
      _messages.add({"sender": "user", "text": text});
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
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 12, bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(),
              const SizedBox(width: 4),
              _dot(delay: 200),
              const SizedBox(width: 4),
              _dot(delay: 400),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot({int delay = 0}) {
    return FadeInUp(
      duration: Duration(milliseconds: 400),
      delay: Duration(milliseconds: delay),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
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
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(_isSpeaking ? opacity : 0),
                  blurRadius: _isSpeaking ? 20 : 0,
                  spreadRadius: _isSpeaking ? 6 : 0,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: IconButton(
          tooltip: "Faire parler Snacky",
          icon: Icon(
            _isSpeaking ? Icons.graphic_eq_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 26,
          ),
          onPressed: _simulateVoice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: theme_colors.AppColors.primaryColor,
        elevation: 0,
        title: Row(
          children: const [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text("🍊", style: TextStyle(fontSize: 20)),
            ),
            SizedBox(width: 10),
            Text(
              "Snacky",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: _buildAnimatedHalo(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }

                final msg = _messages[index];
                final isUser = msg["sender"] == "user";

                // Check for special recipe card message
                if (msg["sender"] == "bot" &&
                    msg["text"]!.startsWith("RECIPE_CARD::")) {
                  final jsonString = msg["text"]!.replaceFirst(
                    "RECIPE_CARD::",
                    "",
                  );
                  final recipeData = jsonDecode(jsonString);
                  return FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    child: RecipeCard(recipeData: recipeData),
                  );
                }

                final bgColor = isUser
                    ? theme_colors.AppColors.primaryColor
                    : Colors.white;
                final textColor = isUser ? Colors.white : Colors.black87;

                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 2),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Text("🍊", style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 2,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isUser ? 20 : 0),
                              bottomRight: Radius.circular(isUser ? 0 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(2, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            msg["text"] ?? "",
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                      if (isUser)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 2),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                theme_colors.AppColors.primaryColor,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 22,
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
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.lightbulb_outline,
                      color: Colors.orange.shade400,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Dis quelque chose à Snacky 🍊",
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
