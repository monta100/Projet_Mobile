import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/journal_repository.dart';
import '../models/health_record.dart';


final journalRepoProvider = Provider<JournalRepository>((ref) => JournalRepository());


class JournalFilter {
final HealthMetricType? type;
final DateTime? from;
final DateTime? to;
final String? query;
const JournalFilter({this.type, this.from, this.to, this.query});


JournalFilter copyWith({HealthMetricType? type, DateTime? from, DateTime? to, String? query}) =>
JournalFilter(
type: type ?? this.type,
from: from ?? this.from,
to: to ?? this.to,
query: query ?? this.query,
);
}


final journalFilterProvider = StateProvider<JournalFilter>((ref) => const JournalFilter());
final journalListProvider = FutureProvider.autoDispose<List<HealthRecord>>((ref) async {
final repo = ref.watch(journalRepoProvider);
final f = ref.watch(journalFilterProvider);
return repo.fetchAll(type: f.type, from: f.from, to: f.to, noteQuery: f.query);
});


final selectedRecordProvider = FutureProvider.family<HealthRecord?, int>((ref, id) async {
final repo = ref.watch(journalRepoProvider);
return repo.findById(id);
});


final last7DaysProvider = FutureProvider.autoDispose<Map<HealthMetricType, List<HealthRecord>>>((ref) async {
final repo = ref.watch(journalRepoProvider);
final now = DateTime.now();
final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
final result = <HealthMetricType, List<HealthRecord>>{};
for (final t in HealthMetricType.values) {
final rows = await repo.fetchAll(type: t, from: from, to: now);
result[t] = rows;
}
return result;
});