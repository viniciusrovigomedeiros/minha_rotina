import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/okr_progress_utils.dart';
import '../../../data/models/key_result.dart';
import '../../../data/models/key_result_check_in.dart';

class OkrCheckInSheetResult {
  const OkrCheckInSheetResult({
    required this.updates,
    required this.confidence,
    this.note,
  });

  final List<OkrCheckInUpdate> updates;
  final String? note;
  final CheckInConfidence confidence;
}

class OkrCheckInUpdate {
  const OkrCheckInUpdate({required this.keyResultId, required this.valueAfter});

  final String keyResultId;
  final double valueAfter;
}

class OkrCheckInItem {
  const OkrCheckInItem({
    required this.keyResult,
    required this.code,
    required this.needsUpdate,
  });

  final KeyResult keyResult;
  final String code;
  final bool needsUpdate;
}

Future<OkrCheckInSheetResult?> showOkrCheckInSheet({
  required BuildContext context,
  required String objectiveTitle,
  required List<OkrCheckInItem> items,
  String? focusKeyResultId,
}) {
  return showModalBottomSheet<OkrCheckInSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (context) => _OkrCheckInSheet(
          objectiveTitle: objectiveTitle,
          items: _sortItems(items, focusKeyResultId),
        ),
  );
}

List<OkrCheckInItem> _sortItems(
  List<OkrCheckInItem> items,
  String? focusKeyResultId,
) {
  final sorted = [...items];
  sorted.sort((a, b) {
    final aFocus = a.keyResult.id == focusKeyResultId ? 1 : 0;
    final bFocus = b.keyResult.id == focusKeyResultId ? 1 : 0;
    if (aFocus != bFocus) return bFocus.compareTo(aFocus);

    final aPending = a.needsUpdate ? 1 : 0;
    final bPending = b.needsUpdate ? 1 : 0;
    if (aPending != bPending) return bPending.compareTo(aPending);

    return a.code.compareTo(b.code);
  });
  return sorted;
}

double? _parseLocalizedDouble(String raw) {
  var normalized = raw.trim().replaceAll(' ', '');
  final hasComma = normalized.contains(',');
  final hasDot = normalized.contains('.');

  if (hasComma && hasDot) {
    final commaIndex = normalized.lastIndexOf(',');
    final dotIndex = normalized.lastIndexOf('.');
    if (commaIndex > dotIndex) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '');
    }
  } else if (hasComma) {
    normalized = normalized.replaceAll(',', '.');
  }

  return double.tryParse(normalized);
}

class _OkrCheckInSheet extends StatefulWidget {
  const _OkrCheckInSheet({required this.objectiveTitle, required this.items});

  final String objectiveTitle;
  final List<OkrCheckInItem> items;

  @override
  State<_OkrCheckInSheet> createState() => _OkrCheckInSheetState();
}

class _OkrCheckInSheetState extends State<_OkrCheckInSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  final Map<String, TextEditingController> _valueControllers = {};
  final Map<String, bool> _booleanValues = {};
  CheckInConfidence _confidence = CheckInConfidence.medium;

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      if (item.keyResult.measurementType == KeyResultMeasurementType.boolean) {
        _booleanValues[item.keyResult.id] =
            item.keyResult.currentValue >= item.keyResult.targetValue;
        continue;
      }
      _valueControllers[item.keyResult.id] = TextEditingController(
        text: _formatEditableValue(item.keyResult.currentValue),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final controller in _valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.items.where((item) => item.needsUpdate).length;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check-in semanal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.objectiveTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.calendar_today_rounded,
                      text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    ),
                    _InfoPill(
                      icon: Icons.pending_actions_rounded,
                      text: '$pendingCount pendente(s)',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Atualização dos resultados-chave',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                for (int index = 0; index < widget.items.length; index++) ...[
                  _KeyResultCheckInCard(
                    item: widget.items[index],
                    controller:
                        _valueControllers[widget.items[index].keyResult.id],
                    booleanValue:
                        _booleanValues[widget.items[index].keyResult.id],
                    onBooleanChanged:
                        widget.items[index].keyResult.measurementType ==
                                KeyResultMeasurementType.boolean
                            ? (value) => setState(
                              () =>
                                  _booleanValues[widget
                                          .items[index]
                                          .keyResult
                                          .id] =
                                      value,
                            )
                            : null,
                  ),
                  if (index < widget.items.length - 1)
                    const SizedBox(height: 10),
                ],
                const SizedBox(height: 16),
                Text(
                  'Status da semana',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      CheckInConfidence.values.map((item) {
                        final selected = item == _confidence;
                        return ChoiceChip(
                          label: Text(item.label),
                          selected: selected,
                          onSelected: (_) => setState(() => _confidence = item),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 220,
                  decoration: const InputDecoration(
                    labelText: 'Observação da semana',
                    hintText:
                        'Resumo rápido do que andou, riscos e pendências.',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Salvar check-in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final updates =
        widget.items.map((item) {
          if (item.keyResult.measurementType ==
              KeyResultMeasurementType.boolean) {
            return OkrCheckInUpdate(
              keyResultId: item.keyResult.id,
              valueAfter: (_booleanValues[item.keyResult.id] ?? false) ? 1 : 0,
            );
          }

          final parsed = _parseLocalizedDouble(
            _valueControllers[item.keyResult.id]?.text ?? '',
          );
          return OkrCheckInUpdate(
            keyResultId: item.keyResult.id,
            valueAfter: parsed ?? item.keyResult.currentValue,
          );
        }).toList();

    Navigator.of(context).pop(
      OkrCheckInSheetResult(
        updates: updates,
        note: _noteController.text.trim(),
        confidence: _confidence,
      ),
    );
  }

  String _formatEditableValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _KeyResultCheckInCard extends StatelessWidget {
  const _KeyResultCheckInCard({
    required this.item,
    this.controller,
    this.booleanValue,
    this.onBooleanChanged,
  });

  final OkrCheckInItem item;
  final TextEditingController? controller;
  final bool? booleanValue;
  final ValueChanged<bool>? onBooleanChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.track_changes_rounded,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.code,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (item.needsUpdate) ...[
                          const SizedBox(width: 8),
                          const _PendingChip(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.keyResult.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atual: ${OkrProgressUtils.formatValue(item.keyResult, item.keyResult.currentValue)} • Meta: ${OkrProgressUtils.formatValue(item.keyResult, item.keyResult.targetValue)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.keyResult.measurementType ==
              KeyResultMeasurementType.boolean)
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('Não')),
                ButtonSegment<bool>(value: true, label: Text('Sim')),
              ],
              selected: {booleanValue ?? false},
              onSelectionChanged: (selection) {
                onBooleanChanged?.call(selection.first);
              },
            )
          else
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Novo valor atual'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe um valor.';
                }
                if (_parseLocalizedDouble(value) == null) {
                  return 'Valor inválido.';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Pendente',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
