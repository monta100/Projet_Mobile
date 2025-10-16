import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Services/database_helper.dart';
import '../Services/user_service.dart';
import '../Entites/user_objective.dart';
import 'create_user_objective_screen.dart';

class CoachClientsScreen extends StatefulWidget {
  final Utilisateur coach;

  const CoachClientsScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  State<CoachClientsScreen> createState() => _CoachClientsScreenState();
}

class _CoachClientsScreenState extends State<CoachClientsScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final UserService _userService = UserService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Utilisateur> _clients = [];
  Map<int, List<UserObjective>> _clientObjectives = {};
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
    
    _loadClientsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClientsData() async {
    setState(() => _isLoading = true);
    try {
      // Charger les clients
      final clients = await _userService.obtenirClientsPourCoach(widget.coach.id!);
      
      // Charger les objectifs pour chaque client
      final Map<int, List<UserObjective>> clientObjectives = {};
      for (final client in clients) {
        final objectives = await _db.getUserObjectives(client.id!);
        clientObjectives[client.id!] = objectives;
      }
      
      setState(() {
        _clients = clients;
        _clientObjectives = clientObjectives;
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mes Clients'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _clients.isEmpty
                  ? _buildEmptyClients()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          ..._clients.map((client) => _buildClientCard(client)).toList(),
                        ],
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
            Colors.green.shade400,
            Colors.green.shade600,
            Colors.teal.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_clients.length} Client${_clients.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Gérez vos clients et leurs objectifs',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClients() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun client',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de clients assignés.\nLes utilisateurs peuvent vous choisir comme coach lors de la création de leurs objectifs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(Utilisateur client) {
    final clientObjectives = _clientObjectives[client.id] ?? [];
    final activeObjectives = clientObjectives.where((o) => !o.estAtteint).toList();
    final completedObjectives = clientObjectives.where((o) => o.estAtteint).toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.green,
                child: Text(
                  client.prenom[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'create_objective',
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 20),
                        SizedBox(width: 8),
                        Text('Créer un objectif'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_details',
                    child: const Row(
                      children: [
                        Icon(Icons.info, size: 20),
                        SizedBox(width: 8),
                        Text('Voir détails'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'create_objective') {
                    _createObjectiveForClient(client);
                  } else if (value == 'view_details') {
                    _showClientDetails(client);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildClientStats(activeObjectives, completedObjectives),
          const SizedBox(height: 16),
          if (clientObjectives.isNotEmpty) ...[
            const Text(
              'Objectifs Récents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...clientObjectives.take(2).map((objective) => _buildClientObjectiveCard(objective)).toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.track_changes, color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun objectif défini',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _createObjectiveForClient(client),
                    child: const Text('Créer'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientStats(List<UserObjective> activeObjectives, List<UserObjective> completedObjectives) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Actifs',
            '${activeObjectives.length}',
            Colors.orange,
            Icons.track_changes,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Atteints',
            '${completedObjectives.length}',
            Colors.green,
            Icons.check_circle,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Total',
            '${activeObjectives.length + completedObjectives.length}',
            Colors.blue,
            Icons.analytics,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientObjectiveCard(UserObjective objective) {
    final isCompleted = objective.estAtteint;
    final isOverdue = objective.estEnRetard;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted 
            ? Colors.green.shade50 
            : isOverdue 
                ? Colors.red.shade50 
                : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.shade200 
              : isOverdue 
                  ? Colors.red.shade200 
                  : Colors.blue.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted 
                ? Icons.check_circle 
                : isOverdue 
                    ? Icons.warning 
                    : Icons.track_changes,
            color: isCompleted 
                ? Colors.green 
                : isOverdue 
                    ? Colors.red 
                    : Colors.blue,
            size: 20,
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

  void _createObjectiveForClient(Utilisateur client) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateUserObjectiveScreen(utilisateur: client),
      ),
    );
    
    if (result == true) {
      _loadClientsData();
    }
  }

  void _showClientDetails(Utilisateur client) {
    final clientObjectives = _clientObjectives[client.id] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green,
                      child: Text(
                        client.prenom[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${client.prenom} ${client.nom}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            client.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Text(
                      'Objectifs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (clientObjectives.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Aucun objectif défini',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ...clientObjectives.map((objective) => _buildDetailedObjectiveCard(objective)).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedObjectiveCard(UserObjective objective) {
    final isCompleted = objective.estAtteint;
    final isOverdue = objective.estEnRetard;
    final progress = objective.progressionPourcentage / 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.shade200 
              : isOverdue 
                  ? Colors.red.shade200 
                  : Colors.blue.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${objective.poidsActuel}kg → ${objective.poidsCible}kg',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted 
                        ? Colors.green 
                        : isOverdue 
                            ? Colors.red 
                            : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${objective.progressionPourcentage.toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IMC: ${objective.imcActuelFormatted} → ${objective.imcCibleFormatted}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (!isCompleted && !isOverdue)
                Text(
                  '${objective.joursRestants} jours restants',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
