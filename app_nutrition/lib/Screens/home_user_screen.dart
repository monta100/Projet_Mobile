import 'package:flutter/material.dart';
import 'dart:io';
import '../Entites/utilisateur.dart';
import '../Routs/app_routes.dart';

class HomeUserScreen extends StatelessWidget {
  final Utilisateur utilisateur;
  const HomeUserScreen({Key? key, required this.utilisateur}) : super(key: key);

  Widget _buildSmallAvatar(BuildContext context) {
    if (utilisateur.avatarPath != null && utilisateur.avatarPath!.isNotEmpty) {
      final file = File(utilisateur.avatarPath!);
      if (file.existsSync())
        return CircleAvatar(radius: 18, backgroundImage: FileImage(file));
    }
    final initials =
        (utilisateur.avatarInitials != null &&
            utilisateur.avatarInitials!.isNotEmpty)
        ? utilisateur.avatarInitials!.toUpperCase()
        : ((utilisateur.prenom.isNotEmpty ? utilisateur.prenom[0] : '') +
                  (utilisateur.nom.isNotEmpty ? utilisateur.nom[0] : ''))
              .toUpperCase();
    return CircleAvatar(
      radius: 18,
      child: Text(initials, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.profil,
              arguments: utilisateur,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildSmallAvatar(context),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${utilisateur.prenom}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bienvenue sur votre espace personnel',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vos activités récentes',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              itemCount: 6,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (ctx, idx) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text('A${idx + 1}'),
                                  ),
                                  title: Text('Activité ${idx + 1}'),
                                  subtitle: const Text('Il y a 1 jour'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: () {},
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
