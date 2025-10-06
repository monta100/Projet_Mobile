import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Entites/objectif.dart';
import '../Entites/rappel.dart';
import '../Services/user_service.dart';
import '../Services/objectif_service.dart';
import '../Services/rappel_service.dart';

class TestDatabaseScreen extends StatefulWidget {
  const TestDatabaseScreen({Key? key}) : super(key: key);

  @override
  State<TestDatabaseScreen> createState() => _TestDatabaseScreenState();
}

class _TestDatabaseScreenState extends State<TestDatabaseScreen> {
  final UserService _userService = UserService();
  final ObjectifService _objectifService = ObjectifService();
  final RappelService _rappelService = RappelService();
  
  String _resultats = '';

  Future<void> _testerDatabase() async {
    setState(() {
      _resultats = 'Test en cours...\n';
    });

    try {
      // Test Utilisateur
      final utilisateur = Utilisateur(
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean.dupont@test.com',
        motDePasse: 'Test123!',
        role: 'Utilisateur',
      );
      
      final userId = await _userService.creerUtilisateur(utilisateur);
      _ajouterResultat('✅ Utilisateur créé avec ID: $userId');

      // Test Objectif
      final objectif = Objectif(
        type: 'Perte de poids',
        valeurCible: 5.0,
        dateFixee: DateTime.now().add(const Duration(days: 30)),
      );
      
      final objectifId = await _objectifService.creerObjectif(objectif);
      _ajouterResultat('✅ Objectif créé avec ID: $objectifId');

      // Test Rappel
      final rappel = Rappel(
        message: 'Boire un verre d\'eau',
        date: DateTime.now().add(const Duration(hours: 1)),
      );
      
      final rappelId = await _rappelService.creerRappel(rappel);
      _ajouterResultat('✅ Rappel créé avec ID: $rappelId');

      // Récupération et affichage
      final utilisateurs = await _userService.obtenirTousLesUtilisateurs();
      _ajouterResultat('📋 Nombre d\'utilisateurs: ${utilisateurs.length}');

      final objectifs = await _objectifService.obtenirTousLesObjectifs();
      _ajouterResultat('🎯 Nombre d\'objectifs: ${objectifs.length}');

      final rappels = await _rappelService.obtenirTousLesRappels();
      _ajouterResultat('🔔 Nombre de rappels: ${rappels.length}');

      _ajouterResultat('\n✅ Test terminé avec succès !');

    } catch (e) {
      _ajouterResultat('❌ Erreur: $e');
    }
  }

  void _ajouterResultat(String message) {
    setState(() {
      _resultats += '$message\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Base de Données'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testerDatabase,
              child: const Text('Tester la Base de Données'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _resultats.isEmpty ? 'Aucun test exécuté' : _resultats,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}