import '../../data/models/activity.dart';
import '../../data/models/key_result.dart';
import '../../data/models/okr_cycle.dart';
import '../../data/models/okr_objective.dart';

class KeyResultProgress {
  const KeyResultProgress({required this.keyResult, required this.progress});

  final KeyResult keyResult;
  final double progress;

  bool get needsUpdate {
    final lastCheckInAt = keyResult.lastCheckInAt;
    if (lastCheckInAt == null) return true;
    return DateTime.now().difference(lastCheckInAt).inDays >= 7;
  }
}

class OkrObjectiveProgress {
  const OkrObjectiveProgress({
    required this.objective,
    required this.cycle,
    required this.keyResults,
    required this.initiatives,
    required this.progress,
  });

  final OkrObjective objective;
  final OkrCycle cycle;
  final List<KeyResultProgress> keyResults;
  final List<Activity> initiatives;
  final double progress;

  bool get isCompleted =>
      progress >= 1 || objective.status == OkrObjectiveStatus.completed;
  int get staleKeyResultsCount =>
      keyResults.where((item) => item.needsUpdate).length;
}

class OkrCycleProgress {
  const OkrCycleProgress({
    required this.cycle,
    required this.objectives,
    required this.progress,
  });

  final OkrCycle cycle;
  final List<OkrObjectiveProgress> objectives;
  final double progress;
}

class OkrProgressUtils {
  const OkrProgressUtils._();

  static OkrCycle? resolveCurrentCycle(
    List<OkrCycle> cycles, {
    DateTime? date,
  }) {
    final target = _normalize(date ?? DateTime.now());
    final activeMatches =
        cycles.where((cycle) {
            final start = _normalize(cycle.startDate);
            final end = _normalize(cycle.endDate);
            return !target.isBefore(start) && !target.isAfter(end);
          }).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (activeMatches.isNotEmpty) {
      return activeMatches.firstWhere(
        (cycle) => cycle.status == OkrCycleStatus.active,
        orElse: () => activeMatches.first,
      );
    }

    final future =
        cycles
            .where((cycle) => _normalize(cycle.startDate).isAfter(target))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
    if (future.isNotEmpty) {
      return future.first;
    }

    if (cycles.isEmpty) return null;
    final sorted = [...cycles]..sort((a, b) => b.endDate.compareTo(a.endDate));
    return sorted.first;
  }

  static List<OkrCycleProgress> buildCycleProgresses({
    required List<OkrCycle> cycles,
    required List<OkrObjective> objectives,
    required List<KeyResult> keyResults,
    required List<Activity> activities,
  }) {
    final cyclesById = {for (final cycle in cycles) cycle.id: cycle};
    final keyResultsByObjective = _groupKeyResultsByObjective(keyResults);
    final initiativesByObjective = _groupActivitiesByObjective(activities);

    final objectiveProgresses =
        objectives.where((item) => cyclesById.containsKey(item.cycleId)).map((
          objective,
        ) {
          final cycle = cyclesById[objective.cycleId]!;
          final objectiveKeyResults =
              keyResultsByObjective[objective.id] ?? const <KeyResult>[];
          final progressItems =
              objectiveKeyResults
                  .map(
                    (item) => KeyResultProgress(
                      keyResult: item,
                      progress: calculateKeyResultProgress(item),
                    ),
                  )
                  .toList();
          return OkrObjectiveProgress(
            objective: objective,
            cycle: cycle,
            keyResults: progressItems,
            initiatives:
                initiativesByObjective[objective.id] ?? const <Activity>[],
            progress: calculateObjectiveProgress(progressItems),
          );
        }).toList();

    final objectiveByCycle = <String, List<OkrObjectiveProgress>>{};
    for (final progress in objectiveProgresses) {
      objectiveByCycle.putIfAbsent(progress.cycle.id, () => []).add(progress);
    }

    return cycles.map((cycle) {
        final cycleObjectives =
            objectiveByCycle[cycle.id] ?? const <OkrObjectiveProgress>[];
        return OkrCycleProgress(
          cycle: cycle,
          objectives: cycleObjectives,
          progress:
              cycleObjectives.isEmpty
                  ? 0
                  : cycleObjectives
                          .map((item) => item.progress)
                          .reduce((value, element) => value + element) /
                      cycleObjectives.length,
        );
      }).toList()
      ..sort((a, b) => b.cycle.startDate.compareTo(a.cycle.startDate));
  }

  static double calculateObjectiveProgress(List<KeyResultProgress> keyResults) {
    if (keyResults.isEmpty) return 0;

    final weighted =
        keyResults.where((item) => item.keyResult.weight != null).toList();
    if (weighted.length == keyResults.length) {
      final totalWeight = weighted.fold<double>(
        0,
        (sum, item) => sum + (item.keyResult.weight ?? 0),
      );
      if (totalWeight > 0) {
        final total = weighted.fold<double>(
          0,
          (sum, item) => sum + (item.progress * (item.keyResult.weight ?? 0)),
        );
        return totalWeight == 0 ? 0 : (total / totalWeight).clamp(0, 1);
      }
    }

    final total = keyResults.fold<double>(
      0,
      (sum, item) => sum + item.progress,
    );
    return (total / keyResults.length).clamp(0, 1);
  }

  static double calculateKeyResultProgress(KeyResult keyResult) {
    switch (keyResult.measurementType) {
      case KeyResultMeasurementType.boolean:
        return keyResult.currentValue >= keyResult.targetValue ? 1 : 0;
      case KeyResultMeasurementType.percentage:
        return (keyResult.currentValue / 100).clamp(0, 1);
      case KeyResultMeasurementType.numeric:
      case KeyResultMeasurementType.currency:
      case KeyResultMeasurementType.quantity:
        final denominator = keyResult.targetValue - keyResult.initialValue;
        if (denominator == 0) {
          return keyResult.currentValue >= keyResult.targetValue ? 1 : 0;
        }
        final ratio =
            (keyResult.currentValue - keyResult.initialValue) / denominator;
        return ratio.clamp(0, 1);
    }
  }

  static String formatValue(KeyResult keyResult, double value) {
    switch (keyResult.measurementType) {
      case KeyResultMeasurementType.percentage:
        return '${value.toStringAsFixed(0)}%';
      case KeyResultMeasurementType.currency:
        return '${keyResult.unit ?? 'R\$'} ${_formatCompact(value)}';
      case KeyResultMeasurementType.boolean:
        return value >= keyResult.targetValue ? 'Sim' : 'Não';
      case KeyResultMeasurementType.numeric:
      case KeyResultMeasurementType.quantity:
        final prefix =
            keyResult.unit == null || keyResult.unit!.isEmpty
                ? ''
                : '${keyResult.unit} ';
        return '$prefix${_formatCompact(value)}'.trim();
    }
  }

  static Map<String, List<KeyResult>> _groupKeyResultsByObjective(
    List<KeyResult> keyResults,
  ) {
    final grouped = <String, List<KeyResult>>{};
    for (final item in keyResults) {
      grouped.putIfAbsent(item.objectiveId, () => []).add(item);
    }
    return grouped;
  }

  static Map<String, List<Activity>> _groupActivitiesByObjective(
    List<Activity> activities,
  ) {
    final grouped = <String, List<Activity>>{};
    for (final item in activities) {
      final objectiveId = item.objectiveId;
      if (objectiveId == null) continue;
      grouped.putIfAbsent(objectiveId, () => []).add(item);
    }
    return grouped;
  }

  static String _formatCompact(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
