import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/utils/okr_progress_utils.dart';
import '../data/models/activity.dart';
import '../data/models/key_result.dart';
import '../data/models/okr_cycle.dart';
import '../data/services/okr_widget_service.dart';
import 'okr_workspace_controller.dart';

final okrWidgetServiceProvider = Provider<OkrWidgetService>((ref) {
  return OkrWidgetService();
});

final okrWidgetSyncProvider = Provider<OkrWidgetSync>((ref) {
  return OkrWidgetSync(ref);
});

class OkrWidgetSync {
  OkrWidgetSync(this._ref);

  final Ref _ref;
  final DateFormat _shortDate = DateFormat('dd/MM', 'pt_BR');

  Future<void> refresh() async {
    final workspace = await _ref.read(okrWorkspaceControllerProvider.future);
    final payload = _buildPayload(workspace);
    final service = _ref.read(okrWidgetServiceProvider);

    if (payload == null) {
      await service.clear();
      return;
    }

    await service.sync(payload);
  }

  OkrWidgetPayload? _buildPayload(OkrWorkspaceState workspace) {
    if (workspace.activeObjectives.isEmpty) return null;

    final focusObjective = _pickFocusObjective(workspace.activeObjectives);
    final focusKeyResult = _pickFocusKeyResult(focusObjective);
    final cycleEnd = _normalize(focusObjective.cycle.endDate);
    final now = _normalize(DateTime.now());
    final daysRemaining = cycleEnd.difference(now).inDays;

    return OkrWidgetPayload(
      objectiveTitle: focusObjective.objective.title.trim(),
      cycleLabel: focusObjective.cycle.name.trim(),
      objectiveProgress: focusObjective.progress,
      objectivePercentText: _percentLabel(focusObjective.progress),
      keyResultTitle:
          focusKeyResult?.keyResult.title.trim() ?? 'Sem key result definido',
      keyResultProgress: focusKeyResult?.progress ?? focusObjective.progress,
      keyResultPercentText: _percentLabel(
        focusKeyResult?.progress ?? focusObjective.progress,
      ),
      keyResultValueText:
          focusKeyResult == null
              ? _percentLabel(focusObjective.progress)
              : _keyResultValueText(focusKeyResult.keyResult),
      statusText: _buildStatusText(
        objective: focusObjective,
        keyResult: focusKeyResult,
        daysRemaining: daysRemaining,
      ),
      promptText: _buildPromptText(
        workspace: workspace,
        objective: focusObjective,
        keyResult: focusKeyResult,
        daysRemaining: daysRemaining,
      ),
      daysRemaining: daysRemaining,
      daysRemainingText: _daysRemainingText(daysRemaining),
      cycleEndTimestamp:
          DateTime(
            cycleEnd.year,
            cycleEnd.month,
            cycleEnd.day,
            23,
            59,
            59,
          ).millisecondsSinceEpoch /
          1000,
      updatedAtTimestamp: DateTime.now().millisecondsSinceEpoch / 1000,
    );
  }

  OkrObjectiveProgress _pickFocusObjective(
    List<OkrObjectiveProgress> objectives,
  ) {
    final candidates = [...objectives];
    candidates.sort((a, b) {
      final urgencyCompare = _objectiveUrgency(
        a,
      ).compareTo(_objectiveUrgency(b));
      if (urgencyCompare != 0) return urgencyCompare;

      final progressCompare = a.progress.compareTo(b.progress);
      if (progressCompare != 0) return progressCompare;

      return a.objective.endDate.compareTo(b.objective.endDate);
    });
    return candidates.first;
  }

  KeyResultProgress? _pickFocusKeyResult(OkrObjectiveProgress objective) {
    if (objective.keyResults.isEmpty) return null;

    final keyResults = [...objective.keyResults];
    keyResults.sort((a, b) {
      final urgencyCompare = _keyResultUrgency(
        objective,
        a,
      ).compareTo(_keyResultUrgency(objective, b));
      if (urgencyCompare != 0) return urgencyCompare;

      final progressCompare = a.progress.compareTo(b.progress);
      if (progressCompare != 0) return progressCompare;

      final aDate = a.keyResult.lastCheckInAt;
      final bDate = b.keyResult.lastCheckInAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return -1;
      if (bDate == null) return 1;
      return aDate.compareTo(bDate);
    });
    return keyResults.first;
  }

  int _objectiveUrgency(OkrObjectiveProgress objective) {
    if (objective.isCompleted) return 4;
    if (objective.keyResults.any((item) => _needsCheckIn(objective, item))) {
      return 0;
    }

    final daysRemaining =
        _normalize(
          objective.cycle.endDate,
        ).difference(_normalize(DateTime.now())).inDays;
    if (daysRemaining <= 7) return 1;
    return 2;
  }

  int _keyResultUrgency(
    OkrObjectiveProgress objective,
    KeyResultProgress keyResult,
  ) {
    if (_needsCheckIn(objective, keyResult)) return 0;
    if (keyResult.progress >= 1) return 2;
    return 1;
  }

  bool _needsCheckIn(
    OkrObjectiveProgress objective,
    KeyResultProgress keyResult,
  ) {
    final frequency = objective.objective.checkInFrequencyDays ?? 7;
    final lastCheckIn = keyResult.keyResult.lastCheckInAt;
    if (lastCheckIn == null) return true;
    return DateTime.now().difference(lastCheckIn).inDays >= frequency;
  }

  String _buildStatusText({
    required OkrObjectiveProgress objective,
    required KeyResultProgress? keyResult,
    required int daysRemaining,
  }) {
    if (objective.isCompleted) return 'Objetivo concluído';
    if (daysRemaining < 0) return 'Ciclo encerrado';

    if (keyResult != null && _needsCheckIn(objective, keyResult)) {
      return keyResult.keyResult.lastCheckInAt == null
          ? 'Primeiro check-in pendente'
          : 'Check-in atrasado';
    }

    final expectedProgress = _expectedProgress(objective.cycle);
    if (objective.progress + 0.08 < expectedProgress) return 'Em risco';
    if (objective.progress >= expectedProgress + 0.12) return 'Adiantado';
    if (daysRemaining <= 7) return 'Reta final';
    return 'No ritmo';
  }

  String _buildPromptText({
    required OkrWorkspaceState workspace,
    required OkrObjectiveProgress objective,
    required KeyResultProgress? keyResult,
    required int daysRemaining,
  }) {
    if (keyResult != null && _needsCheckIn(objective, keyResult)) {
      return 'Atualize ${_truncate(keyResult.keyResult.title.trim(), 34)}';
    }

    final nextInitiative = _nextInitiativeForObjective(
      workspace.weekInitiatives,
      objective.objective.id,
    );
    if (nextInitiative != null) {
      return 'Próxima ação: ${_truncate(nextInitiative.name.trim(), 30)}';
    }

    final nextCheckInDate = workspace.nextCheckInDate;
    if (nextCheckInDate != null) {
      return 'Próximo check-in ${_shortDate.format(nextCheckInDate)}';
    }

    if (daysRemaining == 0) return 'Último dia do ciclo';
    return 'Foco em ${_truncate(objective.objective.title.trim(), 28)}';
  }

  Activity? _nextInitiativeForObjective(
    List<Activity> activities,
    String objectiveId,
  ) {
    for (final activity in activities) {
      if (activity.objectiveId == objectiveId) return activity;
    }
    return null;
  }

  double _expectedProgress(OkrCycle cycle) {
    final start = _normalize(cycle.startDate);
    final end = _normalize(cycle.endDate);
    if (end.isBefore(start)) return 1;

    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) return 1;

    final elapsed = _normalize(DateTime.now()).difference(start).inDays;
    return (elapsed / totalDays).clamp(0, 1);
  }

  String _keyResultValueText(KeyResult keyResult) {
    final current = OkrProgressUtils.formatValue(
      keyResult,
      keyResult.currentValue,
    );
    final target = OkrProgressUtils.formatValue(
      keyResult,
      keyResult.targetValue,
    );
    return '$current / $target';
  }

  String _percentLabel(double value) => '${(value.clamp(0, 1) * 100).round()}%';

  String _daysRemainingText(int daysRemaining) {
    if (daysRemaining < 0) return 'Ciclo encerrado';
    if (daysRemaining == 0) return 'Termina hoje';
    if (daysRemaining == 1) return '1 dia restante';
    return '$daysRemaining dias restantes';
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1)}…';
  }

  DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
