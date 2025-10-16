import 'package:flutter/material.dart';
import '../Entites/utilisateur.dart';
import '../Entites/rappel.dart';
import '../Services/database_helper.dart';
import '../Services/rappel_service.dart';

class UserRemindersScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const UserRemindersScreen({
    Key? key,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<UserRemindersScreen> createState() => _UserRemindersScreenState();
}

class _UserRemindersScreenState extends State<UserRemindersScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final RappelService _rappelService = RappelService();
  
  List<Rappel> _rappels = [];
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadRappels();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRappels() async {
    setState(() => _isLoading = true);
    try {
      final rappels = await _db.getRappelsByUtilisateur(widget.utilisateur.id!);
      setState(() {
        _rappels = rappels;
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
      appBar: AppBar(
        title: const Text('Mes Rappels'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddReminderDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRappels,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildRemindersOverview(),
                  Expanded(
                    child: _buildRemindersList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRemindersOverview() {
    final activeRappels = _rappels.where((r) => !r.statut).toList();
    final completedRappels = _rappels.where((r) => r.statut).toList();
    final overdueRappels = _rappels.where((r) => 
      !r.statut && DateTime.now().isAfter(r.date)
    ).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.purple.shade600,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewStat(
              'Actifs',
              '${activeRappels.length}',
              Icons.schedule,
              Colors.white,
            ),
          ),
          Expanded(
            child: _buildOverviewStat(
              'Terminés',
              '${completedRappels.length}',
              Icons.check_circle,
              Colors.white,
            ),
          ),
          Expanded(
            child: _buildOverviewStat(
              'En retard',
              '${overdueRappels.length}',
              Icons.warning,
              overdueRappels.isNotEmpty ? Colors.orange : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value, IconData icon, Color color) {
    return Column(
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
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersList() {
    if (_rappels.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rappels.length,
      itemBuilder: (context, index) {
        final rappel = _rappels[index];
        return _buildReminderCard(rappel);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun rappel',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier rappel pour ne rien oublier',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddReminderDialog,
            icon: const Icon(Icons.add),
            label: const Text('Créer un rappel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Rappel rappel) {
    final isOverdue = !rappel.statut && DateTime.now().isAfter(rappel.date);
    final isCompleted = rappel.statut;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted 
            ? Colors.green.shade50 
            : isOverdue 
                ? Colors.orange.shade50 
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.shade200 
              : isOverdue 
                  ? Colors.orange.shade200 
                  : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted 
                ? Colors.green 
                : isOverdue 
                    ? Colors.orange 
                    : Colors.purple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCompleted 
                ? Icons.check_circle 
                : isOverdue 
                    ? Icons.warning 
                    : Icons.schedule,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          rappel.message,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(rappel.date),
              style: TextStyle(
                color: isOverdue ? Colors.orange.shade700 : Colors.grey.shade600,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isOverdue)
              Text(
                'En retard',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _markAsCompleted(rappel),
                color: Colors.green,
              ),
        onTap: () => _showReminderDetails(rappel),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Demain à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 1) {
      return 'Dans ${difference.inDays} jours';
    } else {
      return 'Le ${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  void _markAsCompleted(Rappel rappel) {
    setState(() {
      rappel.statut = true;
    });
    
    _rappelService.marquerCommeLu(rappel.id!);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Rappel marqué comme terminé'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showReminderDetails(Rappel rappel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.6,
        minChildSize: 0.3,
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: Colors.purple,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Détails du Rappel',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatDate(rappel.date),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          rappel.message,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fermer'),
                            ),
                          ),
                          if (!rappel.statut) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _markAsCompleted(rappel);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Marquer terminé'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReminderDialog() {
    final messageController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouveau Rappel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message du rappel',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text('${selectedDate.day}/${selectedDate.month}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.isNotEmpty) {
                  final rappel = Rappel(
                    utilisateurId: widget.utilisateur.id!,
                    message: messageController.text,
                    date: selectedDate,
                  );
                  
                  await _rappelService.creerRappel(rappel);
                  Navigator.pop(context);
                  _loadRappels();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rappel créé avec succès !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
