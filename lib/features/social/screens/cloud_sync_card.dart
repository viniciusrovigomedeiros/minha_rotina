import 'package:flutter/material.dart';

import '../../../data/models/cloud_sync_status.dart';

class CloudSyncCard extends StatelessWidget {
  const CloudSyncCard({
    super.key,
    required this.status,
    required this.isLoading,
    required this.onEnable,
    required this.onSync,
    required this.onDisable,
    required this.onRestore,
  });

  final CloudSyncStatus? status;
  final bool isLoading;
  final Future<void> Function() onEnable;
  final Future<void> Function() onSync;
  final Future<void> Function() onDisable;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    final enabled = status?.isEnabled ?? false;
    final busy = isLoading || status?.isSyncing == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seus dados',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(_description(status)),
            if (status?.lastError != null) ...[
              const SizedBox(height: 6),
              Text(
                'A sincronizacao sera tentada novamente quando houver conexao.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            if (!enabled)
              FilledButton.icon(
                onPressed:
                    busy
                        ? null
                        : () async {
                          try {
                            await onEnable();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sincronizacao ativada.'),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nao foi possivel sincronizar agora. Suas alteracoes continuam neste aparelho.',
                                ),
                              ),
                            );
                          }
                        },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Ativar sincronizacao'),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed:
                        busy
                            ? null
                            : () async {
                              await onSync();
                            },
                    icon:
                        busy
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.sync),
                    label: const Text('Sincronizar agora'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onRestore,
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: const Text('Restaurar backup'),
                  ),
                  TextButton(
                    onPressed: busy ? null : onDisable,
                    child: const Text('Usar so neste aparelho'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _description(CloudSyncStatus? status) {
    if (status == null) return 'Verificando o status da sincronizacao...';
    if (!status.isEnabled) {
      return 'Seus dados continuam locais. Ative para manter um backup online e sincronizar depois, mesmo usando offline.';
    }
    if (status.isSyncing) {
      return 'Enviando suas alteracoes para o backup online...';
    }
    if (status.hasPendingChanges) {
      return 'Alteracoes pendentes. O app enviara assim que houver internet.';
    }
    if (status.lastSyncedAt != null) {
      return 'Tudo sincronizado neste aparelho.';
    }
    return 'A sincronizacao esta ativa e aguardando a primeira atualizacao.';
  }
}
