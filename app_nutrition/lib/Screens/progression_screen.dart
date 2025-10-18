import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Entities/progression.dart';
import '../Services/progression_service.dart';

class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  final ProgressionService _service = ProgressionService();
  List<Progression> _progressions = [];

  DateTime? _selectedDate;
  final _caloriesCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  final _commentaireCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProgressions();
  }

  Future<void> _loadProgressions() async {
    final data = await _service.getAllProgressions();
    setState(() => _progressions = data);
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2ECC71), // 🌿 vert nutrition
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addProgression() async {
    if (_selectedDate == null ||
        _caloriesCtrl.text.isEmpty ||
        _dureeCtrl.text.isEmpty ||
        _commentaireCtrl.text.isEmpty ||
        _sessionCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    await _service.insertProgression(Progression(
      date: formattedDate,
      caloriesBrulees: int.parse(_caloriesCtrl.text),
      dureeTotale: int.parse(_dureeCtrl.text),
      commentaire: _commentaireCtrl.text,
      sessionId: int.parse(_sessionCtrl.text),
    ));

    _selectedDate = null;
    _caloriesCtrl.clear();
    _dureeCtrl.clear();
    _commentaireCtrl.clear();
    _sessionCtrl.clear();

    _loadProgressions();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Progression ajoutée avec succès 🎯")),
    );
  }

  Future<void> _deleteProgression(int id) async {
    await _service.deleteProgression(id);
    _loadProgressions();
  }

  @override
  Widget build(BuildContext context) {
    const mainGreen = Color(0xFF2ECC71);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: mainGreen,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER 🌿
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: mainGreen,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.show_chart, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "Suivi des Progressions",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Suivez vos performances et calories brûlées 🔥",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // 📊 GRAPHIQUE
            if (_progressions.isNotEmpty)
              SizedBox(
                height: 220,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LineChart(
                    LineChartData(
                      backgroundColor: Colors.white,
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: mainGreen,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(
                            show: true,
                            color: mainGreen.withOpacity(0.2),
                          ),
                          spots: _progressions.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.caloriesBrulees.toDouble(),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Aucune donnée à afficher pour le moment 📉"),
              ),

            // 🧾 LISTE DES PROGRESSIONS
            Expanded(
              child: _progressions.isEmpty
                  ? const Center(
                      child: Text("Aucune progression enregistrée"),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _progressions.length,
                      itemBuilder: (_, i) {
                        final p = _progressions[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: mainGreen.withOpacity(0.2),
                              child: const Icon(Icons.fitness_center,
                                  color: mainGreen),
                            ),
                            title: Text(
                              DateFormat('dd/MM/yyyy').format(
                                DateTime.parse(p.date),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: mainGreen,
                              ),
                            ),
                            subtitle: Text(
                              "Durée : ${p.dureeTotale} min\nCalories : ${p.caloriesBrulees} kcal\n${p.commentaire}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProgression(p.id!),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 POPUP D’AJOUT
  void _showAddDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nouvelle progression",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Sélecteur de date 🗓️
              GestureDetector(
                onTap: () => _pickDate(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: Color(0xFF2ECC71)),
                      const SizedBox(width: 10),
                      Text(
                        _selectedDate == null
                            ? "Choisir une date"
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _field("Calories brûlées", _caloriesCtrl, number: true),
              _field("Durée totale (min)", _dureeCtrl, number: true),
              _field("Commentaire", _commentaireCtrl),
              _field("ID session associée", _sessionCtrl, number: true),
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
              backgroundColor: const Color(0xFF2ECC71),
            ),
            onPressed: _addProgression,
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
