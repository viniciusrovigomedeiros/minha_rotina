import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_of_day_utils.dart';
import '../../../state/activities_controller.dart';
import '../../../state/history_controller.dart';
import '../../../state/providers.dart';
import '../../../state/today_controller.dart';
import '../../../state/user_settings_controller.dart';
import '../../../state/weekly_dashboard_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBusy = false;
  bool _showBackupTools = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        top: false,
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erro ao carregar: $error')),
          data: (settings) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Tema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha a cor principal do aplicativo.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in AppTheme.options)
                      ChoiceChip(
                        selected: settings.themeKey == option.key,
                        onSelected:
                            _isBusy
                                ? null
                                : (_) async {
                                  await ref
                                      .read(
                                        userSettingsControllerProvider.notifier,
                                      )
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                        enabled: !_isBusy,
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
                        enabled: settings.notificationsEnabled && !_isBusy,
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
                        enabled: settings.notificationsEnabled && !_isBusy,
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
                            settings.goalReminderNotificationsEnabled &&
                            !_isBusy,
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Backup (opcional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use apenas se realmente precisar migrar ou guardar dados.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed:
                              _isBusy
                                  ? null
                                  : () {
                                    setState(() {
                                      _showBackupTools = !_showBackupTools;
                                    });
                                  },
                          icon: Icon(
                            _showBackupTools
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                          label: Text(
                            _showBackupTools
                                ? 'Ocultar ferramentas de backup'
                                : 'Mostrar ferramentas de backup',
                          ),
                        ),
                        if (_showBackupTools) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _isBusy ? null : _exportJson,
                            icon: const Icon(Icons.file_upload_outlined),
                            label: const Text('Exportar JSON'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _isBusy ? null : _importJson,
                            icon: const Icon(Icons.file_download_outlined),
                            label: const Text('Importar JSON'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportJson() async {
    setState(() => _isBusy = true);
    final result = await ref.read(jsonBackupServiceProvider).exportToJsonFile();
    if (mounted) {
      _showMessage(result.message);
      setState(() => _isBusy = false);
    }
  }

  Future<void> _importJson() async {
    setState(() => _isBusy = true);
    final result =
        await ref.read(jsonBackupServiceProvider).importFromJsonFile();
    await _reloadAfterImport();
    if (mounted) {
      _showMessage(result.message);
      setState(() => _isBusy = false);
    }
  }

  Future<void> _reloadAfterImport() async {
    await ref.read(activitiesControllerProvider.notifier).reload();
    await ref.read(userSettingsControllerProvider.notifier).reload();
    await ref.read(todayControllerProvider.notifier).reload();
    await ref.read(historyControllerProvider.notifier).reload();
    await ref.read(weeklyDashboardControllerProvider.notifier).reload();
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
