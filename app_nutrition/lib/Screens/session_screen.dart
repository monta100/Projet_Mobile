import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Entities/session.dart';
import '../Services/session_service.dart';

const Color mainGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF1E8449);
const Color lightGray = Color(0xFFF5F6F8);

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final SessionService _service = SessionService();
  List<Session> _sessions = [];

  final _typeCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  final _intensiteCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getAllSessions();
    setState(() => _sessions = data);
  }

  Future<void> _add() async {
    if (_typeCtrl.text.isEmpty ||
        _dureeCtrl.text.isEmpty ||
        _intensiteCtrl.text.isEmpty ||
        _caloriesCtrl.text.isEmpty) return;

    await _service.insertSession(Session(
      typeActivite: _typeCtrl.text.trim(),
      duree: int.parse(_dureeCtrl.text),
      intensite: _intensiteCtrl.text.trim(),
      calories: int.parse(_caloriesCtrl.text),
    ));

    _typeCtrl.clear();
    _dureeCtrl.clear();
    _intensiteCtrl.clear();
    _caloriesCtrl.clear();
    _load();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Séance ajoutée avec succès !")),
    );
  }

  // 🌈 Couleur selon intensité
  Color _colorByIntensity(String intensity) {
    switch (intensity.toLowerCase()) {
      case "faible":
        return Colors.blueAccent;
      case "moyenne":
        return Colors.orangeAccent;
      case "forte":
        return Colors.redAccent;
      default:
        return mainGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainGreen,
        onPressed: () => _showAddDialog(context),
        label: const Text("Nouvelle séance"),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🌿 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainGreen, darkGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.fitness_center, color: Colors.white, size: 30),
                  SizedBox(height: 8),
                  Text("Mes Séances 🏋️‍♀️",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  SizedBox(height: 6),
                  Text("Suivez et analysez vos entraînements",
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ),

            // 🧾 LISTE DES SÉANCES
            Expanded(
              child: _sessions.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucune séance enregistrée",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length,
                      itemBuilder: (_, i) {
                        final s = _sessions[i];
                        final color = _colorByIntensity(s.intensite);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFF0FDF4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 🎯 Icône principale
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.track_changes,
                                    color: color, size: 24),
                              ),
                              const SizedBox(width: 12),

                              // 🧾 Détails séance
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.typeActivite,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.timer_outlined,
                                            size: 16, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Text("${s.duree} min",
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87)),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.local_fire_department,
                                            size: 16, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Text("${s.calories} kcal",
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Intensité : ${s.intensite}",
                                        style: TextStyle(
                                            color: color,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 🗑 Bouton supprimer (style Programmes)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever_rounded,
                                  color: Colors.redAccent,
                                  size: 26,
                                ),
                                onPressed: () async {
                                  await _service.deleteSession(s.id!);
                                  _load();
                                },
                              ),
                            ],
                          ),
                        );
                      }),
            ),
          ],
        ),
      ),
    );
  }

  // 📋 Dialogue d’ajout stylisé
  void _showAddDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Nouvelle séance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _field("Type d’activité", _typeCtrl),
              _field("Durée (min)", _dureeCtrl, number: true),
              _dropdownIntensity(),
              _field("Calories brûlées", _caloriesCtrl, number: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: mainGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _add();
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.edit, color: mainGreen),
          filled: true,
          fillColor: lightGray,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: mainGreen)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: mainGreen, width: 2),
          ),
        ),
      ),
    );
  }

  // 🧩 Menu déroulant pour intensité
  Widget _dropdownIntensity() {
    final intensities = ["Faible", "Moyenne", "Forte"];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Intensité",
          prefixIcon: const Icon(Icons.bolt, color: mainGreen),
          filled: true,
          fillColor: lightGray,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: intensities
            .map((val) => DropdownMenuItem(value: val, child: Text(val)))
            .toList(),
        onChanged: (val) => _intensiteCtrl.text = val ?? "",
      ),
    );
  }
}
