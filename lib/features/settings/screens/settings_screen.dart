import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/local_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_of_day_utils.dart';
import '../../../state/activities_controller.dart';
import '../../../state/categories_controller.dart';
import '../../../state/history_controller.dart';
import '../../../state/motivation_phrases_controller.dart';
import '../../../state/providers.dart';
import '../../../state/today_controller.dart';
import '../../../state/user_settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _newPhraseController = TextEditingController();
  bool _isBusy = false;
  bool _didLoadInitialName = false;

  @override
  void dispose() {
    _nameController.dispose();
    _newPhraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsControllerProvider);
    final phrasesAsync = ref.watch(motivationPhrasesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        top: false,
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (settings) {
            final phrases = phrasesAsync.valueOrNull ?? const <String>[];

            if (!_didLoadInitialName) {
              _nameController.text = settings.userName;
              _didLoadInitialName = true;
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Nome para saudação',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Ex: Ronald'),
                  onSubmitted: (_) => _saveName(),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _isBusy ? null : _saveName,
                  child: const Text('Salvar nome'),
                ),
                const SizedBox(height: 24),
                Text('Tema', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Escolha a paleta principal do app.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in AppTheme.options)
                      ChoiceChip(
                        selected: settings.themeKey == option.key,
                        onSelected: (_) async {
                          await ref
                              .read(userSettingsControllerProvider.notifier)
                              .updateThemeKey(option.key);
                        },
                        avatar: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: option.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        label: Text(option.label),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Notificações',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      _SettingsSwitchRow(
                        title: 'Ativar notificações',
                        subtitle:
                            'Controle geral de todos os lembretes do app.',
                        value: settings.notificationsEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(userSettingsControllerProvider.notifier)
                              .updateNotificationsEnabled(value);
                        },
                      ),
                      const Divider(height: 1, thickness: 1),
                      _SettingsSwitchRow(
                        title: 'Lembretes de atividades',
                        subtitle:
                            'Notifica atividades com horário inicial e lembrete ativo.',
                        value: settings.activityReminderNotificationsEnabled,
                        enabled: settings.notificationsEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(userSettingsControllerProvider.notifier)
                              .updateActivityRemindersEnabled(value);
                        },
                      ),
                      const Divider(height: 1, thickness: 1),
                      _SettingsSwitchRow(
                        title: 'Lembrete de metas',
                        subtitle:
                            'Envia um lembrete diário para revisar o andamento das metas ativas.',
                        value: settings.goalReminderNotificationsEnabled,
                        enabled: settings.notificationsEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(userSettingsControllerProvider.notifier)
                              .updateGoalRemindersEnabled(value);
                        },
                      ),
                      const Divider(height: 1, thickness: 1),
                      _SettingsTimeRow(
                        title: 'Horário do lembrete de metas',
                        value: TimeOfDayUtils.format(
                          TimeOfDayUtils.fromMinutes(
                            settings.goalReminderMinutes,
                          ),
                        ),
                        enabled:
                            settings.notificationsEnabled &&
                            settings.goalReminderNotificationsEnabled,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDayUtils.fromMinutes(
                              settings.goalReminderMinutes,
                            ),
                          );
                          if (picked == null) return;
                          await ref
                              .read(userSettingsControllerProvider.notifier)
                              .updateGoalReminderMinutes(
                                TimeOfDayUtils.toMinutes(picked),
                              );
                        },
                      ),
                      const Divider(height: 1, thickness: 1),
                      _SettingsSwitchRow(
                        title: 'Frase motivacional noturna',
                        subtitle:
                            'Antes de dormir, envia uma frase para te preparar para o próximo dia.',
                        value: settings.bedtimeMotivationEnabled,
                        enabled: settings.notificationsEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(userSettingsControllerProvider.notifier)
                              .updateBedtimeMotivationEnabled(value);
                        },
                      ),
                      const Divider(height: 1, thickness: 1),
                      _SettingsTimeRow(
                        title: 'Horário da frase noturna',
                        value: TimeOfDayUtils.format(
                          TimeOfDayUtils.fromMinutes(
                            settings.bedtimeMotivationMinutes,
                          ),
                        ),
                        enabled:
                            settings.notificationsEnabled &&
                            settings.bedtimeMotivationEnabled,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDayUtils.fromMinutes(
                              settings.bedtimeMotivationMinutes,
                            ),
                          );
                          if (picked == null) return;
                          await ref
                              .read(userSettingsControllerProvider.notifier)
                              .updateBedtimeMotivationMinutes(
                                TimeOfDayUtils.toMinutes(picked),
                              );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Frases motivacionais',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha se a frase muda todo dia ou se fica fixa.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Automático'),
                      selected: settings.motivationPhraseMode != 'fixed',
                      onSelected: (_) async {
                        await ref
                            .read(userSettingsControllerProvider.notifier)
                            .updateMotivationPhraseMode('daily');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Fixa'),
                      selected: settings.motivationPhraseMode == 'fixed',
                      onSelected:
                          phrases.isEmpty
                              ? null
                              : (_) async {
                                await ref
                                    .read(
                                      userSettingsControllerProvider.notifier,
                                    )
                                    .updateMotivationPhraseMode('fixed');
                                final selectedPhrase =
                                    settings.fixedMotivationPhrase;
                                if (selectedPhrase == null ||
                                    !phrases.contains(selectedPhrase)) {
                                  await ref
                                      .read(
                                        userSettingsControllerProvider.notifier,
                                      )
                                      .updateFixedMotivationPhrase(
                                        phrases.first,
                                      );
                                }
                              },
                    ),
                  ],
                ),
                if (settings.motivationPhraseMode == 'fixed') ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value:
                        (settings.fixedMotivationPhrase != null &&
                                phrases.contains(
                                  settings.fixedMotivationPhrase,
                                ))
                            ? settings.fixedMotivationPhrase
                            : (phrases.isEmpty ? null : phrases.first),
                    items:
                        phrases
                            .map(
                              (phrase) => DropdownMenuItem(
                                value: phrase,
                                child: Text(
                                  phrase,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Frase fixa selecionada',
                    ),
                    onChanged:
                        phrases.isEmpty
                            ? null
                            : (value) async {
                              if (value == null) return;
                              await ref
                                  .read(userSettingsControllerProvider.notifier)
                                  .updateFixedMotivationPhrase(value);
                            },
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: _newPhraseController,
                  decoration: const InputDecoration(
                    hintText: 'Digite uma nova frase',
                  ),
                  onSubmitted: (_) => _addPhrase(),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 380;

                    final addButton = FilledButton.icon(
                      onPressed: _isBusy ? null : _addPhrase,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Adicionar'),
                    );

                    final restoreButton = OutlinedButton.icon(
                      onPressed: _isBusy ? null : _restoreDefaultPhrases,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text(
                        'Restaurar padrão',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          SizedBox(width: double.infinity, child: addButton),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: restoreButton,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: addButton),
                        const SizedBox(width: 10),
                        Expanded(child: restoreButton),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  onPressed: _isBusy ? null : _clearPhrases,
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text('Excluir todas as frases'),
                ),
                const SizedBox(height: 10),
                phrasesAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, _) => Text('Erro ao carregar frases: $error'),
                  data: (phrases) {
                    if (phrases.isEmpty) {
                      return const Text('Sem frases cadastradas no momento.');
                    }

                    return Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (int i = 0; i < phrases.length; i++) ...[
                            ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              title: Text(phrases[i]),
                              trailing: IconButton(
                                onPressed:
                                    _isBusy ? null : () => _removePhrase(i),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ),
                            if (i < phrases.length - 1)
                              const Divider(height: 1, thickness: 1),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('Dados', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _exportJson,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Exportar e compartilhar JSON'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : _importJson,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Importar dados de JSON'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  onPressed: _isBusy ? null : _confirmClearData,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Limpar dados do app'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Informe um nome válido.');
      return;
    }

    await ref.read(userSettingsControllerProvider.notifier).updateName(name);
    _showMessage('Nome atualizado.');
  }

  Future<void> _addPhrase() async {
    final phrase = _newPhraseController.text.trim();
    if (phrase.isEmpty) {
      _showMessage('Digite uma frase antes de adicionar.');
      return;
    }

    await ref
        .read(motivationPhrasesControllerProvider.notifier)
        .addPhrase(phrase);
    _newPhraseController.clear();
    _showMessage('Frase adicionada.');
  }

  Future<void> _removePhrase(int index) async {
    await ref
        .read(motivationPhrasesControllerProvider.notifier)
        .removeAt(index);
    _showMessage('Frase removida.');
  }

  Future<void> _clearPhrases() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir todas as frases?'),
            content: const Text(
              'Você pode adicionar novas depois. Esta ação remove todas as frases atuais.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    await ref.read(motivationPhrasesControllerProvider.notifier).clearAll();
    _showMessage('Todas as frases foram removidas.');
  }

  Future<void> _restoreDefaultPhrases() async {
    await ref
        .read(motivationPhrasesControllerProvider.notifier)
        .restoreDefaults();
    _showMessage('Frases padrão restauradas.');
  }

  Future<void> _exportJson() async {
    setState(() => _isBusy = true);
    final result = await ref.read(jsonBackupServiceProvider).exportToJsonFile();
    if (mounted) _showMessage(result.message);
    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _importJson() async {
    setState(() => _isBusy = true);
    final result =
        await ref.read(jsonBackupServiceProvider).importFromJsonFile();
    await _reloadAll();
    if (mounted) _showMessage(result.message);
    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _confirmClearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpar dados?'),
          content: const Text(
            'Esta ação apaga atividades, histórico e configurações. Não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Limpar tudo'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isBusy = true);
    await ref.read(appDataRepositoryProvider).clearAll();
    await LocalStorageService.ensureDefaultCategories();
    await ref.read(motivationPhraseRepositoryProvider).restoreDefaults();
    await _reloadAll();
    if (mounted) _showMessage('Dados removidos com sucesso.');
    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _reloadAll() async {
    _didLoadInitialName = false;
    await ref.read(categoriesControllerProvider.notifier).reload();
    await ref.read(activitiesControllerProvider.notifier).reload();
    await ref.read(userSettingsControllerProvider.notifier).reload();
    await ref.read(motivationPhrasesControllerProvider.notifier).reload();
    await ref.read(todayControllerProvider.notifier).reload();
    await ref.read(historyControllerProvider.notifier).reload();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool value) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: enabled ? null : Theme.of(context).disabledColor,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color:
          enabled
              ? Theme.of(context).textTheme.bodyMedium?.color
              : Theme.of(context).disabledColor,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 2),
                Text(subtitle, style: subtitleStyle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged:
                enabled
                    ? (newValue) async {
                      await onChanged(newValue);
                    }
                    : null,
          ),
        ],
      ),
    );
  }
}

class _SettingsTimeRow extends StatelessWidget {
  const _SettingsTimeRow({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String value;
  final bool enabled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        enabled
            ? Theme.of(context).textTheme.bodyLarge?.color
            : Theme.of(context).disabledColor;
    final subtitleColor =
        enabled
            ? Theme.of(context).textTheme.bodyMedium?.color
            : Theme.of(context).disabledColor;

    return InkWell(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      onTap:
          enabled
              ? () async {
                await onTap();
              }
              : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.schedule_outlined, color: color),
          ],
        ),
      ),
    );
  }
}
