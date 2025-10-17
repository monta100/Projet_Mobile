import 'package:flutter/material.dart';
import '../Entities/session.dart';
import '../Services/session_service.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final SessionService _sessionService = SessionService();
  List<Session> _sessions = [];

  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _dureeController = TextEditingController();
  final TextEditingController _intensiteController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final data = await _sessionService.getAllSessions();
    setState(() => _sessions = data);
  }

  Future<void> _addSession() async {
    if (_typeController.text.isEmpty ||
        _dureeController.text.isEmpty ||
        _intensiteController.text.isEmpty ||
        _caloriesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final session = Session(
      typeActivite: _typeController.text,
      duree: int.tryParse(_dureeController.text) ?? 0,
      intensite: _intensiteController.text,
      calories: int.tryParse(_caloriesController.text) ?? 0,
    );

    await _sessionService.insertSession(session);
    _clearForm();
    _loadSessions();
  }

  void _clearForm() {
    _typeController.clear();
    _dureeController.clear();
    _intensiteController.clear();
    _caloriesController.clear();
  }

  Future<void> _deleteSession(int id) async {
    await _sessionService.deleteSession(id);
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    const Color mainGreen = Color(0xFF2ECC71); // 💚 vert principal

    return Scaffold(
      appBar: AppBar(
        title: const Text("Suivi des séances"),
        backgroundColor: mainGreen,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🟢 Formulaire d’ajout
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Ajouter une séance",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: mainGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _typeController,
                      decoration: const InputDecoration(
                        labelText: "Type d’activité",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dureeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Durée (min)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _intensiteController,
                      decoration: const InputDecoration(
                        labelText: "Intensité (faible / moyenne / forte)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Calories brûlées",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _addSession,
                      icon: const Icon(Icons.add),
                      label: const Text("Ajouter"),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🟩 Liste des séances
          Expanded(
            child: _sessions.isEmpty
                ? const Center(
                    child: Text(
                      "Aucune séance enregistrée",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final s = _sessions[index];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            s.typeActivite,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: mainGreen,
                            ),
                          ),
                          subtitle: Text(
                            "Durée: ${s.duree} min | Intensité: ${s.intensite}\nCalories: ${s.calories}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSession(s.id!),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
