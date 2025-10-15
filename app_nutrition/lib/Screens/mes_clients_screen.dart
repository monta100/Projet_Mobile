import 'dart:io';
import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/user_service.dart';
import '../Routs/app_routes.dart';
import 'chat_screen.dart';

class MesClientsScreen extends StatefulWidget {
  final Utilisateur coach;
  const MesClientsScreen({Key? key, required this.coach}) : super(key: key);

  @override
  State<MesClientsScreen> createState() => _MesClientsScreenState();
}

class _MesClientsScreenState extends State<MesClientsScreen> {
  final UserService _userService = UserService();
  List<Utilisateur> _clients = [];
  bool _loading = true;

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _loading = true);
    final clients = await _userService.obtenirClientsPourCoach(
      widget.coach.id!,
    );
    setState(() {
      _clients = clients;
      _loading = false;
    });
  }

  Future<void> _assignClientByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final users = await _userService.obtenirTousLesUtilisateurs();
    Utilisateur? found;
    try {
      found = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      found = null;
    }

    if (found == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun utilisateur trouvé pour cet email'),
          ),
        );
      }
      return;
    }

    final success = await _userService.assignerClientAuCoach(
      found.id!,
      widget.coach.id!,
    );
    if (success) {
      _emailController.clear();
      await _loadClients();
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client assigné avec succès')),
        );
    } else {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec lors de l\'assignation')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes clients')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email du client',
                      hintText: 'ex: client@exemple.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _assignClientByEmail,
                  child: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadClients,
                      child: _clients.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 60),
                                Center(
                                  child: Text('Aucun client pour le moment'),
                                ),
                              ],
                            )
                          : ListView.builder(
                              itemCount: _clients.length,
                              itemBuilder: (context, index) {
                                final client = _clients[index];
                                return Card(
                                  child: ListTile(
                                    leading:
                                        client.avatarPath != null &&
                                            client.avatarPath!.isNotEmpty
                                        ? CircleAvatar(
                                            backgroundImage: FileImage(
                                              File(client.avatarPath!),
                                            ),
                                          )
                                        : CircleAvatar(
                                            child: Text(
                                              '${client.prenom.isNotEmpty ? client.prenom[0] : ''}${client.nom.isNotEmpty ? client.nom[0] : ''}',
                                            ),
                                          ),
                                    title: Text(
                                      '${client.prenom} ${client.nom}',
                                    ),
                                    subtitle: Text(client.email),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'profil') {
                                          await Navigator.pushNamed(
                                            context,
                                            AppRoutes.profil,
                                            arguments: client,
                                          );
                                          await _loadClients();
                                        } else if (value == 'chat') {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (ctx) => ChatScreen(
                                                currentUser: widget.coach,
                                                otherUser: client,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'profil',
                                          child: Text('Voir le profil'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'chat',
                                          child: Text('Chat'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
