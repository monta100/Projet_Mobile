import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Entities/programme.dart';
import '../Services/programme_service.dart';

const Color mainGreen = Color(0xFF2ECC71);
const Color darkGreen = Color(0xFF1E8449);
const Color lightGray = Color(0xFFF8F9FA);

class ProgrammeScreen extends StatefulWidget {
  const ProgrammeScreen({super.key});

  @override
  State<ProgrammeScreen> createState() => _ProgrammeScreenState();
}

class _ProgrammeScreenState extends State<ProgrammeScreen> {
  final ProgrammeService _service = ProgrammeService();
  List<Programme> _programmes = [];

  final _nomCtrl = TextEditingController();
  final _objectifCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;

  final DateFormat _fmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getAllProgrammes();
    setState(() => _programmes = data);
  }

  Future<void> _add() async {
    if (_nomCtrl.text.isEmpty ||
        _objectifCtrl.text.isEmpty ||
        _dateDebut == null ||
        _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Veuillez remplir tous les champs')),
      );
      return;
    }

    await _service.insertProgramme(Programme(
      nom: _nomCtrl.text.trim(),
      objectif: _objectifCtrl.text.trim(),
      dateDebut: _dateDebut!.toIso8601String().split('T').first,
      dateFin: _dateFin!.toIso8601String().split('T').first,
    ));

    _nomCtrl.clear();
    _objectifCtrl.clear();
    _dateDebut = null;
    _dateFin = null;
    _load();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Programme ajouté avec succès !")),
    );
  }

  DateTime _safeParse(String date) {
    try {
      return DateTime.parse(date);
    } catch (_) {
      try {
        return DateFormat('d/M/yyyy').parse(date);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _dateDebut : _dateFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('fr', 'FR'),
      helpText: isStart ? "Choisir la date de début" : "Choisir la date de fin",
      cancelText: "Annuler",
      confirmText: "Valider",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: mainGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => isStart ? _dateDebut = picked : _dateFin = picked);
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("🗑 Supprimer le programme",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "Voulez-vous vraiment supprimer ce programme ?",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _service.deleteProgramme(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainGreen,
        icon: const Icon(Icons.add),
        label: const Text("Nouveau programme"),
        onPressed: () => _showAddDialog(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🌿 HEADER MODERNE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.calendar_month,
                          color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "Mes Programmes 💪",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Planifiez vos objectifs sportifs et vos progrès",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 70,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),

            // 📋 LISTE DES PROGRAMMES
            Expanded(
              child: _programmes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty,
                              color: Colors.grey, size: 80),
                          SizedBox(height: 10),
                          Text("Aucun programme pour le moment",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _programmes.length,
                      itemBuilder: (_, i) {
                        final p = _programmes[i];
                        final debut = _fmt.format(_safeParse(p.dateDebut));
                        final fin = _fmt.format(_safeParse(p.dateFin));

                        // 🌟 Nouveau style de carte
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFF0FDF4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🟢 Icône
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: mainGreen.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.track_changes,
                                    color: mainGreen, size: 26),
                              ),
                              const SizedBox(width: 12),

                              // 🧾 Contenu
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.nom,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.flag,
                                            size: 16, color: mainGreen),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            "Objectif : ${p.objectif}",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 14, color: Colors.black54),
                                        const SizedBox(width: 4),
                                        Text(
                                          "$debut → $fin",
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 🗑 Bouton supprimer
                              IconButton(
                                icon: const Icon(Icons.delete_forever_rounded,
                                    color: Colors.redAccent, size: 26),
                                onPressed: () => _confirmDelete(p.id!),
                              ),
                            ],
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

  // 🌟 MODAL D’AJOUT – AVEC BOUTON ANNULER
  void _showAddDialog(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Text(
                  "🆕 Nouveau programme",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _field("Nom du programme", _nomCtrl),
                _field("Objectif", _objectifCtrl),
                const SizedBox(height: 10),
                _dateButton(
                    label: "Date de début",
                    value:
                        _dateDebut == null ? "" : _fmt.format(_dateDebut!),
                    onTap: () => _selectDate(ctx, true)),
                const SizedBox(height: 10),
                _dateButton(
                    label: "Date de fin",
                    value: _dateFin == null ? "" : _fmt.format(_dateFin!),
                    onTap: () => _selectDate(ctx, false)),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Bouton Annuler
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text("Annuler",
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    // Bouton Ajouter
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: const Text("Ajouter",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: mainGreen.withOpacity(0.4),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _add();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.edit, color: mainGreen),
          filled: true,
          fillColor: lightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: mainGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: mainGreen, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: mainGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: mainGreen.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: mainGreen),
            const SizedBox(width: 10),
            Text(
              value.isEmpty ? label : "$label : $value",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
