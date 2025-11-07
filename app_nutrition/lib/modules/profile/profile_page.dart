import 'package:flutter_riverpod/legacy.dart';

import 'metabolism_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// If you're defining providers at the top level, you might need this:
final sexProvider = StateProvider<Sex>((_) => Sex.male);
final weightProvider = StateProvider<double>((_) => 70);
final heightProvider = StateProvider<double>((_) => 175);
final ageProvider = StateProvider<int>((_) => 25);
final activityProvider = StateProvider<ActivityLevel>((_) => ActivityLevel.moderate);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sex = ref.watch(sexProvider);
    final weight = ref.watch(weightProvider);
    final height = ref.watch(heightProvider);
    final age = ref.watch(ageProvider);
    final act = ref.watch(activityProvider);

    final bmr = Metabolism.bmr(sex: sex, weightKg: weight, heightCm: height, age: age);
    final tdee = Metabolism.tdee(bmr, act);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Métabolisme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _segmented<Sex>(
            label: 'Sexe',
            value: sex,
            values: const [Sex.male, Sex.female],
            toText: (s) => s == Sex.male ? 'Homme' : 'Femme',
            onChange: (v) => ref.read(sexProvider.notifier).state = v,
          ),
          _numTile(context, 'Poids (kg)', weight, (v) => ref.read(weightProvider.notifier).state = v, 30, 250),
          _numTile(context, 'Taille (cm)', height, (v) => ref.read(heightProvider.notifier).state = v, 100, 230),
          _intTile(context, 'Âge', age, (v) => ref.read(ageProvider.notifier).state = v, 10, 100),
          const SizedBox(height: 8),
          DropdownButtonFormField<ActivityLevel>(
            value: act,
            items: ActivityLevel.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
            onChanged: (v) => ref.read(activityProvider.notifier).state = v!,
            decoration: const InputDecoration(labelText: 'Niveau d’activité'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('MB (BMR): ${bmr.toStringAsFixed(0)} kcal/j • TDEE: ${tdee.toStringAsFixed(0)} kcal/j'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmented<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) toText,
    required ValueChanged<T> onChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: values.map((v) {
            final sel = v == value;
            return ChoiceChip(label: Text(toText(v)), selected: sel, onSelected: (_) => onChange(v));
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _numTile(BuildContext c, String label, double current, ValueChanged<double> onSet, double min, double max) {
    final ctl = TextEditingController(text: current.toStringAsFixed(1));
    return ListTile(
      title: Text(label),
      trailing: Text('${current.toStringAsFixed(1)}'),
      onTap: () async {
        final v = await _ask(c, ctl, TextInputType.number);
        final parsed = double.tryParse(v ?? '');
        if (parsed != null && parsed >= min && parsed <= max) onSet(parsed);
      },
    );
  }

  Widget _intTile(BuildContext c, String label, int current, ValueChanged<int> onSet, int min, int max) {
    final ctl = TextEditingController(text: '$current');
    return ListTile(
      title: Text(label),
      trailing: Text('$current'),
      onTap: () async {
        final v = await _ask(c, ctl, TextInputType.number);
        final parsed = int.tryParse(v ?? '');
        if (parsed != null && parsed >= min && parsed <= max) onSet(parsed);
      },
    );
  }

  Future<String?> _ask(BuildContext c, TextEditingController ctl, TextInputType type) {
    return showDialog<String>(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Modifier'),
        content: TextField(controller: ctl, keyboardType: type),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(c, ctl.text), child: const Text('OK')),
        ],
      ),
    );
  }
}
