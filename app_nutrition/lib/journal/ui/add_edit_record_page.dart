import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_record.dart';
import '../state/journal_providers.dart';

class AddEditRecordPage extends ConsumerStatefulWidget {
  final HealthRecord? existing;
  const AddEditRecordPage({super.key, this.existing});

  @override
  ConsumerState<AddEditRecordPage> createState() => _AddEditRecordPageState();
}

class _AddEditRecordPageState extends ConsumerState<AddEditRecordPage> {
  late HealthMetricType _type;
  DateTime _dateTime = DateTime.now();

  // controllers for fields
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _glucose = TextEditingController();
  final _sleep = TextEditingController();
  final _weight = TextEditingController();
  final _bpm = TextEditingController();
  final _customVal = TextEditingController();
  final _customUnit = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? HealthMetricType.bloodPressure;
    _dateTime = e?.dateTime ?? DateTime.now();
    if (e != null) {
      switch (e.type) {
        case HealthMetricType.bloodPressure:
          _systolic.text = (e.values['systolic'] ?? '').toString();
          _diastolic.text = (e.values['diastolic'] ?? '').toString();
          break;
        case HealthMetricType.glucose:
          _glucose.text = (e.values['value'] ?? '').toString();
          break;
        case HealthMetricType.sleep:
          _sleep.text = (e.values['hours'] ?? '').toString();
          break;
        case HealthMetricType.weight:
          _weight.text = (e.values['kg'] ?? '').toString();
          break;
        case HealthMetricType.heartRate:
          _bpm.text = (e.values['bpm'] ?? '').toString();
          break;
        case HealthMetricType.custom:
          _customVal.text = (e.values['value'] ?? '').toString();
          _customUnit.text = e.unit ?? '';
          break;
      }
      _note.text = e.note ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _systolic,
      _diastolic,
      _glucose,
      _sleep,
      _weight,
      _bpm,
      _customVal,
      _customUnit,
      _note,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'Ajouter entrée' : 'Modifier entrée',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<HealthMetricType>(
              initialValue: _type,
              items: [
                for (final t in HealthMetricType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _type = v!),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 8),
            _DateTimeField(
              value: _dateTime,
              onChange: (d) => setState(() => _dateTime = d),
            ),
            const SizedBox(height: 8),
            _buildFields(),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظة / Note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ / Enregistrer'),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    switch (_type) {
      case HealthMetricType.bloodPressure:
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _systolic,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Systolic (mmHg)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _diastolic,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Diastolic (mmHg)',
                ),
              ),
            ),
          ],
        );
      case HealthMetricType.glucose:
        return TextField(
          controller: _glucose,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Glucose (mg/dL)'),
        );
      case HealthMetricType.sleep:
        return TextField(
          controller: _sleep,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Heures de sommeil'),
        );
      case HealthMetricType.weight:
        return TextField(
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Poids (kg)'),
        );
      case HealthMetricType.heartRate:
        return TextField(
          controller: _bpm,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'BPM'),
        );
      case HealthMetricType.custom:
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customVal,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Valeur'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _customUnit,
                decoration: const InputDecoration(labelText: 'Unité'),
              ),
            ),
          ],
        );
    }
  }

  Future<void> _save() async {
    final repo = ref.read(journalRepoProvider);
    final values = <String, num>{};
    String? unit;
    try {
      switch (_type) {
        case HealthMetricType.bloodPressure:
          values['systolic'] = num.parse(_systolic.text);
          values['diastolic'] = num.parse(_diastolic.text);
          break;
        case HealthMetricType.glucose:
          values['value'] = num.parse(_glucose.text);
          break;
        case HealthMetricType.sleep:
          values['hours'] = num.parse(_sleep.text);
          break;
        case HealthMetricType.weight:
          values['kg'] = num.parse(_weight.text);
          break;
        case HealthMetricType.heartRate:
          values['bpm'] = num.parse(_bpm.text);
          break;
        case HealthMetricType.custom:
          values['value'] = num.parse(_customVal.text);
          unit = _customUnit.text.trim().isEmpty
              ? null
              : _customUnit.text.trim();
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez vérifier les valeurs saisies'),
          ),
        );
      }
      return;
    }

    final base = HealthRecord(
      id: widget.existing?.id,
      type: _type,
      dateTime: _dateTime,
      values: values,
      unit: unit,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      createdAt: widget.existing?.createdAt,
      updatedAt: DateTime.now(),
    );

    if (widget.existing == null) {
      await repo.insert(base);
    } else {
      await repo.update(base);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _DateTimeField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onChange;
  const _DateTimeField({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Date'),
            child: InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: value,
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2100),
                );
                if (d != null)
                  onChange(
                    DateTime(d.year, d.month, d.day, value.hour, value.minute),
                  );
              },
              child: Text(
                '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Heure'),
            child: InkWell(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(value),
                );
                if (t != null)
                  onChange(
                    DateTime(
                      value.year,
                      value.month,
                      value.day,
                      t.hour,
                      t.minute,
                    ),
                  );
              },
              child: Text(
                '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
