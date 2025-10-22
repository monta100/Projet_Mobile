import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/database_helper.dart';
import '../Services/user_service.dart';
import '../Entites/user_objective.dart';

class CoachDashboardScreen extends StatefulWidget {
  final Utilisateur coach;

  const CoachDashboardScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final UserService _userService = UserService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<Utilisateur> _clients = [];
  List<UserObjective> _objectives = [];
  Map<String, dynamic> _stats = {};
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
      // Charger les clients
      final clients = await _userService.obtenirClientsPourCoach(widget.coach.id!);
      
      // Charger les objectifs des clients
      final objectives = await _db.getUserObjectivesByCoach(widget.coach.id!);
      
      // Calculer les statistiques
      final stats = _calculateStats(clients, objectives);
      
      setState(() {
        _clients = clients;
        _objectives = objectives;
        _stats = stats;
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

  Map<String, dynamic> _calculateStats(List<Utilisateur> clients, List<UserObjective> objectives) {
    final activeObjectives = objectives.where((o) => !o.estAtteint).toList();
    final completedObjectives = objectives.where((o) => o.estAtteint).toList();
    final overdueObjectives = objectives.where((o) => o.estEnRetard).toList();
    
    return {
      'totalClients': clients.length,
      'activeObjectives': activeObjectives.length,
      'completedObjectives': completedObjectives.length,
      'overdueObjectives': overdueObjectives.length,
      'completionRate': objectives.isNotEmpty 
          ? (completedObjectives.length / objectives.length * 100).round()
          : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      const SizedBox(height: 30),
                      _buildStatsCards(),
                      const SizedBox(height: 30),
                      _buildQuickActions(),
                      const SizedBox(height: 30),
                      _buildRecentObjectives(),
                      const SizedBox(height: 30),
                      _buildClientsOverview(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
            Colors.indigo.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${widget.coach.prenom} !',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tableau de bord Coach',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.sports_gymnastics,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Clients',
            '${_stats['totalClients']}',
            Icons.people,
            Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Objectifs Actifs',
            '${_stats['activeObjectives']}',
            Icons.track_changes,
            Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Taux de Réussite',
            '${_stats['completionRate']}%',
            Icons.trending_up,
            Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques Détaillées',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDetailedStatCard(
                'Objectifs Atteints',
                '${_stats['completedObjectives']}',
                Icons.check_circle,
                Colors.green,
                'Objectifs complétés avec succès',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailedStatCard(
                'En Retard',
                '${_stats['overdueObjectives']}',
                Icons.warning,
                Colors.red,
                'Objectifs nécessitant une attention',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
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
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Voir Mes Clients',
                'Gérer vos clients',
                Icons.people,
                Colors.blue,
                () => _navigateToClients(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Objectifs Clients',
                'Suivre les objectifs',
                Icons.track_changes,
                Colors.orange,
                () => _navigateToObjectives(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Créer Programme',
                'Nouveau programme',
                Icons.add_circle,
                Colors.green,
                () => _navigateToPrograms(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Analyses',
                'Statistiques détaillées',
                Icons.analytics,
                Colors.purple,
                () => _navigateToAnalytics(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentObjectives() {
    final recentObjectives = _objectives.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Objectifs Récents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _navigateToObjectives,
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recentObjectives.isEmpty
            ? _buildEmptyObjectives()
            : Column(
                children: recentObjectives.map((objective) => _buildObjectiveCard(objective)).toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyObjectives() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.track_changes,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun objectif récent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vos clients n\'ont pas encore créé d\'objectifs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectiveCard(UserObjective objective) {
    final isCompleted = objective.estAtteint;
    final isOverdue = objective.estEnRetard;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.shade200 
              : isOverdue 
                  ? Colors.red.shade200 
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? Colors.green 
                  : isOverdue 
                      ? Colors.red 
                      : Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted 
                  ? Icons.check_circle 
                  : isOverdue 
                      ? Icons.warning 
                      : Icons.track_changes,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objective.typeObjectif,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${objective.poidsActuel}kg → ${objective.poidsCible}kg',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Durée: ${objective.dureeFormatted}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Atteint',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'En retard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClientsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes Clients',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _navigateToClients,
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _clients.isEmpty
            ? _buildEmptyClients()
            : Column(
                children: _clients.take(3).map((client) => _buildClientCard(client)).toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyClients() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.people,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun client',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de clients assignés',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(Utilisateur client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue,
            child: Text(
              client.prenom[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  client.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _viewClientDetails(client),
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }

  void _navigateToClients() {
    // Navigation vers l'écran des clients
    // Cette méthode sera implémentée dans le parent
  }

  void _navigateToObjectives() {
    // Navigation vers l'écran des objectifs
    // Cette méthode sera implémentée dans le parent
  }

  void _navigateToPrograms() {
    // Navigation vers l'écran des programmes
    // Cette méthode sera implémentée dans le parent
  }

  void _navigateToAnalytics() {
    // Navigation vers l'écran des analyses
    // Cette méthode sera implémentée dans le parent
  }

  void _viewClientDetails(Utilisateur client) {
    // Afficher les détails du client
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${client.prenom} ${client.nom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${client.email}'),
            const SizedBox(height: 8),
            Text('Rôle: ${client.role}'),
            const SizedBox(height: 8),
            Text('Coach ID: ${client.coachId ?? 'Non assigné'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
