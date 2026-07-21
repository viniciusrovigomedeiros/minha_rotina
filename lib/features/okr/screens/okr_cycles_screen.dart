import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/okr_cycle.dart';
import '../../../state/okr_management_controller.dart';
import '../../../state/okr_workspace_controller.dart';

class OkrCyclesScreen extends ConsumerWidget {
  const OkrCyclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceAsync = ref.watch(okrWorkspaceControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ciclos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateCycleDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo ciclo'),
      ),
      body: SafeArea(
        top: false,
        child: workspaceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (workspace) {
            if (workspace.cycleProgresses.isEmpty) {
              return const Center(child: Text('Nenhum ciclo disponível.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemBuilder: (context, index) {
                final item = workspace.cycleProgresses[index];
                final percent = (item.progress * 100).round();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.cycle.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(item.cycle.startDate)} - ${DateFormat('dd/MM/yyyy').format(item.cycle.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: item.progress),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(
                              label: 'Status',
                              value: item.cycle.status.label,
                            ),
                            _InfoPill(label: 'Progresso', value: '$percent%'),
                            _InfoPill(
                              label: 'Objetivos',
                              value: '${item.objectives.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: workspace.cycleProgresses.length,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreateCycleDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<_CycleDraft>(
      context: context,
      builder: (_) => const _CreateCycleDialog(),
    );

    if (result == null) return;
    await ref
        .read(okrManagementControllerProvider.notifier)
        .createCycle(
          name: result.name,
          startDate: result.startDate,
          endDate: result.endDate,
        );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CycleDraft {
  const _CycleDraft({
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final String name;
  final DateTime startDate;
  final DateTime endDate;
}

class _CreateCycleDialog extends StatefulWidget {
  const _CreateCycleDialog();

  @override
  State<_CreateCycleDialog> createState() => _CreateCycleDialogState();
}

class _CreateCycleDialogState extends State<_CreateCycleDialog> {
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime(2026, 7, 1);
  DateTime _endDate = DateTime(2026, 9, 30);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo ciclo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 12),
          _DialogDateField(
            label: 'Início',
            value: _startDate,
            onTap: () => _pickDate(isStart: true),
          ),
          const SizedBox(height: 10),
          _DialogDateField(
            label: 'Fim',
            value: _endDate,
            onTap: () => _pickDate(isStart: false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            Navigator.of(context).pop(
              _CycleDraft(
                name: _nameController.text.trim(),
                startDate: _startDate,
                endDate: _endDate,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }
}

class _DialogDateField extends StatelessWidget {
  const _DialogDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(DateFormat('dd/MM/yyyy').format(value)),
      ),
    );
  }
}
