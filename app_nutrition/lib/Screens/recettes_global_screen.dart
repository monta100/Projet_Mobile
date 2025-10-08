import 'package:flutter/material.dart';
import '../Entites/recette.dart';
import '../Services/recette_service.dart';

class RecettesGlobalScreen extends StatefulWidget {
  const RecettesGlobalScreen({super.key});

  @override
  State<RecettesGlobalScreen> createState() => _RecettesGlobalScreenState();
}

class _RecettesGlobalScreenState extends State<RecettesGlobalScreen> {
  final RecetteService _recetteService = RecetteService();
  late Future<List<Recette>> _future; // always published only now

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _recetteService.getPublishedRecettes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recettes Publiées')),
      body: FutureBuilder<List<Recette>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = (snapshot.data ?? []); // déjà filtré publié
          if (list.isEmpty) {
            return const Center(child: Text('Aucune recette'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(r.nom),
                  subtitle: Text('${r.calories.toStringAsFixed(0)} kcal'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
