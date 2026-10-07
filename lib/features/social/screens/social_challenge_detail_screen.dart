import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/social/social_challenge.dart';
import '../../../state/social/social_providers.dart';

class SocialChallengeDetailScreen extends ConsumerWidget {
  const SocialChallengeDetailScreen({super.key, required this.challenge});

  final SocialChallengeSummary challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(socialLeaderboardProvider(challenge.id));
    final timeline = ref.watch(socialTimelineProvider(challenge.id));

    return Scaffold(
      appBar: AppBar(title: Text(challenge.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            challenge.type.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('${challenge.statusLabel} • ${challenge.progressLabel}'),
          const SizedBox(height: 24),
          Text('Ranking', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          leaderboard.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) => const Text(
                  'Nao foi possivel carregar o ranking agora. Tente novamente.',
                ),
            data:
                (items) =>
                    items.isEmpty
                        ? const Text(
                          'O ranking aparece depois do primeiro check-in.',
                        )
                        : Column(
                          children: [
                            for (var index = 0; index < items.length; index++)
                              ListTile(
                                leading: Text('#${index + 1}'),
                                title: Text(items[index].name),
                                subtitle: Text(
                                  '${items[index].streak} check-ins',
                                ),
                                trailing: Text('${items[index].score} pts'),
                              ),
                          ],
                        ),
          ),
          const SizedBox(height: 24),
          Text('Check-ins', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          timeline.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) => const Text(
                  'Nao foi possivel carregar os check-ins agora. Tente novamente.',
                ),
            data:
                (items) =>
                    items.isEmpty
                        ? const Text('Ainda nao ha atualizacoes neste desafio.')
                        : Column(
                          children: [
                            for (final item in items)
                              Card(
                                child: ListTile(
                                  title: Text(item.author),
                                  subtitle: Text(item.advanceNote),
                                  trailing: Text(
                                    '${item.createdAt.day}/${item.createdAt.month}',
                                  ),
                                ),
                              ),
                          ],
                        ),
          ),
        ],
      ),
    );
  }
}
