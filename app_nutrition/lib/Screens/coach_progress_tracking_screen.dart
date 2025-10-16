import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Entites/exercise_session.dart';
import '../Services/exercise_service.dart';
import '../Services/database_helper.dart';

class CoachProgressTrackingScreen extends StatefulWidget {
  final int coachId;

  const CoachProgressTrackingScreen({
    Key? key,
    required this.coachId,
  }) : super(key: key);

  @override
  State<CoachProgressTrackingScreen> createState() => _CoachProgressTrackingScreenState();
}

class _CoachProgressTrackingScreenState extends State<CoachProgressTrackingScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Utilisateur> _clients = [];
  Map<int, List<ExerciseSession>> _clientSessions = {};
  Map<int, Map<String, dynamic>> _clientStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final clients = await _db.getClientsByCoach(widget.coachId);
      final clientSessions = <int, List<ExerciseSession>>{};
      final clientStats = <int, Map<String, dynamic>>{};
      
      for (final client in clients) {
        final sessions = await _exerciseService.getUserSessions(client.id!);
        final stats = await _exerciseService.getUserStats(client.id!);
        
        clientSessions[client.id!] = sessions;
        clientStats[client.id!] = stats;
      }
      
      setState(() {
        _clients = clients;
        _clientSessions = clientSessions;
        _clientStats = clientStats;
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text('Suivi des Progrès'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Statistiques globales
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: _buildGlobalStats(),
                    ),
                    // Liste des clients
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _clients.length,
                        itemBuilder: (context, index) {
                          final client = _clients[index];
                          final sessions = _clientSessions[client.id!] ?? [];
                          final stats = _clientStats[client.id!] ?? {};
                          return _buildClientProgressCard(client, sessions, stats);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun client à suivre',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les statistiques de progression de vos clients\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStats() {
    final totalClients = _clients.length;
    final totalSessions = _clientSessions.values
        .map((sessions) => sessions.where((s) => s.estTerminee).length)
        .fold(0, (sum, count) => sum + count);
    final totalCalories = _clientStats.values
        .map((stats) => (stats['totalCalories'] ?? 0) as int)
        .fold(0, (sum, calories) => sum + calories);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Clients actifs',
            '$totalClients',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Séances terminées',
            '$totalSessions',
            Icons.fitness_center,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Calories brûlées',
            '$totalCalories',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientProgressCard(
    Utilisateur client,
    List<ExerciseSession> sessions,
    Map<String, dynamic> stats,
  ) {
    final completedSessions = sessions.where((s) => s.estTerminee).toList();
    final recentSessions = completedSessions.take(5).toList();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du client
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    client.prenom[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        client.email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(completedSessions.isNotEmpty),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistiques du client
            Row(
              children: [
                Expanded(
                  child: _buildClientStatItem(
                    'Séances',
                    '${completedSessions.length}',
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildClientStatItem(
                    'Calories',
                    '${stats['totalCalories'] ?? 0}',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildClientStatItem(
                    'Durée',
                    '${stats['totalDuration'] ?? 0} min',
                    Icons.timer,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dernières séances
            if (recentSessions.isNotEmpty) ...[
              const Text(
                'Dernières séances',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...recentSessions.map((session) => _buildSessionItem(session)),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Aucune séance terminée',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool hasActivity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasActivity ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActivity ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Text(
        hasActivity ? 'Actif' : 'Inactif',
        style: TextStyle(
          color: hasActivity ? Colors.green : Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSessionItem(ExerciseSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
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
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                  Text(
                    '${session.dureeReelle ?? 0} min • ${session.caloriesBrulees ?? 0} cal',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
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
}
