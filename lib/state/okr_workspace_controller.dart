import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/okr_progress_utils.dart';
import '../data/models/activity.dart';
import '../state/providers.dart';

class OkrWorkspaceState {
  const OkrWorkspaceState({
    required this.cycleProgresses,
    required this.currentCycle,
    required this.activeObjectives,
    required this.staleKeyResults,
    required this.weekInitiatives,
    required this.independentActivities,
    required this.nextCheckInDate,
  });

  final List<OkrCycleProgress> cycleProgresses;
  final OkrCycleProgress? currentCycle;
  final List<OkrObjectiveProgress> activeObjectives;
  final List<KeyResultProgress> staleKeyResults;
  final List<Activity> weekInitiatives;
  final List<Activity> independentActivities;
  final DateTime? nextCheckInDate;

  List<OkrObjectiveProgress> get allObjectives =>
      cycleProgresses.expand((item) => item.objectives).toList();
}

final okrWorkspaceControllerProvider =
    AsyncNotifierProvider<OkrWorkspaceController, OkrWorkspaceState>(
      OkrWorkspaceController.new,
    );

final okrObjectiveProgressProvider =
    Provider.family<OkrObjectiveProgress?, String>((ref, objectiveId) {
      final workspace = ref.watch(okrWorkspaceControllerProvider).valueOrNull;
      if (workspace == null) return null;
      final matches =
          workspace.allObjectives
              .where((item) => item.objective.id == objectiveId)
              .toList();
      return matches.isEmpty ? null : matches.first;
    });

class OkrWorkspaceController extends AsyncNotifier<OkrWorkspaceState> {
  @override
  Future<OkrWorkspaceState> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<OkrWorkspaceState> _load() async {
    final cycles = await ref.read(okrCycleRepositoryProvider).getAll();
    final objectives = await ref.read(okrObjectiveRepositoryProvider).getAll();
    final keyResults = await ref.read(keyResultRepositoryProvider).getAll();
    final activities = await ref.read(activityRepositoryProvider).getAll();
    final cycleProgresses = OkrProgressUtils.buildCycleProgresses(
      cycles: cycles,
      objectives: objectives,
      keyResults: keyResults,
      activities: activities,
    );

    final currentCycle = _resolveCurrentCycleProgress(cycleProgresses);
    final activeObjectives = [
      ...(currentCycle?.objectives ?? const <OkrObjectiveProgress>[]),
    ]..sort((a, b) => b.progress.compareTo(a.progress));
    final staleKeyResults =
        activeObjectives
            .expand((item) => item.keyResults)
            .where((item) => item.needsUpdate)
            .toList()
          ..sort((a, b) {
            final aDate = a.keyResult.lastCheckInAt;
            final bDate = b.keyResult.lastCheckInAt;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return -1;
            if (bDate == null) return 1;
            return aDate.compareTo(bDate);
          });
    final activeObjectiveIds =
        activeObjectives.map((item) => item.objective.id).toSet();

    final weekInitiatives =
        activities
            .where(
              (item) =>
                  item.objectiveId != null &&
                  activeObjectiveIds.contains(item.objectiveId) &&
                  item.isRecurringForObjective &&
                  _isScheduledForCurrentWeek(item),
            )
            .toList()
          ..sort(_compareActivities);
    final independentActivities =
        activities
            .where((item) => item.objectiveId == null && item.isActive)
            .toList()
          ..sort(_compareActivities);

    return OkrWorkspaceState(
      cycleProgresses: cycleProgresses,
      currentCycle: currentCycle,
      activeObjectives: activeObjectives,
      staleKeyResults: staleKeyResults,
      weekInitiatives: weekInitiatives.take(6).toList(),
      independentActivities: independentActivities.take(6).toList(),
      nextCheckInDate: _resolveNextCheckInDate(activeObjectives),
    );
  }

  OkrCycleProgress? _resolveCurrentCycleProgress(
    List<OkrCycleProgress> cycles,
  ) {
    if (cycles.isEmpty) return null;
    final currentCycle = OkrProgressUtils.resolveCurrentCycle(
      cycles.map((item) => item.cycle).toList(),
    );
    if (currentCycle == null) return cycles.first;
    final matches =
        cycles.where((item) => item.cycle.id == currentCycle.id).toList();
    return matches.isEmpty ? cycles.first : matches.first;
  }

  DateTime? _resolveNextCheckInDate(List<OkrObjectiveProgress> objectives) {
    final dates =
        objectives.map((objective) {
          final checkInDays = objective.objective.checkInFrequencyDays ?? 7;
          final lastUpdate =
              objective.keyResults
                  .map((item) => item.keyResult.lastCheckInAt)
                  .whereType<DateTime>()
                  .toList();
          final base =
              lastUpdate.isEmpty
                  ? objective.objective.createdAt
                  : lastUpdate.reduce(
                    (value, element) =>
                        value.isAfter(element) ? value : element,
                  );
          return base.add(Duration(days: checkInDays));
        }).toList();

    if (dates.isEmpty) return null;
    dates.sort((a, b) => a.compareTo(b));
    return dates.first;
  }

  int _compareActivities(Activity a, Activity b) {
    final aMinutes = a.startMinutes ?? 9999;
    final bMinutes = b.startMinutes ?? 9999;
    if (aMinutes != bMinutes) {
      return aMinutes.compareTo(bMinutes);
    }
    return a.name.compareTo(b.name);
  }

  bool _isScheduledForCurrentWeek(Activity activity) {
    if (!activity.isActive) return false;

    final now = _normalize(DateTime.now());
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return !activity.createdAt.isAfter(
          DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59, 999),
        );
      case ActivityRecurrence.weekly:
      case ActivityRecurrence.weeklyFixed:
        return !activity.createdAt.isAfter(
          DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59, 999),
        );
      case ActivityRecurrence.oneOff:
        final scheduledDate = activity.scheduledDate;
        if (scheduledDate == null) return false;
        final normalized = _normalize(scheduledDate);
        return !normalized.isBefore(weekStart) && !normalized.isAfter(weekEnd);
      case ActivityRecurrence.monthly:
        final scheduledDate = activity.scheduledDate;
        if (scheduledDate == null) return false;
        return _weekContainsDayOfMonth(
          weekStart: weekStart,
          weekEnd: weekEnd,
          dayOfMonth: scheduledDate.day,
        );
      case ActivityRecurrence.flexible:
        return false;
    }
  }

  bool _weekContainsDayOfMonth({
    required DateTime weekStart,
    required DateTime weekEnd,
    required int dayOfMonth,
  }) {
    for (
      DateTime cursor = weekStart;
      !cursor.isAfter(weekEnd);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      if (cursor.day == dayOfMonth) return true;
    }
    return false;
  }

  DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
