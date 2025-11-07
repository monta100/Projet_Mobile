import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'metabolism_utils.dart';

final sexProvider = StateProvider<Sex>((_) => Sex.male);
final weightProvider = StateProvider<double>((_) => 70);
final heightProvider = StateProvider<double>((_) => 175);
final ageProvider = StateProvider<int>((_) => 25);
final activityProvider = StateProvider<ActivityLevel>(
  (_) => ActivityLevel.moderate,
);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil & Métabolisme',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Gérez vos informations personnelles',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          centerTitle: false,
          backgroundColor: const Color(0xFF8BC34A), // Matching green shade
          elevation: 6,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _segmented<Sex>(
              label: 'Sexe',
              value: ref.watch(sexProvider),
              values: const [Sex.male, Sex.female],
              toText: (s) => s == Sex.male ? 'Homme' : 'Femme',
              onChange: (v) => ref.read(sexProvider.notifier).state = v,
            ),
            _numTile(
              context,
              'Poids (kg)',
              ref.watch(weightProvider),
              (v) => ref.read(weightProvider.notifier).state = v,
              30,
              250,
            ),
            _numTile(
              context,
              'Taille (cm)',
              ref.watch(heightProvider),
              (v) => ref.read(heightProvider.notifier).state = v,
              100,
              230,
            ),
            _intTile(
              context,
              'Âge',
              ref.watch(ageProvider),
              (v) => ref.read(ageProvider.notifier).state = v,
              10,
              100,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ActivityLevel>(
              value: ref.watch(activityProvider),
              items: ActivityLevel.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => ref.read(activityProvider.notifier).state = v!,
              decoration: const InputDecoration(
                labelText: 'Niveau d’activité',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'MB (BMR): ${Metabolism.bmr(sex: ref.watch(sexProvider), weightKg: ref.watch(weightProvider), heightCm: ref.watch(heightProvider), age: ref.watch(ageProvider)).toStringAsFixed(0)} kcal/j • TDEE: ${Metabolism.tdee(Metabolism.bmr(sex: ref.watch(sexProvider), weightKg: ref.watch(weightProvider), heightCm: ref.watch(heightProvider), age: ref.watch(ageProvider)), ref.watch(activityProvider)).toStringAsFixed(0)} kcal/j',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
              ),
            ),
          ],
        ),
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
            return ChoiceChip(
              label: Text(toText(v)),
              selected: sel,
              onSelected: (_) => onChange(v),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _numTile(
    BuildContext c,
    String label,
    double current,
    ValueChanged<double> onSet,
    double min,
    double max,
  ) {
    return ListTile(
      title: Text(label),
      trailing: Text('${current.toStringAsFixed(1)}'),
      onTap: () async {
        final value = await _promptDouble(c, label, current, min, max);
        if (value != null) onSet(value);
      },
    );
  }

  Widget _intTile(
    BuildContext c,
    String label,
    int current,
    ValueChanged<int> onSet,
    int min,
    int max,
  ) {
    return ListTile(
      title: Text(label),
      trailing: Text('$current'),
      onTap: () async {
        final value = await _promptInt(c, label, current, min, max);
        if (value != null) onSet(value);
      },
    );
  }

  Future<double?> _promptDouble(
    BuildContext context,
    String label,
    double current,
    double min,
    double max,
  ) async {
    final controller = TextEditingController(text: current.toStringAsFixed(1));
    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Modifier $label'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed != null && parsed >= min && parsed <= max) {
                Navigator.pop(context, parsed);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<int?> _promptInt(
    BuildContext context,
    String label,
    int current,
    int min,
    int max,
  ) async {
    final controller = TextEditingController(text: '$current');
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Modifier $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null && parsed >= min && parsed <= max) {
                Navigator.pop(context, parsed);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
