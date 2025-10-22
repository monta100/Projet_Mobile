import 'package:flutter/material.dart';
import '../Entites/rappel.dart';
import '../Entites/utilisateur.dart';
import '../Services/rappel_service.dart';

class MesRappelsScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const MesRappelsScreen({Key? key, required this.utilisateur})
    : super(key: key);

  @override
  State<MesRappelsScreen> createState() => _MesRappelsScreenState();
}

class _MesRappelsScreenState extends State<MesRappelsScreen> {
  final RappelService _service = RappelService();

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes rappels'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Rappel>>(
          future: _service.obtenirRappelsByUtilisateur(widget.utilisateur.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final rappels = snapshot.data ?? [];
            if (rappels.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun rappel',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez un rappel pour être notifié.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                itemCount: rappels.length,
                itemBuilder: (context, index) {
                  final r = rappels[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(r.message),
                      subtitle: Text(
                        '${r.date.day}/${r.date.month}/${r.date.year} ${r.date.hour}:${r.date.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'supprimer') {
                            final ok = await _service.supprimerRappel(r.id!);
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rappel supprimé'),
                                ),
                              );
                              await _refresh();
                            }
                          } else if (v == 'lu') {
                            final ok = await _service.marquerCommeLu(r.id!);
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marqué comme lu'),
                                ),
                              );
                              await _refresh();
                            }
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'lu',
                            child: Text('Marquer comme lu'),
                          ),
                          const PopupMenuItem(
                            value: 'supprimer',
                            child: Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/rappels/nouveau',
            arguments: widget.utilisateur,
          ).then((v) {
            if (v == true) _refresh();
          });
        },
        child: const Icon(Icons.add_alarm),
      ),
    );
  }
}
