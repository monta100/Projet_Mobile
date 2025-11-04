import 'package:flutter/material.dart';

import '../Entites/message.dart';
import '../Entites/utilisateur.dart';
import '../Services/message_service.dart';

class ChatScreen extends StatefulWidget {
  final Utilisateur currentUser;
  final Utilisateur otherUser;

  const ChatScreen({
    Key? key,
    required this.currentUser,
    required this.otherUser,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _service = MessageService();
  final TextEditingController _controller = TextEditingController();
  List<Message> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final msgs = await _service.fetchConversation(
      widget.currentUser.id!,
      widget.otherUser.id!,
    );
    setState(() {
      _messages = msgs;
      _loading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final msg = Message(
      senderId: widget.currentUser.id!,
      receiverId: widget.otherUser.id!,
      content: text,
      type: 'message',
    );
    final id = await _service.sendMessage(msg);
    if (id > 0) {
      _controller.clear();
      await _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.chat_bubble_outline),
            const SizedBox(width: 8),
            Text('${widget.otherUser.prenom} ${widget.otherUser.nom}'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isMe = m.senderId == widget.currentUser.id;
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.blueAccent
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.content,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${m.createdAt.toLocal()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    child: const Icon(Icons.send),
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
