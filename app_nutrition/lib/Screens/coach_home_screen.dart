import 'dart:io';
import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/user_service.dart';
import '../Routs/app_routes.dart';
import '../Services/message_service.dart';
import '../Entites/message.dart';
import 'chat_screen.dart';
import 'coach_plans_screen.dart';
import 'exercise_library_screen.dart';
import 'coach_progress_tracking_screen.dart';

class CoachHomeScreen extends StatefulWidget {
  final Utilisateur coach;
  const CoachHomeScreen({Key? key, required this.coach}) : super(key: key);

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  final UserService _userService = UserService();
  List<Utilisateur> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    if (widget.coach.id != null) {
      final clients = await _userService.obtenirClientsPourCoach(
        widget.coach.id!,
      );
      setState(() {
        _clients = clients;
        _loading = false;
      });
    } else {
      setState(() {
        _clients = [];
        _loading = false;
      });
    }
  }

  Future<void> _showShareExerciseDialog(Utilisateur client) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Partager un exercice'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Décris l\'exercice à partager...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Partager'),
          ),
        ],
      ),
    );

    if (result == true) {
      final text = controller.text.trim();
      if (text.isEmpty) return;
      // Persist the shared exercise as a message of type 'exercise'
      final msgService = MessageService();
      final created = await msgService.sendMessage(
        Message(
          senderId: widget.coach.id!,
          receiverId: client.id!,
          content: text,
          type: 'exercise',
        ),
      );
      if (created > 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercice partagé et enregistré')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec lors de l\'enregistrement de l\'exercice'),
            ),
          );
        }
      }
    }
  }

  Widget _buildClientCard(Utilisateur client) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            client.avatarPath != null && client.avatarPath!.isNotEmpty
                ? CircleAvatar(
                    radius: 30,
                    backgroundImage: FileImage(File(client.avatarPath!)),
                  )
                : CircleAvatar(
                    radius: 30,
                    child: Text(
                      '${client.prenom.isNotEmpty ? client.prenom[0] : ''}${client.nom.isNotEmpty ? client.nom[0] : ''}',
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${client.prenom} ${client.nom}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Placeholder progression for MVP
                  Row(
                    children: [
                      Expanded(child: LinearProgressIndicator(value: 0.3)),
                      const SizedBox(width: 8),
                      const Text('30%'),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'profil':
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.profil,
                      arguments: client,
                    );
                    await _loadClients();
                    break;
                  case 'chat':
                    // Open chat between coach and client
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ChatScreen(
                          currentUser: widget.coach,
                          otherUser: client,
                        ),
                      ),
                    );
                    break;
                  case 'partager':
                    await _showShareExerciseDialog(client);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'profil',
                  child: Text('Voir le profil'),
                ),
                const PopupMenuItem(value: 'chat', child: Text('Chat')),
                const PopupMenuItem(
                  value: 'partager',
                  child: Text('Partager un exercice'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Coach'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.mesClients,
                arguments: widget.coach,
              );
            },
            tooltip: 'Voir tous mes clients',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, size: 40, color: Colors.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, ${widget.coach.prenom}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gérez vos clients, suivez leurs progrès et partagez des exercices.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Exercise management section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fitness_center, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Gestion des Exercices',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Créez des plans d\'exercices personnalisés et assignez-les à vos clients.',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoachPlansScreen(coachId: widget.coach.id!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Mes Plans'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseLibraryScreen(coachId: widget.coach.id!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.library_books),
                          label: const Text('Bibliothèque'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade600,
                            side: BorderSide(color: Colors.blue.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CoachProgressTrackingScreen(coachId: widget.coach.id!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics),
                      label: const Text('Suivi des Progrès'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Clients list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _clients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text('Aucun client associé pour le moment'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadClients,
                      child: ListView.separated(
                        itemCount: _clients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _buildClientCard(_clients[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
