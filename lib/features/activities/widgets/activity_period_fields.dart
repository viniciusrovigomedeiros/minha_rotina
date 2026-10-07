import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/quarter_date_range.dart';

class ActivityPeriodFields extends StatefulWidget {
  const ActivityPeriodFields({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.fallbackStartDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onQuarterSelected,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime fallbackStartDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<QuarterDateRange> onQuarterSelected;

  @override
  State<ActivityPeriodFields> createState() => _ActivityPeriodFieldsState();
}

class _ActivityPeriodFieldsState extends State<ActivityPeriodFields> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year =
        (widget.startDate ?? widget.endDate ?? widget.fallbackStartDate).year;
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.startDate ?? widget.fallbackStartDate;
    final format = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período da iniciativa',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _dateField(
          label: 'Data inicial',
          value: format.format(start),
          onTap: () => _pickDate(isStart: true),
        ),
        const SizedBox(height: 12),
        _dateField(
          label: 'Data final',
          value:
              widget.endDate == null
                  ? 'Sem data final'
                  : format.format(widget.endDate!),
          onTap: () => _pickDate(isStart: false),
          onClear:
              widget.endDate == null
                  ? null
                  : () => widget.onEndDateChanged(null),
        ),
        const SizedBox(height: 8),
        Text(
          'Conta no calendário e no progresso apenas dentro deste período, incluindo a data final. Você pode ajustar datas passadas.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Row(
          children: [
            const Expanded(child: Text('Sugestões por trimestre')),
            IconButton(
              tooltip: 'Ano anterior',
              onPressed: () => setState(() => _year--),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text('$_year'),
            IconButton(
              tooltip: 'Próximo ano',
              onPressed: () => setState(() => _year++),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final range in QuarterDateRange.forYear(_year))
              ChoiceChip(
                label: Text(range.label),
                selected:
                    DateUtils.isSameDay(start, range.start) &&
                    DateUtils.isSameDay(widget.endDate, range.end),
                onSelected: (_) => widget.onQuarterSelected(range),
              ),
          ],
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon:
              onClear == null
                  ? const Icon(Icons.calendar_month_rounded)
                  : IconButton(
                    tooltip: 'Remover data final',
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_rounded),
                  ),
        ),
        child: Text(value),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final start = widget.startDate ?? widget.fallbackStartDate;
    final initial =
        isStart
            ? start
            : widget.endDate ?? QuarterDateRange.containing(start).end;
    final now = DateTime.now();
    final firstYear =
        initial.year < now.year - 20 ? initial.year : now.year - 20;
    final lastYear =
        initial.year > now.year + 20 ? initial.year : now.year + 20;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(firstYear),
      lastDate: DateTime(lastYear, 12, 31),
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null || !mounted) return;
    setState(() => _year = picked.year);
    if (isStart) {
      widget.onStartDateChanged(picked);
    } else {
      widget.onEndDateChanged(picked);
    }
  }
}
