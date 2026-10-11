import 'package:flutter/material.dart';

/// Label–value rows, the labels in one column.
class FactsTable extends StatelessWidget {
  final List<(String, String)> rows;

  const FactsTable(this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor);
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        for (final (label, value) in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 6),
                child: Text(label, style: labelStyle),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 6), child: SelectableText(value)),
            ],
          ),
      ],
    );
  }
}
