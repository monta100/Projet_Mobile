import 'package:flutter/material.dart';
import '../Entites/achievement.dart';
import '../Entites/user_achievement.dart';
import '../Services/exercise_service.dart';
import '../Services/database_helper.dart';

class UserAchievementsScreen extends StatefulWidget {
  final int utilisateurId;

  const UserAchievementsScreen({
    Key? key,
    required this.utilisateurId,
  }) : super(key: key);

  @override
  State<UserAchievementsScreen> createState() => _UserAchievementsScreenState();
}

class _UserAchievementsScreenState extends State<UserAchievementsScreen>
    with TickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Achievement> _achievements = [];
  List<UserAchievement> _userAchievements = [];
  Map<String, dynamic> _userStats = {};
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _loadAchievements();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _exerciseService.getUserStats(widget.utilisateurId);
      final achievements = await _getAllAchievements();
      final userAchievements = await _getUserAchievements();
      
      // Vérifier et débloquer de nouveaux achievements
      await _checkAndUnlockAchievements(stats);
      
      setState(() {
        _userStats = stats;
        _achievements = achievements;
        _userAchievements = userAchievements;
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

  Future<List<Achievement>> _getAllAchievements() async {
    // Pour l'instant, retournons des achievements prédéfinis
    return [
      Achievement(
        id: 1,
        nom: 'Premier Pas',
        description: 'Terminez votre première séance d\'entraînement',
        icone: '🚀',
        couleur: '#4CAF50',
        points: 10,
        type: 'workout',
        conditionValue: 1,
      ),
      Achievement(
        id: 2,
        nom: 'Débutant Confirmé',
        description: 'Terminez 5 séances d\'entraînement',
        icone: '💪',
        couleur: '#2196F3',
        points: 25,
        type: 'workout',
        conditionValue: 5,
      ),
      Achievement(
        id: 3,
        nom: 'Athlète',
        description: 'Terminez 15 séances d\'entraînement',
        icone: '🏆',
        couleur: '#FF9800',
        points: 50,
        type: 'workout',
        conditionValue: 15,
      ),
      Achievement(
        id: 4,
        nom: 'Champion',
        description: 'Terminez 30 séances d\'entraînement',
        icone: '👑',
        couleur: '#9C27B0',
        points: 100,
        type: 'workout',
        conditionValue: 30,
      ),
      Achievement(
        id: 5,
        nom: 'Brûleur de Calories',
        description: 'Brûlez 1000 calories au total',
        icone: '🔥',
        couleur: '#F44336',
        points: 30,
        type: 'calories',
        conditionValue: 1000,
      ),
      Achievement(
        id: 6,
        nom: 'Marathonien',
        description: 'Cumulez 300 minutes d\'entraînement',
        icone: '⏱️',
        couleur: '#00BCD4',
        points: 40,
        type: 'duration',
        conditionValue: 300,
      ),
      Achievement(
        id: 7,
        nom: 'Régularité',
        description: 'Entraînez-vous 3 jours consécutifs',
        icone: '📅',
        couleur: '#8BC34A',
        points: 35,
        type: 'streak',
        conditionValue: 3,
      ),
      Achievement(
        id: 8,
        nom: 'Détermination',
        description: 'Entraînez-vous 7 jours consécutifs',
        icone: '💎',
        couleur: '#E91E63',
        points: 75,
        type: 'streak',
        conditionValue: 7,
      ),
    ];
  }

  Future<List<UserAchievement>> _getUserAchievements() async {
    // Pour l'instant, retournons une liste vide
    // Dans une vraie app, on récupérerait depuis la base de données
    return [];
  }

  Future<void> _checkAndUnlockAchievements(Map<String, dynamic> stats) async {
    final totalSessions = stats['totalSessions'] ?? 0;
    final totalCalories = stats['totalCalories'] ?? 0;
    final totalDuration = stats['totalDuration'] ?? 0;
    
    for (final achievement in _achievements) {
      int currentValue = 0;
      
      switch (achievement.type) {
        case 'workout':
          currentValue = totalSessions;
          break;
        case 'calories':
          currentValue = totalCalories;
          break;
        case 'duration':
          currentValue = totalDuration;
          break;
        case 'streak':
          // Pour l'instant, on simule une streak
          currentValue = totalSessions > 0 ? 1 : 0;
          break;
      }
      
      if (achievement.canUnlock(currentValue)) {
        achievement.unlock();
        // Ici, on sauvegarderait l'achievement débloqué
        _showAchievementUnlocked(achievement);
      }
    }
  }

  void _showAchievementUnlocked(Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getColorFromHex(achievement.couleur).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                achievement.icone,
                style: const TextStyle(fontSize: 48),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Achievement Débloqué !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getColorFromHex(achievement.couleur),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.nom,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getColorFromHex(achievement.couleur),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${achievement.points} points',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getColorFromHex(achievement.couleur),
              foregroundColor: Colors.white,
            ),
            child: const Text('Génial !'),
          ),
        ],
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Récompenses'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAchievements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsHeader(),
                Expanded(
                  child: _buildAchievementsGrid(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader() {
    final totalPoints = _userAchievements.fold(0, (sum, ua) => sum + ua.pointsEarned);
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Points',
              '$totalPoints',
              Icons.stars,
              Colors.amber,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Achievements',
              '$unlockedCount/${_achievements.length}',
              Icons.emoji_events,
              Colors.orange,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Séances',
              '${_userStats['totalSessions'] ?? 0}',
              Icons.fitness_center,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _achievements.length,
        itemBuilder: (context, index) {
          final achievement = _achievements[index];
          return ScaleTransition(
            scale: _scaleAnimation,
            child: _buildAchievementCard(achievement),
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked 
              ? _getColorFromHex(achievement.couleur)
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnlocked 
                ? _getColorFromHex(achievement.couleur).withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? _getColorFromHex(achievement.couleur).withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                achievement.icone,
                style: TextStyle(
                  fontSize: 32,
                  color: isUnlocked ? null : Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              achievement.nom,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.black : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 12,
                color: isUnlocked ? Colors.grey.shade600 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? _getColorFromHex(achievement.couleur)
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${achievement.points} pts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
