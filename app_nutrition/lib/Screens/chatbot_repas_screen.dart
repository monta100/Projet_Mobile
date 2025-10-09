// ignore_for_file: use_super_parameters, library_private_types_in_public_api, unused_element, unused_field

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../Services/openrouter_service.dart';
import '../Theme/app_colors.dart' as theme_colors;
import '../Services/nutribot_brain.dart';

class ChatbotRepasScreen extends StatefulWidget {
  const ChatbotRepasScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotRepasScreen> createState() => _ChatbotRepasScreenState();
}

class _ChatbotRepasScreenState extends State<ChatbotRepasScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  final OpenRouterService _openRouter = OpenRouterService();
  final NutriBotBrain _brain = NutriBotBrain();

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _greetUser();
  }

  /// 👋 Message d’accueil Snacky
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

  /// 💬 Envoi d’un message utilisateur
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _controller.clear();
      _isTyping = true;
    });

    // Scroll vers le bas
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

  /// 🎨 Bulle animée de “Snacky écrit...”
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
                final bgColor = isUser
                    ? theme_colors.AppColors.primaryColor
                    : Colors.white;
                final textColor = isUser ? Colors.white : Colors.black87;

                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: isUser ? 40 : 8,
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
