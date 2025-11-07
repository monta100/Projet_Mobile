import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw_widgets;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as xls;
import 'package:share_plus/share_plus.dart';
import '../models/health_record.dart';
import '../state/journal_providers.dart';

class ExportUtils {
  static Future<void> exportSingleRecordPdf(BuildContext context, HealthRecord r) async {
    final df = DateFormat('y-MM-dd HH:mm');
    final doc = pw_widgets.Document();
    doc.addPage(
      pw_widgets.Page(
        build: (_) => pw_widgets.Column(crossAxisAlignment: pw_widgets.CrossAxisAlignment.start, children: [
          pw_widgets.Text('Journal de Santé — Entrée', style: pw_widgets.TextStyle(fontSize: 18, fontWeight: pw_widgets.FontWeight.bold)),
          pw_widgets.SizedBox(height: 8),
          pw_widgets.Text('Type: ${r.type.label}'),
          pw_widgets.Text('Date: ${df.format(r.dateTime)}'),
          pw_widgets.SizedBox(height: 8),
          pw_widgets.Text('Valeurs: ${r.values} ${r.unit ?? ''}'),
          if (r.note != null) pw_widgets.Text('Note: ${r.note}')
        ]),
      ),
    );
    await Printing.layoutPdf(onLayout: (fmt) async => doc.save());
  }

  static Future<void> openRangeExportSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const _ExportSheet(),
    );
  }
}

class _ExportSheet extends ConsumerStatefulWidget { const _ExportSheet();
  @override ConsumerState<_ExportSheet> createState() => _ExportSheetState(); }

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  DateTimeRange? _range;
  HealthMetricType? _type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Exporter — PDF / Excel', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final r = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 5),
                    initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
                  );
                  if (r != null) setState(() => _range = r);
                },
                child: Text(_range == null ? 'Période' : '${_range!.start.toString().split(' ').first} → ${_range!.end.toString().split(' ').first}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<HealthMetricType?>(
                initialValue: _type,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous')),
                  ...HealthMetricType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))),
                ],
                onChanged: (v) => setState(() => _type = v),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
                onPressed: () async {
                  await _exportPdf(context);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.table_view),
                label: const Text('Excel'),
                onPressed: () async { await _exportExcel(context); },
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final repo = ref.read(journalRepoProvider);
    final from = _range?.start;
    final to = _range?.end;
    final df = DateFormat('y-MM-dd HH:mm');
    final rows = await repo.fetchAll(type: _type, from: from, to: to);

    final doc = pw_widgets.Document();
    doc.addPage(
      pw_widgets.MultiPage(
        pageFormat: pw.PdfPageFormat.a4,
        build: (_) => [
          pw_widgets.Header(level: 0, child: pw_widgets.Text('Journal de Santé — Rapport')),
          pw_widgets.Paragraph(text: 'Période: ${from?.toString().split(' ').first ?? '-'} → ${to?.toString().split(' ').first ?? '-'}'),
          pw_widgets.Table.fromTextArray(
            headers: const ['Date', 'Type', 'Valeurs', 'Note'],
            data: [
              for (final r in rows)
                [
                  df.format(r.dateTime),
                  r.type.label,
                  r.values.toString() + (r.unit == null ? '' : ' ${r.unit}'),
                  r.note ?? ''
                ]
            ],
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (fmt) async => doc.save());
  }

  Future<void> _exportExcel(BuildContext context) async {
    final repo = ref.read(journalRepoProvider);
    final from = _range?.start;
    final to = _range?.end;
    final rows = await repo.fetchAll(type: _type, from: from, to: to);

    final book = xls.Excel.createExcel();
    final sheet = book['Journal'];
   sheet.appendRow([
  xls.TextCellValue('Date'),
  xls.TextCellValue('Type'),
  xls.TextCellValue('Values'),
  xls.TextCellValue('Unit'),
  xls.TextCellValue('Note'),
]);

for (final r in rows) {
  sheet.appendRow([
    // use TextCellValue for safe serialization (or DoubleCellValue for numbers)
    xls.TextCellValue(r.dateTime.toIso8601String()),
    xls.TextCellValue(r.type.label),
    xls.TextCellValue(r.values.toString()),
    xls.TextCellValue(r.unit ?? ''),
    xls.TextCellValue(r.note ?? ''),
  ]);
}
    book.setDefaultSheet('Journal');

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/journal_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(book.encode()!);

    await Share.shareXFiles([XFile(file.path)], subject: 'Export Journal Santé');
  }
}
