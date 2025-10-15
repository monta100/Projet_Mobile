import 'package:flutter/material.dart';
import '../Entites/objectif.dart';
import '../Entites/utilisateur.dart';
import '../Services/objectif_service.dart';
import '../Routs/app_routes.dart';
import 'nouveau_objectif_screen.dart';

class MesObjectifsScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const MesObjectifsScreen({Key? key, required this.utilisateur})
    : super(key: key);

  @override
  State<MesObjectifsScreen> createState() => _MesObjectifsScreenState();
}

class _MesObjectifsScreenState extends State<MesObjectifsScreen> {
  final ObjectifService _service = ObjectifService();

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes objectifs'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.objectifsNouveau,
            arguments: widget.utilisateur,
          );
          if (result == true) {
            await _refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Objectif>>(
          future: _service.obtenirObjectifsParUtilisateur(
            widget.utilisateur.id!,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final objectifs = snapshot.data ?? [];
            if (objectifs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun objectif',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Appuyez sur + pour en créer un.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                itemCount: objectifs.length,
                itemBuilder: (context, index) {
                  final obj = objectifs[index];
                  final double percent = obj.valeurCible == 0.0
                      ? 0.0
                      : (obj.progression / obj.valeurCible).toDouble();
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        obj.type,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cible: ${obj.valeurCible}'),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Date limite: ${obj.dateFixee.day}/${obj.dateFixee.month}/${obj.dateFixee.year}',
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            // Open NouveauObjectifScreen in edit mode
                            // We actually need to open with initial objective - use modal push directly
                            // Fallback: open the screen manually
                            final edited = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => NouveauObjectifScreen(
                                  utilisateur: widget.utilisateur,
                                  initial: obj,
                                ),
                              ),
                            );
                            if (edited == true) await _refresh();
                          } else if (v == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Supprimer l\'objectif'),
                                content: const Text(
                                  'Voulez-vous supprimer cet objectif ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              final ok = await _service.supprimerObjectif(
                                obj.id!,
                              );
                              if (ok && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Objectif supprimé'),
                                  ),
                                );
                                await _refresh();
                              }
                            }
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Modifier'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
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
    );
  }
}
