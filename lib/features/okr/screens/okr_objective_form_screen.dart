import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/okr_progress_utils.dart';
import '../../../data/models/category.dart';
import '../../../data/models/key_result.dart';
import '../../../data/models/okr_cycle.dart';
import '../../../data/models/okr_objective.dart';
import '../../../state/categories_controller.dart';
import '../../../state/okr_management_controller.dart';
import '../../../state/okr_workspace_controller.dart';

class OkrObjectiveFormScreen extends ConsumerStatefulWidget {
  const OkrObjectiveFormScreen({super.key, this.objectiveId});

  final String? objectiveId;

  bool get isEditing => objectiveId != null;

  @override
  ConsumerState<OkrObjectiveFormScreen> createState() =>
      _OkrObjectiveFormScreenState();
}

class _OkrObjectiveFormScreenState
    extends ConsumerState<OkrObjectiveFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_KeyResultFormValue> _keyResults = [];
  bool _didLoadInitialData = false;
  bool _isSubmitting = false;
  String? _cycleId;
  String? _categoryId;
  OkrObjectiveStatus _status = OkrObjectiveStatus.active;
  int? _checkInFrequencyDays = 7;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final item in _keyResults) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceAsync = ref.watch(okrWorkspaceControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar objetivo' : 'Novo objetivo'),
      ),
      body: SafeArea(
        top: false,
        child: workspaceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (workspace) {
            return categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => Center(child: Text('Erro ao carregar: $error')),
              data: (categories) {
                final cycles =
                    workspace.cycleProgresses
                        .map((item) => item.cycle)
                        .toList();
                final editing =
                    widget.objectiveId == null
                        ? null
                        : ref.watch(
                          okrObjectiveProgressProvider(widget.objectiveId!),
                        );
                _loadInitialData(cycles, categories, editing);

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      DropdownButtonFormField<String>(
                        value: _cycleId,
                        decoration: const InputDecoration(labelText: 'Ciclo'),
                        items:
                            cycles
                                .map(
                                  (cycle) => DropdownMenuItem(
                                    value: cycle.id,
                                    child: Text(cycle.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _cycleId = value;
                            final match =
                                cycles
                                    .where((item) => item.id == value)
                                    .toList();
                            if (match.isEmpty) return;
                            _startDate = match.first.startDate;
                            _endDate = match.first.endDate;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Objetivo',
                          hintText:
                              'Ex: Estar preparado para processos seletivos internacionais',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o objetivo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Descrição (opcional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Categoria / área da vida',
                        ),
                        items:
                            categories
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(() => _categoryId = value),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Início',
                              value: _startDate,
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DateField(
                              label: 'Fim',
                              value: _endDate,
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<OkrObjectiveStatus>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items:
                            OkrObjectiveStatus.values
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status.label),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _status = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: _checkInFrequencyDays,
                        decoration: const InputDecoration(
                          labelText: 'Frequência de check-in',
                        ),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('Semanal')),
                          DropdownMenuItem(value: 14, child: Text('Quinzenal')),
                          DropdownMenuItem(value: 30, child: Text('Mensal')),
                          DropdownMenuItem(
                            value: null,
                            child: Text('Sem frequência fixa'),
                          ),
                        ],
                        onChanged:
                            (value) =>
                                setState(() => _checkInFrequencyDays = value),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Resultados-chave',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (_keyResults.length < 5)
                            TextButton.icon(
                              onPressed: _addKeyResult,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Adicionar'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (
                        int index = 0;
                        index < _keyResults.length;
                        index++
                      ) ...[
                        _KeyResultEditor(
                          value: _keyResults[index],
                          index: index,
                          canRemove: _keyResults.length > 1,
                          onRemove: () => _removeKeyResult(index),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        onPressed: _isSubmitting ? null : _save,
                        child: Text(
                          _isSubmitting ? 'Salvando...' : 'Salvar objetivo',
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _loadInitialData(
    List<OkrCycle> cycles,
    List<Category> categories,
    OkrObjectiveProgress? editing,
  ) {
    if (_didLoadInitialData) return;
    _didLoadInitialData = true;

    if (editing != null) {
      final objective = editing.objective;
      _titleController.text = objective.title;
      _descriptionController.text = objective.description ?? '';
      _cycleId = objective.cycleId;
      _categoryId = objective.categoryId;
      _status = objective.status;
      _checkInFrequencyDays = objective.checkInFrequencyDays;
      _startDate = objective.startDate;
      _endDate = objective.endDate;
      for (final item in editing.keyResults) {
        _keyResults.add(_KeyResultFormValue.fromProgress(item));
      }
      return;
    }

    final currentCycle =
        cycles.where((item) => item.status == OkrCycleStatus.active).toList();
    final cycle =
        currentCycle.isNotEmpty
            ? currentCycle.first
            : (cycles.isEmpty ? null : cycles.first);
    _cycleId = cycle?.id;
    _startDate = cycle?.startDate;
    _endDate = cycle?.endDate;
    _categoryId = categories.isEmpty ? null : categories.first.id;
    _keyResults.add(_KeyResultFormValue.initial());
  }

  void _addKeyResult() {
    if (_keyResults.length >= 5) return;
    setState(() => _keyResults.add(_KeyResultFormValue.initial()));
  }

  void _removeKeyResult(int index) {
    final item = _keyResults.removeAt(index);
    item.dispose();
    setState(() {});
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(2026, 7, 20),
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
      locale: const Locale('pt', 'BR'),
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_cycleId == null || _categoryId == null) return;
    if (_startDate == null || _endDate == null) return;

    final drafts = <KeyResultDraft>[];
    for (final item in _keyResults) {
      final draft = item.toDraft();
      if (draft == null) {
        _showMessage('Revise os resultados-chave antes de salvar.');
        return;
      }
      drafts.add(draft);
    }

    if (drafts.isEmpty) {
      _showMessage('Adicione ao menos um resultado-chave.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final original =
          widget.objectiveId == null
              ? null
              : ref
                  .watch(okrObjectiveProgressProvider(widget.objectiveId!))
                  ?.objective;

      await ref
          .read(okrManagementControllerProvider.notifier)
          .saveObjective(
            original: original,
            title: _titleController.text,
            description: _descriptionController.text,
            cycleId: _cycleId!,
            categoryId: _categoryId!,
            startDate: _startDate!,
            endDate: _endDate!,
            status: _status,
            checkInFrequencyDays: _checkInFrequencyDays,
            keyResults: drafts,
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null
              ? 'Selecionar'
              : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}',
        ),
      ),
    );
  }
}

class _KeyResultEditor extends StatefulWidget {
  const _KeyResultEditor({
    required this.value,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  final _KeyResultFormValue value;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  State<_KeyResultEditor> createState() => _KeyResultEditorState();
}

class _KeyResultEditorState extends State<_KeyResultEditor> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Resultado-chave ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (widget.canRemove)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.value.titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o título';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<KeyResultMeasurementType>(
              value: widget.value.measurementType,
              decoration: const InputDecoration(labelText: 'Tipo de medição'),
              items:
                  KeyResultMeasurementType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => widget.value.measurementType = value);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.value.initialValueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor inicial',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: widget.value.currentValueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Valor atual'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: widget.value.targetValueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor desejado',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.value.unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unidade (opcional)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: widget.value.weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Peso (opcional)',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyResultFormValue {
  _KeyResultFormValue({
    this.id,
    required this.measurementType,
    required this.titleController,
    required this.initialValueController,
    required this.currentValueController,
    required this.targetValueController,
    required this.unitController,
    required this.weightController,
  });

  final String? id;
  KeyResultMeasurementType measurementType;
  final TextEditingController titleController;
  final TextEditingController initialValueController;
  final TextEditingController currentValueController;
  final TextEditingController targetValueController;
  final TextEditingController unitController;
  final TextEditingController weightController;

  factory _KeyResultFormValue.initial() {
    return _KeyResultFormValue(
      measurementType: KeyResultMeasurementType.numeric,
      titleController: TextEditingController(),
      initialValueController: TextEditingController(text: '0'),
      currentValueController: TextEditingController(text: '0'),
      targetValueController: TextEditingController(text: '1'),
      unitController: TextEditingController(),
      weightController: TextEditingController(),
    );
  }

  factory _KeyResultFormValue.fromProgress(KeyResultProgress progress) {
    return _KeyResultFormValue(
      id: progress.keyResult.id,
      measurementType: progress.keyResult.measurementType,
      titleController: TextEditingController(text: progress.keyResult.title),
      initialValueController: TextEditingController(
        text: progress.keyResult.initialValue.toString(),
      ),
      currentValueController: TextEditingController(
        text: progress.keyResult.currentValue.toString(),
      ),
      targetValueController: TextEditingController(
        text: progress.keyResult.targetValue.toString(),
      ),
      unitController: TextEditingController(
        text: progress.keyResult.unit ?? '',
      ),
      weightController: TextEditingController(
        text: progress.keyResult.weight?.toString() ?? '',
      ),
    );
  }

  KeyResultDraft? toDraft() {
    final title = titleController.text.trim();
    final initialValue = double.tryParse(
      initialValueController.text.replaceAll(',', '.'),
    );
    final currentValue = double.tryParse(
      currentValueController.text.replaceAll(',', '.'),
    );
    final targetValue = double.tryParse(
      targetValueController.text.replaceAll(',', '.'),
    );
    final weightText = weightController.text.trim();
    final weight =
        weightText.isEmpty
            ? null
            : double.tryParse(weightText.replaceAll(',', '.'));

    if (title.isEmpty ||
        initialValue == null ||
        currentValue == null ||
        targetValue == null) {
      return null;
    }

    return KeyResultDraft(
      id: id,
      title: title,
      measurementType: measurementType,
      initialValue: initialValue,
      currentValue: currentValue,
      targetValue: targetValue,
      unit: unitController.text.trim(),
      weight: weight,
    );
  }

  void dispose() {
    titleController.dispose();
    initialValueController.dispose();
    currentValueController.dispose();
    targetValueController.dispose();
    unitController.dispose();
    weightController.dispose();
  }
}
