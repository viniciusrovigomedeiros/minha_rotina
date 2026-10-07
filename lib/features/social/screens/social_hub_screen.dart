import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/social/social_challenge.dart';
import '../../../data/models/social/social_session.dart';
import '../../../state/activities_controller.dart';
import '../../../state/categories_controller.dart';
import '../../../state/cloud_sync_providers.dart';
import '../../../state/daily_closures_controller.dart';
import '../../../state/goals_controller.dart';
import '../../../state/history_controller.dart';
import '../../../state/okr_workspace_controller.dart';
import '../../../state/social/social_providers.dart';
import '../../../state/today_controller.dart';
import '../../../state/user_settings_controller.dart';
import '../../../state/weekly_dashboard_controller.dart';
import '../../../state/weekly_goals_controller.dart';
import 'cloud_sync_card.dart';
import 'social_challenge_detail_screen.dart';

class SocialHubScreen extends ConsumerWidget {
  const SocialHubScreen({
    super.key,
    this.initialChallengeTitle,
    this.initialChallengeDescription,
    this.initialChallengeType,
  });

  final String? initialChallengeTitle;
  final String? initialChallengeDescription;
  final SocialChallengeType? initialChallengeType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(socialSessionControllerProvider);
    final highlightsAsync = ref.watch(socialHighlightsProvider);
    final createAction = ref.watch(socialChallengeActionProvider);
    final cloudSyncAsync = ref.watch(cloudSyncStatusProvider);
    final session = sessionAsync.valueOrNull;
    final isAuthenticated = session?.isAuthenticated == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SocialHero(isAuthenticated: isAuthenticated),
            const SizedBox(height: 16),
            _AccountCard(
              session: session,
              isLoading: sessionAsync.isLoading,
              onEmailAuth: (isSignUp, name, email, password) async {
                if (isSignUp) {
                  return ref
                      .read(socialSessionControllerProvider.notifier)
                      .signUp(name: name, email: email, password: password);
                }
                await ref
                    .read(socialSessionControllerProvider.notifier)
                    .signInWithPassword(email: email, password: password);
                return true;
              },
              onPickAvatar: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                final path = result?.files.single.path;
                if (path == null) return;
                await ref
                    .read(socialSessionControllerProvider.notifier)
                    .uploadAvatar(path);
              },
              onSignOut: () async {
                await ref
                    .read(socialSessionControllerProvider.notifier)
                    .signOut();
              },
            ),
            if (isAuthenticated) ...[
              const SizedBox(height: 12),
              CloudSyncCard(
                status: cloudSyncAsync.valueOrNull,
                isLoading: cloudSyncAsync.isLoading,
                onEnable: () async {
                  final session = sessionAsync.valueOrNull!;
                  await ref.read(cloudSyncServiceProvider).enable(session);
                  ref.invalidate(cloudSyncStatusProvider);
                },
                onSync: () async {
                  await ref
                      .read(cloudSyncServiceProvider)
                      .syncNow(sessionAsync.valueOrNull);
                  ref.invalidate(cloudSyncStatusProvider);
                },
                onDisable: () async {
                  await ref.read(cloudSyncServiceProvider).disable();
                  ref.invalidate(cloudSyncStatusProvider);
                },
                onRestore: () async {
                  final shouldRestore = await showDialog<bool>(
                    context: context,
                    builder:
                        (dialogContext) => AlertDialog(
                          title: const Text('Restaurar backup online?'),
                          content: const Text(
                            'Os dados atuais deste aparelho serao substituidos pelo ultimo backup da sua conta.',
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => Navigator.pop(dialogContext, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed:
                                  () => Navigator.pop(dialogContext, true),
                              child: const Text('Restaurar'),
                            ),
                          ],
                        ),
                  );
                  if (shouldRestore != true) return;

                  final restored = await ref
                      .read(cloudSyncServiceProvider)
                      .restoreFromCloud(sessionAsync.valueOrNull!);
                  if (!context.mounted) return;
                  if (restored) {
                    _refreshLocalState(ref);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup restaurado.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nenhum backup online encontrado.'),
                      ),
                    );
                  }
                  ref.invalidate(cloudSyncStatusProvider);
                },
              ),
            ],
            if (isAuthenticated) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seu proximo passo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comece um desafio ou entre em um que alguem ja criou.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              createAction.isLoading
                                  ? null
                                  : () async {
                                    final created = await showModalBottomSheet<
                                      bool
                                    >(
                                      context: context,
                                      isScrollControlled: true,
                                      isDismissible: false,
                                      enableDrag: false,
                                      builder:
                                          (_) => _CreateChallengeSheet(
                                            initialTitle: initialChallengeTitle,
                                            initialDescription:
                                                initialChallengeDescription,
                                            initialType: initialChallengeType,
                                            onCreate:
                                                (draft) => ref
                                                    .read(
                                                      socialChallengeActionProvider
                                                          .notifier,
                                                    )
                                                    .create(draft),
                                          ),
                                    );
                                    if (created != true || !context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Desafio criado.'),
                                      ),
                                    );
                                  },
                          icon:
                              createAction.isLoading
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.add_rounded),
                          label: const Text('Criar desafio'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () async {
                          final token = await _askForText(
                            context,
                            title: 'Entrar com convite',
                            label: 'Codigo recebido',
                          );
                          if (token == null || token.trim().isEmpty) return;
                          try {
                            await ref
                                .read(socialChallengeActionProvider.notifier)
                                .acceptInvite(token.trim());
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Voce entrou no desafio.'),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nao foi possivel usar esse convite. Confira o codigo.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.key_outlined, size: 18),
                        label: const Text('Tenho um codigo de convite'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const _ModesCard(),
            if (isAuthenticated) ...[
              const SizedBox(height: 20),
              Text(
                'Seus desafios',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              highlightsAsync.when(
                loading:
                    () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                error:
                    (error, _) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Nao foi possivel carregar seus desafios agora. Tente novamente.',
                        ),
                      ),
                    ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Nenhum desafio ainda. Crie um desafio ou entre com um codigo de convite para comecar.',
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (int index = 0; index < items.length; index++) ...[
                        _HighlightCard(
                          item: items[index],
                          onOpen:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => SocialChallengeDetailScreen(
                                        challenge: items[index],
                                      ),
                                ),
                              ),
                          onShareInvite: () async {
                            try {
                              final token = await ref
                                  .read(socialChallengeActionProvider.notifier)
                                  .createInvite(items[index].id);
                              await Share.share(
                                'Entre no desafio "${items[index].title}" no Minha Rotina. Codigo: $token',
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Nao foi possivel gerar o convite. Tente novamente.',
                                  ),
                                ),
                              );
                            }
                          },
                          onCheckIn: () async {
                            final note = await _askForText(
                              context,
                              title: 'Check-in semanal',
                              label: 'Como voce avancou?',
                            );
                            if (note == null || note.trim().isEmpty) return;
                            try {
                              await ref
                                  .read(socialChallengeActionProvider.notifier)
                                  .createWeeklyCheckIn(
                                    SocialWeeklyCheckInDraft(
                                      challengeId: items[index].id,
                                      advanceNote: note,
                                    ),
                                  );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Check-in enviado.'),
                                ),
                              );
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Nao foi possivel enviar o check-in. Tente novamente.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        if (index < items.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 20),
              const _HowItWorksCard(),
            ],
          ],
        ),
      ),
    );
  }
}

void _refreshLocalState(WidgetRef ref) {
  ref.invalidate(activitiesControllerProvider);
  ref.invalidate(categoriesControllerProvider);
  ref.invalidate(dailyClosuresControllerProvider);
  ref.invalidate(goalsControllerProvider);
  ref.invalidate(historyControllerProvider);
  ref.invalidate(okrWorkspaceControllerProvider);
  ref.invalidate(todayControllerProvider);
  ref.invalidate(userSettingsControllerProvider);
  ref.invalidate(weeklyDashboardControllerProvider);
  ref.invalidate(weeklyGoalsControllerProvider);
}

class _SocialHero extends StatelessWidget {
  const _SocialHero({required this.isAuthenticated});

  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title =
        isAuthenticated
            ? 'Evolua com gente que puxa voce para frente.'
            : 'Objetivos ficam mais fortes quando sao acompanhados.';
    final body =
        isAuthenticated
            ? 'Crie um desafio, convide pessoas e mantenha o ritmo juntos.'
            : 'Desafios simples, check-ins curtos e menos desculpas para deixar um objetivo de lado.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: colors.primary,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuthenticated ? 'SEU ESPACO SOCIAL' : 'NAO FACA SOZINHO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.90),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_2_rounded, color: colors.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como funciona',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const _HowItWorksStep(
              number: '1',
              title: 'Escolha um objetivo',
              body: 'Use um OKR seu ou crie um desafio simples para a semana.',
            ),
            const SizedBox(height: 12),
            const _HowItWorksStep(
              number: '2',
              title: 'Convide quem importa',
              body: 'Envie um codigo para uma pessoa ou para o seu grupo.',
            ),
            const SizedBox(height: 12),
            const _HowItWorksStep(
              number: '3',
              title: 'Prestacao de contas curta',
              body:
                  'Uma atualizacao por semana ja deixa todo mundo em movimento.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.primary,
          child: Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

Future<String?> _askForText(
  BuildContext context, {
  required String title,
  required String label,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Confirmar'),
            ),
          ],
        ),
  );
  controller.dispose();
  return result;
}

class _CreateChallengeSheet extends StatefulWidget {
  const _CreateChallengeSheet({
    required this.onCreate,
    this.initialTitle,
    this.initialDescription,
    this.initialType,
  });

  final String? initialTitle;
  final String? initialDescription;
  final SocialChallengeType? initialType;
  final Future<void> Function(SocialChallengeDraft) onCreate;

  @override
  State<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<_CreateChallengeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late SocialChallengeType _type;
  bool _isCreating = false;
  String? _creationError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _type = widget.initialType ?? SocialChallengeType.weeklyShort;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: !_isCreating,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Novo desafio',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  enabled: !_isCreating,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nome do desafio',
                  ),
                  validator:
                      (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Dê um nome para o desafio.'
                              : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SocialChallengeType>(
                  value: _type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Formato'),
                  items: SocialChallengeType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged:
                      _isCreating
                          ? null
                          : (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: 8),
                Text(
                  'Duracao inicial: ${_type.defaultDurationDays} dias.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                if (_creationError != null) ...[
                  Text(
                    _creationError!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isCreating ? null : _create,
                    child:
                        _isCreating
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Criar e convidar pessoas depois'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed:
                        _isCreating ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (_isCreating || !_formKey.currentState!.validate()) return;
    setState(() {
      _isCreating = true;
      _creationError = null;
    });
    try {
      await widget.onCreate(
        SocialChallengeDraft(
          title: _titleController.text.trim(),
          type: _type,
          description: widget.initialDescription,
        ),
      );
      if (!mounted) return;
      setState(() => _isCreating = false);
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _creationError = 'Nao foi possivel criar o desafio. Tente novamente.';
      });
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.session,
    required this.isLoading,
    required this.onEmailAuth,
    required this.onPickAvatar,
    required this.onSignOut,
  });

  final SocialSession? session;
  final bool isLoading;
  final Future<bool> Function(
    bool isSignUp,
    String name,
    String email,
    String password,
  )
  onEmailAuth;
  final Future<void> Function() onPickAvatar;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final isConfigured = session?.isConfigured ?? false;
    final isAuthenticated = session?.isAuthenticated ?? false;
    final displayName = session?.displayName ?? session?.email ?? 'Sua conta';

    if (!isConfigured) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Este recurso esta indisponivel agora. Tente novamente mais tarde.',
          ),
        ),
      );
    }

    if (isAuthenticated) {
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              displayName.characters.first.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          title: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text('Conta conectada'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'avatar') onPickAvatar();
              if (value == 'signOut') onSignOut();
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'avatar', child: Text('Trocar foto')),
                  PopupMenuItem(value: 'signOut', child: Text('Sair da conta')),
                ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convide alguem para evoluir junto',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Crie uma conta para iniciar desafios, aceitar convites e acompanhar o grupo.',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : () => _openAuth(context, true),
                child: const Text('Criar conta'),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: isLoading ? null : () => _openAuth(context, false),
                child: const Text('Ja tenho conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAuth(BuildContext context, bool signUp) async {
    final outcome = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => _EmailAuthSheet(onSubmit: onEmailAuth, initialSignUp: signUp),
    );
    if (outcome == false && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirme seu e-mail antes de entrar.')),
      );
    }
  }
}

class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet({required this.onSubmit, required this.initialSignUp});

  final Future<bool> Function(bool, String, String, String) onSubmit;
  final bool initialSignUp;

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _isSignUp;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _isSignUp ? 'Criar conta' : 'Entrar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_isSignUp)
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha (minimo 6 caracteres)',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              _loading
                  ? null
                  : () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _loading = true);
                    try {
                      final active = await widget.onSubmit(
                        _isSignUp,
                        _name.text,
                        _email.text,
                        _password.text,
                      );
                      if (mounted) {
                        navigator.pop(active);
                      }
                    } catch (error) {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nao foi possivel continuar agora. Confira seus dados e tente novamente.',
                            ),
                          ),
                        );
                      }
                    }
                    if (mounted) {
                      setState(() => _loading = false);
                    }
                  },
          child: Text(_isSignUp ? 'Criar conta' : 'Entrar'),
        ),
        TextButton(
          onPressed: () => setState(() => _isSignUp = !_isSignUp),
          child: Text(_isSignUp ? 'Ja tenho conta' : 'Criar conta nova'),
        ),
      ],
    ),
  );
}

class _ModesCard extends StatelessWidget {
  const _ModesCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feito para o seu ritmo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Um desafio pode durar uma semana, um ciclo ou o tempo que seu grupo precisar.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FormatPill(
                  icon: Icons.flash_on_rounded,
                  label: 'Semana',
                  color: colors.primary,
                ),
                _FormatPill(
                  icon: Icons.track_changes_rounded,
                  label: 'Ciclo',
                  color: colors.secondary,
                ),
                _FormatPill(
                  icon: Icons.flag_rounded,
                  label: 'Mesmo objetivo',
                  color: colors.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatPill extends StatelessWidget {
  const _FormatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.item,
    required this.onOpen,
    required this.onShareInvite,
    required this.onCheckIn,
  });

  final SocialChallengeSummary item;
  final VoidCallback onOpen;
  final Future<void> Function() onShareInvite;
  final Future<void> Function() onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpen,
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text('${item.type.label} • ${item.memberCount} membros'),
            const SizedBox(height: 4),
            Text('${item.statusLabel} • ${item.progressLabel}'),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onCheckIn,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Check-in'),
                ),
                TextButton.icon(
                  onPressed: onShareInvite,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Convidar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
