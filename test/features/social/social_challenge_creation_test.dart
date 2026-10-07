import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minha_rotina/core/theme/app_theme.dart';
import 'package:minha_rotina/data/models/cloud_sync_status.dart';
import 'package:minha_rotina/data/models/social/social_challenge.dart';
import 'package:minha_rotina/data/models/social/social_session.dart';
import 'package:minha_rotina/features/social/screens/social_hub_screen.dart';
import 'package:minha_rotina/state/cloud_sync_providers.dart';
import 'package:minha_rotina/state/social/social_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SignedInSession extends SocialSessionController {
  @override
  Future<SocialSession> build() async => const SocialSession(
    isConfigured: true,
    isAuthenticated: true,
    displayName: 'Participante',
  );
}

class _CreationAction extends SocialChallengeActionController {
  final submissions = <SocialChallengeDraft>[];
  Completer<void>? pending;

  @override
  Future<void> create(SocialChallengeDraft draft) {
    submissions.add(draft);
    return pending!.future;
  }
}

Future<void> _openForm(WidgetTester tester, _CreationAction action) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socialSessionControllerProvider.overrideWith(_SignedInSession.new),
        socialChallengeActionProvider.overrideWith(() => action),
        socialHighlightsProvider.overrideWith((ref) async => []),
        cloudSyncStatusProvider.overrideWith(
          (ref) async => const CloudSyncStatus(
            isAvailable: true,
            isAuthenticated: true,
            isEnabled: false,
            hasPendingChanges: false,
            isSyncing: false,
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const SocialHubScreen()),
    ),
  );
  await tester.pumpAndSettle();
  final createButton = find.text('Criar desafio');
  await tester.scrollUntilVisible(createButton, 200);
  await tester.pumpAndSettle();
  await tester.tap(createButton);
  await tester.pumpAndSettle();
}

void main() {
  final failures = <String, Object>{
    'erro original nas permissoes': const PostgrestException(
      message: 'stack depth limit exceeded',
      code: '54001',
    ),
    'falta de internet': const SocketException('No internet connection'),
  };
  for (final failure in failures.entries) {
    testWidgets(
      'preserva o nome com ${failure.key} e permite tentar novamente',
      (tester) async {
        final action = _CreationAction()..pending = Completer<void>();
        await _openForm(tester, action);
        await tester.enterText(find.byType(TextFormField), 'Treinar na semana');
        final submit = find.widgetWithText(
          FilledButton,
          'Criar e convidar pessoas depois',
        );
        await tester.tap(submit);
        await tester.pump();
        expect(action.submissions, hasLength(1));
        expect(action.submissions.single.title, 'Treinar na semana');
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        action.pending!.completeError(failure.value);
        await tester.pumpAndSettle();
        expect(
          find.text('Nao foi possivel criar o desafio. Tente novamente.'),
          findsOneWidget,
        );
        expect(find.text('Treinar na semana'), findsOneWidget);

        action.pending = Completer<void>();
        await tester.tap(submit);
        await tester.pump();
        expect(action.submissions, hasLength(2));
        action.pending!.complete();
        await tester.pumpAndSettle();
        expect(find.text('Novo desafio'), findsNothing);
        expect(find.text('Desafio criado.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('valida nome vazio e bloqueia novo envio enquanto cria', (
    tester,
  ) async {
    final action = _CreationAction()..pending = Completer<void>();
    await _openForm(tester, action);
    final submit = find.widgetWithText(
      FilledButton,
      'Criar e convidar pessoas depois',
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Dê um nome para o desafio.'), findsOneWidget);
    expect(action.submissions, isEmpty);

    await tester.enterText(find.byType(TextFormField), 'Estudar');
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();
    final busyButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(FilledButton),
      ),
    );
    expect(busyButton.onPressed, isNull);
    expect(action.submissions, hasLength(1));
    action.pending!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
