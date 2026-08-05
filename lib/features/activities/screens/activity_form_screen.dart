import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/icon_mapper.dart';
import '../../../core/utils/time_of_day_utils.dart';
import '../../../data/models/activity.dart';
import '../../../state/activities_controller.dart';
import '../../../state/categories_controller.dart';
import '../../../state/okr_workspace_controller.dart';

class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({
    super.key,
    this.activity,
    this.initialObjectiveId,
    this.initialKeyResultId,
  });

  final Activity? activity;
  final String? initialObjectiveId;
  final String? initialKeyResultId;

  bool get isEditing => activity != null;

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _categoryId;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<int> _weekdays = [];
  int _weeklyTargetCount = 4;
  ActivityRecurrence _recurrence = ActivityRecurrence.flexible;
  DateTime? _scheduledDate;
  int? _selectedColor;
  String? _iconKey;
  String? _objectiveId;
  String? _keyResultId;
  bool _isActive = true;
  bool _remindersEnabled = false;
  bool _isSubmitting = false;

  static const _colorOptions = [
    0xFF5A7DFA,
    0xFF3FAE7A,
    0xFFE6007A,
    0xFFFF2DA6,
    0xFFFF4FD8,
    0xFF9A6DF5,
    0xFF259D9B,
    0xFFE09A3C,
    0xFFCF6F89,
  ];

  static const _primaryIconOptions = [
    'favorite',
    'work',
    'school',
    'bolt',
    'home',
    'person',
    'self_improvement',
    'menu_book',
    'fitness',
    'checklist',
  ];

  static const _allIconOptions = [
    ..._primaryIconOptions,
    'run',
    'water',
    'bed',
    'alarm',
    'book',
    'code',
    'laptop',
    'calendar',
    'wallet',
    'shopping',
    'car',
    'flight',
    'music',
    'movie',
    'camera',
    'clean',
    'restaurant',
    'pets',
    'nature',
    'meditation',
    'phone',
    'mail',
    'chat',
    'family',
    'medicine',
    'heart',
    'target',
    'trophy',
    'lightbulb',
    'star',
    'sun',
    'moon',
    'build',
    'brush',
    'language',
    'public',
    'security',
    'volunteer',
    'payments',
    'savings',
  ];

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    if (activity != null) {
      _nameController.text = activity.name;
      _descriptionController.text = activity.description ?? '';
      _categoryId = activity.categoryId;
      _weekdays = List<int>.from(activity.weekdays);
      _weeklyTargetCount = activity.effectiveWeeklyTargetCount == 0
          ? 4
          : activity.effectiveWeeklyTargetCount;
      _recurrence = activity.recurrence;
      _scheduledDate = activity.scheduledDate;
      _selectedColor = activity.colorHex;
      _iconKey = activity.iconKey;
      _objectiveId = activity.objectiveId;
      _keyResultId = activity.keyResultId;
      _isActive = activity.isActive;
      _remindersEnabled = activity.remindersEnabled;
      if (activity.startMinutes != null) {
        _startTime = TimeOfDayUtils.fromMinutes(activity.startMinutes!);
      }
      if (activity.endMinutes != null) {
        _endTime = TimeOfDayUtils.fromMinutes(activity.endMinutes!);
      }
    } else {
      _weekdays = [1, 2, 3, 4];
      _weeklyTargetCount = 4;
      _recurrence = ActivityRecurrence.weekly;
      _iconKey = 'checklist';
      _selectedColor = _colorOptions.first;
      _objectiveId = widget.initialObjectiveId;
      _keyResultId = widget.initialKeyResultId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final workspace = ref.watch(okrWorkspaceControllerProvider).valueOrNull;
    final objectives = workspace?.allObjectives ?? const [];
    final objectiveMatches =
        objectives.where((item) => item.objective.id == _objectiveId).toList();
    final selectedObjective =
        objectiveMatches.isEmpty ? null : objectiveMatches.first;
    final keyResults = selectedObjective?.keyResults ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar ação' : 'Nova ação'),
      ),
      body: SafeArea(
        top: false,
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (categories) {
            final fallbackCategory =
                categories.isNotEmpty ? categories.first.id : null;
            _categoryId ??= fallbackCategory;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da ação',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe um nome';
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
                  DropdownButtonFormField<String?>(
                    value: _objectiveId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sem objetivo vinculado'),
                      ),
                      ...objectives.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.objective.id,
                          child: Text(item.objective.title),
                        ),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Objetivo (opcional)',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _objectiveId = value;
                        if (_objectiveId == null) {
                          _keyResultId = null;
                        } else {
                          final matches =
                              objectives
                                  .where(
                                    (item) => item.objective.id == _objectiveId,
                                  )
                                  .toList();
                          if (matches.isEmpty) {
                            _keyResultId = null;
                          } else if (!matches.first.keyResults.any(
                            (item) => item.keyResult.id == _keyResultId,
                          )) {
                            _keyResultId = null;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _keyResultId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sem resultado-chave específico'),
                      ),
                      ...keyResults.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.keyResult.id,
                          child: Text(item.keyResult.title),
                        ),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Resultado-chave (opcional)',
                    ),
                    onChanged:
                        _objectiveId == null
                            ? null
                            : (value) => setState(() => _keyResultId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    items:
                        categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _createCategoryInline,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Cadastrar categoria'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeInput(
                          label: 'Horário inicial',
                          value: _startTime,
                          onPick: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  _startTime ??
                                  const TimeOfDay(hour: 7, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _startTime = picked);
                            }
                          },
                          onClear: () => setState(() => _startTime = null),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimeInput(
                          label: 'Horário final',
                          value: _endTime,
                          onPick: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  _endTime ??
                                  const TimeOfDay(hour: 8, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _endTime = picked);
                            }
                          },
                          onClear: () => setState(() => _endTime = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ActivityRecurrence>(
                    value: _recurrence,
                    decoration: const InputDecoration(labelText: 'Cadência'),
                    items:
                        ActivityRecurrence.values
                            .map(
                              (recurrence) => DropdownMenuItem(
                                value: recurrence,
                                child: Text(recurrence.label),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _recurrence = value;
                        switch (_recurrence) {
                          case ActivityRecurrence.daily:
                            _weekdays = [1, 2, 3, 4, 5, 6, 7];
                            _weeklyTargetCount = 7;
                            break;
                          case ActivityRecurrence.weekly:
                            _weekdays =
                                _weekdays.isEmpty ? [1, 2, 3, 4] : _weekdays;
                            _weeklyTargetCount =
                                _weeklyTargetCount.clamp(1, 7);
                            break;
                          case ActivityRecurrence.weeklyFixed:
                            _weekdays =
                                _weekdays.isEmpty ? [1, 2, 3, 4, 5] : _weekdays;
                            break;
                          case ActivityRecurrence.oneOff:
                            _scheduledDate ??= DateTime(2026, 7, 20);
                            _weekdays = [];
                            _weeklyTargetCount = 1;
                            break;
                          case ActivityRecurrence.monthly:
                          case ActivityRecurrence.flexible:
                            _weekdays = [];
                            _weeklyTargetCount = 1;
                            break;
                        }
                      });
                    },
                  ),
                  if (_recurrence == ActivityRecurrence.weekly) ...[
                    const SizedBox(height: 12),
                    _WeeklyTargetCard(
                      value: _weeklyTargetCount,
                      onChanged:
                          (value) => setState(() => _weeklyTargetCount = value),
                    ),
                  ],
                  if (_recurrence == ActivityRecurrence.oneOff ||
                      _recurrence == ActivityRecurrence.monthly) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickScheduledDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de referência',
                        ),
                        child: Text(
                          _scheduledDate == null
                              ? 'Selecionar data'
                              : '${_scheduledDate!.day.toString().padLeft(2, '0')}/${_scheduledDate!.month.toString().padLeft(2, '0')}/${_scheduledDate!.year}',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _recurrence == ActivityRecurrence.oneOff ||
                            _recurrence == ActivityRecurrence.flexible
                        ? 'Ações únicas aparecem como próximos passos do objetivo.'
                        : _recurrence == ActivityRecurrence.weekly
                        ? 'Metas semanais flexíveis aparecem até você bater a meta da semana.'
                        : 'Ações recorrentes aparecem como iniciativas do objetivo.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _recurrence == ActivityRecurrence.weekly
                        ? 'Dias sugeridos'
                        : 'Dias da semana',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_recurrence == ActivityRecurrence.weekly ||
                      _recurrence == ActivityRecurrence.weeklyFixed)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (index) {
                        final day = index + 1;
                        final selected = _weekdays.contains(day);
                        const labels = [
                          'Seg',
                          'Ter',
                          'Qua',
                          'Qui',
                          'Sex',
                          'Sab',
                          'Dom',
                        ];

                        return FilterChip(
                          label: Text(labels[index]),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _weekdays = [..._weekdays, day]..sort();
                              } else {
                                _weekdays =
                                    _weekdays.where((d) => d != day).toList();
                              }
                            });
                          },
                        );
                      }),
                    )
                  else
                    Text(
                      _recurrence == ActivityRecurrence.daily
                          ? 'Essa ação aparecerá todos os dias.'
                          : _recurrence == ActivityRecurrence.weekly
                          ? 'Os dias servem como sugestão. A meta continua disponível em qualquer dia da semana até ser concluída.'
                          : _recurrence == ActivityRecurrence.weeklyFixed
                          ? 'Essa ação só aparece nos dias fixos escolhidos.'
                          : _recurrence == ActivityRecurrence.oneOff
                          ? 'Essa ação será exibida apenas na data definida.'
                          : _recurrence == ActivityRecurrence.monthly
                          ? 'A data escolhida serve como referência mensal.'
                          : 'Sem recorrência fixa. Use quando quiser manter a tarefa disponível sem agenda.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Cor do card',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _colorOptions.map((color) {
                          return _ColorOptionSwatch(
                            color: Color(color),
                            selected: _selectedColor == color,
                            onTap: () => setState(() => _selectedColor = color),
                            size: 38,
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Ícone', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _primaryIconOptions.map((key) {
                          final selected = _iconKey == key;
                          return ChoiceChip(
                            label: Icon(IconMapper.fromKey(key), size: 18),
                            selected: selected,
                            onSelected: (_) => setState(() => _iconKey = key),
                          );
                        }).toList(),
                  ),
                  if (_iconKey != null &&
                      !_primaryIconOptions.contains(_iconKey))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Text(
                            'Selecionado:',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Icon(IconMapper.fromKey(_iconKey), size: 18),
                            selected: true,
                            onSelected: (_) {},
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _openAllIconsPicker,
                      icon: const Icon(Icons.grid_view_rounded),
                      label: const Text('Ver todos os ícones'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Ação ativa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Quando desativada, esta atividade não aparece na rotina diária.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Lembretes locais',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _recurrence == ActivityRecurrence.weekly
                          ? 'Quando ativado, o app continua lembrando no horário definido até você bater a meta semanal.'
                          : 'Quando ativado, o app envia uma notificação no horário inicial da atividade.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                    value: _remindersEnabled,
                    onChanged:
                        (value) => setState(() => _remindersEnabled = value),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _save,
                    child: Text(_isSubmitting ? 'Salvando...' : 'Salvar ação'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;
    if (_recurrence == ActivityRecurrence.weeklyFixed && _weekdays.isEmpty) {
      _showMessage('Selecione ao menos um dia fixo da semana.');
      return;
    }
    if (_recurrence == ActivityRecurrence.weekly &&
        (_weeklyTargetCount < 1 || _weeklyTargetCount > 7)) {
      _showMessage('Defina uma meta semanal entre 1 e 7 vezes.');
      return;
    }
    if ((_recurrence == ActivityRecurrence.oneOff ||
            _recurrence == ActivityRecurrence.monthly) &&
        _scheduledDate == null) {
      _showMessage('Selecione uma data de referência.');
      return;
    }

    if (_categoryId == null) {
      _showMessage('Selecione uma categoria.');
      return;
    }

    setState(() => _isSubmitting = true);

    final controller = ref.read(activitiesControllerProvider.notifier);

    if (widget.activity == null) {
      await controller.create(
        name: _nameController.text,
        description: _descriptionController.text,
        categoryId: _categoryId!,
        weekdays: _weekdays,
        weeklyTargetCount:
            _recurrence == ActivityRecurrence.weekly ? _weeklyTargetCount : null,
        recurrence: _recurrence,
        startMinutes:
            _startTime == null ? null : TimeOfDayUtils.toMinutes(_startTime!),
        endMinutes:
            _endTime == null ? null : TimeOfDayUtils.toMinutes(_endTime!),
        colorHex: _selectedColor,
        iconKey: _iconKey,
        objectiveId: _objectiveId,
        keyResultId: _keyResultId,
        scheduledDate: _scheduledDate,
        isActive: _isActive,
        remindersEnabled: _remindersEnabled,
      );
    } else {
      final current = widget.activity!;
      await controller.updateActivity(
        current.copyWith(
          name: _nameController.text.trim(),
          description:
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
          categoryId: _categoryId ?? current.categoryId,
          weekdays: _weekdays,
          weeklyTargetCount:
              _recurrence == ActivityRecurrence.weekly
                  ? _weeklyTargetCount
                  : null,
          recurrence: _recurrence,
          startMinutes:
              _startTime == null ? null : TimeOfDayUtils.toMinutes(_startTime!),
          endMinutes:
              _endTime == null ? null : TimeOfDayUtils.toMinutes(_endTime!),
          colorHex: _selectedColor,
          iconKey: _iconKey,
          objectiveId: _objectiveId,
          keyResultId: _keyResultId,
          scheduledDate: _scheduledDate,
          isActive: _isActive,
          remindersEnabled: _remindersEnabled,
          updatedAt: DateTime.now(),
          clearDescription: _descriptionController.text.trim().isEmpty,
          clearStartMinutes: _startTime == null,
          clearEndMinutes: _endTime == null,
          clearColor: _selectedColor == null,
          clearIcon: _iconKey == null,
          clearObjectiveId: _objectiveId == null,
          clearKeyResultId: _keyResultId == null,
          clearScheduledDate: _scheduledDate == null,
          clearWeeklyTargetCount: _recurrence != ActivityRecurrence.weekly,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _createCategoryInline() async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder:
          (_) => const _CreateCategoryDialog(
            colorOptions: _colorOptions,
            iconOptions: _primaryIconOptions,
          ),
    );

    if (draft == null) return;

    final category = await ref
        .read(categoriesControllerProvider.notifier)
        .createCategory(
          name: draft.name,
          colorHex: draft.colorHex,
          iconKey: draft.iconKey,
        );

    if (category == null || !mounted) return;

    setState(() => _categoryId = category.id);
    _showMessage('Categoria "${category.name}" criada.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _openAllIconsPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return _IconPickerBottomSheet(
          icons: _allIconOptions,
          selected: _iconKey,
        );
      },
    );

    if (selected == null) return;
    setState(() => _iconKey = selected);
  }

  Future<void> _pickScheduledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime(2026, 7, 20),
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
      locale: const Locale('pt', 'BR'),
    );

    if (picked == null) return;
    setState(() => _scheduledDate = picked);
  }
}

class _CategoryDraft {
  const _CategoryDraft({
    required this.name,
    required this.colorHex,
    required this.iconKey,
  });

  final String name;
  final int colorHex;
  final String iconKey;
}

class _WeeklyTargetCard extends StatelessWidget {
  const _WeeklyTargetCard({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meta por semana',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Essa iniciativa continua disponível até completar ${value}x na semana.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: value < 7 ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog({
    required this.colorOptions,
    required this.iconOptions,
  });

  final List<int> colorOptions;
  final List<String> iconOptions;

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  int? _selectedColor;
  String? _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.colorOptions.first;
    _selectedIcon = widget.iconOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova categoria'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome da categoria'),
            ),
            const SizedBox(height: 12),
            const Text('Cor'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.colorOptions.map((color) {
                    return _ColorOptionSwatch(
                      color: Color(color),
                      selected: _selectedColor == color,
                      onTap: () => setState(() => _selectedColor = color),
                      size: 34,
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),
            const Text('Ícone'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.iconOptions.map((key) {
                    final selected = _selectedIcon == key;
                    return ChoiceChip(
                      label: Icon(IconMapper.fromKey(key), size: 18),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedIcon = key),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty ||
                _selectedColor == null ||
                _selectedIcon == null) {
              return;
            }
            Navigator.of(context).pop(
              _CategoryDraft(
                name: name,
                colorHex: _selectedColor!,
                iconKey: _selectedIcon!,
              ),
            );
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

class _IconPickerBottomSheet extends StatelessWidget {
  const _IconPickerBottomSheet({required this.icons, required this.selected});

  final List<String> icons;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha um ícone',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: icons.length,
                itemBuilder: (context, index) {
                  final key = icons[index];
                  final isSelected = selected == key;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(key),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.18)
                                : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Icon(
                        IconMapper.fromKey(key),
                        size: 22,
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeInput extends StatelessWidget {
  const _TimeInput({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final TimeOfDay? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'Não definido' : TimeOfDayUtils.format(value!),
              ),
            ),
            if (value != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorOptionSwatch extends StatelessWidget {
  const _ColorOptionSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.size,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor =
        color.computeLuminance() > 0.62 ? Colors.black : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color:
                selected
                    ? scheme.primary
                    : scheme.outline.withValues(alpha: 0.45),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  selected
                      ? scheme.primary.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.08),
              blurRadius: selected ? 10 : 4,
              spreadRadius: selected ? 1 : 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: selected ? 1 : 0,
          child: Icon(Icons.check_rounded, size: size * 0.52, color: iconColor),
        ),
      ),
    );
  }
}
