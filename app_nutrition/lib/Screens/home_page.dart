import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import 'user_main_screen.dart';
import 'main_navigation_screen.dart';
import 'coach_main_screen.dart';

/// 🏠 Page d'accueil centrale qui permet de basculer entre les modules
class HomePage extends StatelessWidget {
  final Utilisateur utilisateur;

  const HomePage({Key? key, required this.utilisateur}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCoach = utilisateur.role.toLowerCase().trim() == 'coach' ||
        utilisateur.role.toLowerCase().trim() == 'coatch' ||
        utilisateur.role.toLowerCase().trim() == 'entraîneur' ||
        utilisateur.role.toLowerCase().trim() == 'entraineur' ||
        utilisateur.role.toLowerCase().trim() == 'trainer';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4CAF50),
              const Color(0xFF81C784),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar et bienvenue
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        isCoach ? Icons.sports : Icons.person,
                        size: 60,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Bienvenue ${utilisateur.prenom} !',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    utilisateur.email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Carte Module Utilisateur
                  if (!isCoach)
                    _buildModuleCard(
                      context,
                      title: 'Module Sportif',
                      subtitle: 'Exercices, progression & récompenses',
                      icon: Icons.fitness_center,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserMainScreen(utilisateur: utilisateur),
                          ),
                        );
                      },
                    ),

                  // Carte Module Coach
                  if (isCoach)
                    _buildModuleCard(
                      context,
                      title: 'Module Coach',
                      subtitle: 'Clients, programmes & suivi',
                      icon: Icons.sports,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CoachMainScreen(coach: utilisateur),
                          ),
                        );
                      },
                    ),

                  if (!isCoach) const SizedBox(height: 16),
                  if (isCoach) const SizedBox(height: 16),

                  // Carte Module Nutrition (pour tous)
                  _buildModuleCard(
                    context,
                    title: 'Module Nutrition',
                    subtitle: 'Repas, recettes & assistant IA',
                    icon: Icons.restaurant_menu,
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigationScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Bouton de déconnexion
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

