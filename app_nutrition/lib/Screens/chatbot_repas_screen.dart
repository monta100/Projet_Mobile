// ignore_for_file: use_super_parameters, library_private_types_in_public_api, unused_element

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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _greetUser();
  }

  /// 👋 Message d’accueil personnalisé
  Future<void> _greetUser() async {
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _messages.add({
        "sender": "bot",
        "text":
            "👋 Coucou ! Moi c’est **Snacky 🍊**, ton compagnon de cuisine et de bien-être 🥗.\nJe peux te proposer des repas, t’écrire des recettes, ou juste papoter 😄.\nAlors, on cuisine quoi aujourd’hui ? 👨‍🍳",
      });
    });
  }

  /// 💬 Envoi de message utilisateur
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _controller.clear();
      _isLoading = true;
    });

    // Scroll vers le bas
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    final response = await _brain.process(text);

    setState(() {
      _messages.add({"sender": "bot", "text": response});
      _isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 150,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
                fontSize: 18,
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";

                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: isUser ? 40 : 8,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUser
                            ? theme_colors.AppColors.primaryColor
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(
                            isUser ? 20 : 0,
                          ), // bulle arrondie
                          bottomRight: Radius.circular(
                            isUser ? 0 : 20,
                          ), // inverse
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        msg["text"] ?? "",
                        style: TextStyle(
                          fontSize: 16,
                          color: isUser ? Colors.white : Colors.black87,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loader de réflexion Snacky
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Snacky réfléchit à une idée délicieuse... 🍳",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Champ d'entrée
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
