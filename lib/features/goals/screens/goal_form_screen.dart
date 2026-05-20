import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/weekly_goal_progress_utils.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/category.dart';
import '../../../data/models/weekly_goal.dart';
import '../../../state/activities_controller.dart';
import '../../../state/categories_controller.dart';
import '../../../state/goals_controller.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goal});

  final WeeklyGoal? goal;

  bool get isEditing => goal != null;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController();
  final _unitController = TextEditingController();

  late GoalTrackingMode _trackingMode;
  late GoalPeriod _period;
  late WeeklyGoalType _type;
  late WeeklyGoalScope _scope;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _activityId;
  String? _categoryId;
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    if (goal != null) {
      _nameController.text = goal.name;
      _targetController.text = _formatNumber(goal.targetValue);
      _currentController.text = _formatNumber(goal.currentValue);
      _unitController.text = goal.unit ?? '';
      _trackingMode = goal.trackingMode;
      _period = goal.period;
      _type = goal.type ?? WeeklyGoalType.completions;
      _scope = goal.scope ?? WeeklyGoalScope.overall;
      _activityId = goal.activityId;
      _categoryId = goal.categoryId;
      _startDate = goal.startDate;
      _endDate = goal.endDate;
      _isActive = goal.isActive;
    } else {
      _trackingMode = GoalTrackingMode.automatic;
      _period = GoalPeriod.week;
      _type = WeeklyGoalType.completions;
      _scope = WeeklyGoalScope.overall;
      _targetController.text = '5';
      _currentController.text = '0';
      _unitController.text = '%';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar meta' : 'Nova meta'),
      ),
      body: SafeArea(
        top: false,
        child: activitiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (activities) {
            return categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => Center(child: Text('Erro ao carregar: $error')),
              data: (categories) {
                _ensureScopeSelection(activities, categories);

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Tipo de meta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final mode in GoalTrackingMode.values)
                            ChoiceChip(
                              selected: _trackingMode == mode,
                              onSelected:
                                  (_) => setState(() {
                                    _trackingMode = mode;
                                    if (_trackingMode ==
                                        GoalTrackingMode.manual) {
                                      _period =
                                          _period == GoalPeriod.week
                                              ? GoalPeriod.year
                                              : _period;
                                      _scope = WeeklyGoalScope.overall;
                                      _activityId = null;
                                      _categoryId = null;
                                    } else {
                                      _unitController.clear();
                                      _currentController.text = '0';
                                    }
                                  }),
                              label: Text(mode.label),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _trackingMode.helperText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nome da meta',
                          hintText:
                              _trackingMode == GoalTrackingMode.manual
                                  ? 'Ex: Ficar fluente em inglês'
                                  : 'Ex: Fechar 12 conclusões no mês',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe um nome para a meta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<GoalPeriod>(
                        value: _period,
                        decoration: const InputDecoration(labelText: 'Período'),
                        items:
                            GoalPeriod.values
                                .map(
                                  (period) => DropdownMenuItem(
                                    value: period,
                                    child: Text(period.label),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _period = value;
                            if (_period != GoalPeriod.custom) {
                              _startDate = null;
                              _endDate = null;
                            } else {
                              final now = DateTime.now();
                              _startDate ??= DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              _endDate ??= _startDate!.add(
                                const Duration(days: 89),
                              );
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _periodHelperText(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_period == GoalPeriod.custom) ...[
                        const SizedBox(height: 14),
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
                      ],
                      const SizedBox(height: 14),
                      if (_trackingMode == GoalTrackingMode.automatic) ...[
                        DropdownButtonFormField<WeeklyGoalType>(
                          value: _type,
                          decoration: const InputDecoration(
                            labelText: 'Métrica automática',
                          ),
                          items:
                              WeeklyGoalType.values
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type.label),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _type = value);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _type.helperText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<WeeklyGoalScope>(
                          value: _scope,
                          decoration: const InputDecoration(
                            labelText: 'Escopo',
                          ),
                          items:
                              WeeklyGoalScope.values
                                  .map(
                                    (scope) => DropdownMenuItem(
                                      value: scope,
                                      child: Text(scope.label),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _scope = value;
                              if (_scope != WeeklyGoalScope.activity) {
                                _activityId = null;
                              }
                              if (_scope != WeeklyGoalScope.category) {
                                _categoryId = null;
                              }
                            });
                          },
                        ),
                        if (_scope == WeeklyGoalScope.activity) ...[
                          const SizedBox(height: 14),
                          _ActivitySelector(
                            activities: activities,
                            value: _activityId,
                            onChanged:
                                (value) => setState(() => _activityId = value),
                          ),
                        ],
                        if (_scope == WeeklyGoalScope.category) ...[
                          const SizedBox(height: 14),
                          _CategorySelector(
                            categories: categories,
                            value: _categoryId,
                            onChanged:
                                (value) => setState(() => _categoryId = value),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ] else ...[
                        TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unidade',
                            hintText: 'Ex: %, livros, R\$, nível',
                          ),
                          validator: (value) {
                            if (_trackingMode == GoalTrackingMode.manual &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Informe a unidade da meta';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _currentController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Valor atual',
                            hintText: 'Ex: 35',
                          ),
                          validator: (value) {
                            final currentValue = _parseNumber(value);
                            if (_trackingMode == GoalTrackingMode.manual &&
                                currentValue == null) {
                              return 'Informe o valor atual';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              _trackingMode == GoalTrackingMode.manual
                                  ? 'Valor alvo'
                                  : 'Meta numérica',
                          hintText:
                              _trackingMode == GoalTrackingMode.manual
                                  ? 'Ex: 100'
                                  : (_type == WeeklyGoalType.qualityPoints
                                      ? '7.5'
                                      : '12'),
                        ),
                        validator: (value) {
                          final target = _parseNumber(value);
                          if (target == null || target <= 0) {
                            return 'Informe um valor alvo válido';
                          }
                          if (_trackingMode == GoalTrackingMode.automatic &&
                              _type != WeeklyGoalType.qualityPoints &&
                              target != target.roundToDouble()) {
                            return 'Use número inteiro para esse tipo de meta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Meta ativa'),
                        subtitle: const Text(
                          'Metas inativas ficam salvas, mas saem do dashboard e dos lembretes.',
                        ),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed:
                            _isSubmitting
                                ? null
                                : () => _submit(activities, categories),
                        icon: const Icon(Icons.flag_rounded),
                        label: Text(
                          widget.isEditing ? 'Salvar meta' : 'Criar meta',
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

  Future<void> _submit(
    List<Activity> activities,
    List<Category> categories,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (_trackingMode == GoalTrackingMode.automatic) {
      if (_scope == WeeklyGoalScope.activity && _activityId == null) return;
      if (_scope == WeeklyGoalScope.category && _categoryId == null) return;
    }
    if (_period == GoalPeriod.custom &&
        (_startDate == null || _endDate == null)) {
      return;
    }

    final targetValue = _parseNumber(_targetController.text);
    final currentValue =
        _trackingMode == GoalTrackingMode.manual
            ? _parseNumber(_currentController.text)
            : 0.0;
    if (targetValue == null) return;
    if (_trackingMode == GoalTrackingMode.manual && currentValue == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    if (widget.goal == null) {
      await ref
          .read(goalsControllerProvider.notifier)
          .create(
            name: _nameController.text.trim(),
            trackingMode: _trackingMode,
            period: _period,
            type: _trackingMode == GoalTrackingMode.automatic ? _type : null,
            scope: _trackingMode == GoalTrackingMode.automatic ? _scope : null,
            targetValue: targetValue,
            currentValue:
                _trackingMode == GoalTrackingMode.manual ? currentValue! : 0,
            activityId:
                _trackingMode == GoalTrackingMode.automatic &&
                        _scope == WeeklyGoalScope.activity
                    ? _activityId
                    : null,
            categoryId:
                _trackingMode == GoalTrackingMode.automatic &&
                        _scope == WeeklyGoalScope.category
                    ? _categoryId
                    : null,
            unit:
                _trackingMode == GoalTrackingMode.manual
                    ? _unitController.text.trim()
                    : null,
            startDate: _period == GoalPeriod.custom ? _startDate : null,
            endDate: _period == GoalPeriod.custom ? _endDate : null,
            isActive: _isActive,
          );
    } else {
      await ref
          .read(goalsControllerProvider.notifier)
          .updateGoal(
            widget.goal!.copyWith(
              name: _nameController.text.trim(),
              trackingMode: _trackingMode,
              period: _period,
              type: _trackingMode == GoalTrackingMode.automatic ? _type : null,
              scope:
                  _trackingMode == GoalTrackingMode.automatic ? _scope : null,
              targetValue: targetValue,
              currentValue:
                  _trackingMode == GoalTrackingMode.manual ? currentValue! : 0,
              isActive: _isActive,
              activityId:
                  _trackingMode == GoalTrackingMode.automatic &&
                          _scope == WeeklyGoalScope.activity
                      ? _activityId
                      : null,
              categoryId:
                  _trackingMode == GoalTrackingMode.automatic &&
                          _scope == WeeklyGoalScope.category
                      ? _categoryId
                      : null,
              unit:
                  _trackingMode == GoalTrackingMode.manual
                      ? _unitController.text.trim()
                      : null,
              startDate: _period == GoalPeriod.custom ? _startDate : null,
              endDate: _period == GoalPeriod.custom ? _endDate : null,
              clearType: _trackingMode == GoalTrackingMode.manual,
              clearScope: _trackingMode == GoalTrackingMode.manual,
              clearActivityId:
                  _trackingMode == GoalTrackingMode.manual ||
                  _scope != WeeklyGoalScope.activity,
              clearCategoryId:
                  _trackingMode == GoalTrackingMode.manual ||
                  _scope != WeeklyGoalScope.category,
              clearUnit: _trackingMode == GoalTrackingMode.automatic,
              clearStartDate: _period != GoalPeriod.custom,
              clearEndDate: _period != GoalPeriod.custom,
            ),
          );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _ensureScopeSelection(
    List<Activity> activities,
    List<Category> categories,
  ) {
    if (_trackingMode == GoalTrackingMode.manual) return;

    if (_scope == WeeklyGoalScope.activity &&
        activities.isNotEmpty &&
        (_activityId == null ||
            !activities.any((activity) => activity.id == _activityId))) {
      _activityId = activities.first.id;
    }

    if (_scope == WeeklyGoalScope.category &&
        categories.isNotEmpty &&
        (_categoryId == null ||
            !categories.any((category) => category.id == _categoryId))) {
      _categoryId = categories.first.id;
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial =
        isStart
            ? (_startDate ?? DateTime.now())
            : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day);
        if (_startDate != null && _endDate!.isBefore(_startDate!)) {
          _startDate = _endDate;
        }
      }
    });
  }

  String _periodHelperText() {
    if (_period == GoalPeriod.custom) {
      return 'Use datas livres para metas com prazo específico.';
    }

    final probeGoal = WeeklyGoal(
      id: 'preview',
      name: 'preview',
      trackingMode: _trackingMode,
      period: _period,
      type: _trackingMode == GoalTrackingMode.automatic ? _type : null,
      scope: _trackingMode == GoalTrackingMode.automatic ? _scope : null,
      targetValue: 1,
      currentValue: 0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final range = WeeklyGoalProgressUtils.resolveRange(goal: probeGoal);
    return 'Período atual: ${_formatDate(range.start)} até ${_formatDate(range.end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  double? _parseNumber(String? raw) {
    final normalized = raw?.trim().replaceAll(',', '.');
    if (normalized == null || normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _ActivitySelector extends StatelessWidget {
  const _ActivitySelector({
    required this.activities,
    required this.value,
    required this.onChanged,
  });

  final List<Activity> activities;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: activities.isEmpty ? null : value,
      decoration: const InputDecoration(labelText: 'Atividade'),
      items:
          activities
              .map(
                (activity) => DropdownMenuItem(
                  value: activity.id,
                  child: Text(activity.name),
                ),
              )
              .toList(),
      onChanged: activities.isEmpty ? null : onChanged,
      validator: (_) {
        if (activities.isEmpty) {
          return 'Cadastre uma atividade antes de criar essa meta';
        }
        if (value == null) {
          return 'Selecione uma atividade';
        }
        return null;
      },
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<Category> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: categories.isEmpty ? null : value,
      decoration: const InputDecoration(labelText: 'Categoria'),
      items:
          categories
              .map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
              )
              .toList(),
      onChanged: categories.isEmpty ? null : onChanged,
      validator: (_) {
        if (categories.isEmpty) {
          return 'Cadastre uma categoria antes de criar essa meta';
        }
        if (value == null) {
          return 'Selecione uma categoria';
        }
        return null;
      },
    );
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
