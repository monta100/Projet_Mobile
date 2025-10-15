import 'package:flutter/material.dart';
import '../Entites/rappel.dart';
import '../Entites/utilisateur.dart';
import '../Services/rappel_service.dart';

class NouveauRappelScreen extends StatefulWidget {
  final Utilisateur utilisateur;

  const NouveauRappelScreen({Key? key, required this.utilisateur})
    : super(key: key);

  @override
  State<NouveauRappelScreen> createState() => _NouveauRappelScreenState();
}

class _NouveauRappelScreenState extends State<NouveauRappelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  final RappelService _service = RappelService();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final rappel = Rappel(
      message: _messageController.text.trim(),
      date: date,
      utilisateurId: widget.utilisateur.id,
    );
    try {
      await _service.creerRappel(rappel);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Rappel créé')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau rappel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Entrez un message'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickDate,
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickTime,
                        child: Text('${_selectedTime.format(context)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _create,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Créer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
