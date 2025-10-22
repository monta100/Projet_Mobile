import 'package:flutter/material.dart';
import 'dart:io';
import '../Entites/utilisateur.dart';
import '../Services/exercise_service.dart';
import '../Services/database_helper.dart';
import 'user_exercise_programs_screen.dart';
import 'profil_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserDashboardScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with TickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  final DatabaseHelper _db = DatabaseHelper();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Map<String, dynamic> _userStats = {};
  List<dynamic> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _exerciseService.getUserStats(widget.utilisateur.id!);
      final sessions = await _exerciseService.getUserSessions(widget.utilisateur.id!);
      final recentSessions = sessions.take(5).toList();
      
      setState(() {
        _userStats = stats;
        _recentSessions = recentSessions;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildQuickStats(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildRecentActivity(),
                          const SizedBox(height: 24),
                          _buildMotivationalCard(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilScreen(utilisateur: widget.utilisateur),
              ),
            );
            // Rafraîchir l'écran si des modifications ont été apportées
            if (result == true) {
              setState(() {
                // L'état sera mis à jour automatiquement
              });
            }
          },
          child: _buildAvatar(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, ${widget.utilisateur.prenom} ! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Prêt pour votre séance d\'aujourd\'hui ?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _loadDashboardData,
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Séances',
            '${_userStats['totalSessions'] ?? 0}',
            Icons.fitness_center,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Calories',
            '${_userStats['totalCalories'] ?? 0}',
            Icons.local_fire_department,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Durée',
            '${_userStats['totalDuration'] ?? 0} min',
            Icons.timer,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Commencer l\'entraînement',
                'Démarrez votre séance',
                Icons.play_arrow,
                Colors.green,
                () => _startWorkout(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Mes Programmes',
                'Voir tous les plans',
                Icons.list_alt,
                Colors.blue,
                () => _viewPrograms(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité Récente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _recentSessions.isEmpty
              ? Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune séance récente',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Commencez votre première séance !',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: _recentSessions.map((session) => _buildSessionItem(session)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSessionItem(dynamic session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Séance terminée',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${session.dureeReelle ?? 0} min • ${session.caloriesBrulees ?? 0} cal',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(session.dateFin ?? DateTime.now()),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalCard() {
    final sessions = _userStats['totalSessions'] ?? 0;
    String message = '';
    String emoji = '';
    
    if (sessions == 0) {
      message = 'Commencez votre parcours fitness dès aujourd\'hui !';
      emoji = '🚀';
    } else if (sessions < 5) {
      message = 'Excellent début ! Continuez sur cette lancée.';
      emoji = '💪';
    } else if (sessions < 15) {
      message = 'Vous êtes sur la bonne voie ! Félicitations.';
      emoji = '🎉';
    } else {
      message = 'Vous êtes un vrai champion ! Inspirant !';
      emoji = '🏆';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.pink.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motivation du jour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _startWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserExerciseProgramsScreen(
          utilisateurId: widget.utilisateur.id!,
        ),
      ),
    );
  }

  void _viewPrograms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserExerciseProgramsScreen(
          utilisateurId: widget.utilisateur.id!,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Si l'utilisateur a une photo de profil, l'afficher
    if (widget.utilisateur.avatarPath != null && 
        widget.utilisateur.avatarPath!.isNotEmpty) {
      final file = File(widget.utilisateur.avatarPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white.withOpacity(0.2),
          backgroundImage: FileImage(file),
        );
      }
    }

    // Sinon, afficher les initiales avec couleur personnalisée
    final initials = widget.utilisateur.prenom.isNotEmpty 
        ? widget.utilisateur.prenom[0].toUpperCase()
        : 'U';
    
    Color avatarColor = Colors.white.withOpacity(0.2);
    
    // Si l'utilisateur a une couleur personnalisée, l'utiliser
    if (widget.utilisateur.avatarColor != null && 
        widget.utilisateur.avatarColor!.isNotEmpty) {
      try {
        avatarColor = Color(int.parse('0xff' + 
            widget.utilisateur.avatarColor!.replaceFirst('#', '')));
      } catch (e) {
        // En cas d'erreur, utiliser la couleur par défaut
        avatarColor = Colors.white.withOpacity(0.2);
      }
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: avatarColor,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
