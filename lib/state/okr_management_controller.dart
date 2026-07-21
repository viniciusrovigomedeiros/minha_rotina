import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/key_result.dart';
import '../data/models/key_result_check_in.dart';
import '../data/models/okr_cycle.dart';
import '../data/models/okr_objective.dart';
import 'activities_controller.dart';
import 'okr_workspace_controller.dart';
import 'providers.dart';

class KeyResultDraft {
  const KeyResultDraft({
    required this.title,
    required this.measurementType,
    required this.initialValue,
    required this.currentValue,
    required this.targetValue,
    this.unit,
    this.weight,
    this.id,
  });

  final String? id;
  final String title;
  final KeyResultMeasurementType measurementType;
  final double initialValue;
  final double currentValue;
  final double targetValue;
  final String? unit;
  final double? weight;
}

class KeyResultCheckInDraft {
  const KeyResultCheckInDraft({
    required this.keyResultId,
    required this.valueAfter,
  });

  final String keyResultId;
  final double valueAfter;
}

final okrManagementControllerProvider =
    AsyncNotifierProvider<OkrManagementController, void>(
      OkrManagementController.new,
    );

class OkrManagementController extends AsyncNotifier<void> {
  final Uuid _uuid = const Uuid();

  @override
  Future<void> build() async {}

  Future<void> createCycle({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final now = DateTime.now();
    final cycle = OkrCycle(
      id: _uuid.v4(),
      name: name.trim(),
      startDate: startDate,
      endDate: endDate,
      status:
          now.isBefore(startDate)
              ? OkrCycleStatus.planned
              : now.isAfter(endDate)
              ? OkrCycleStatus.completed
              : OkrCycleStatus.active,
      isCustom: true,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(okrCycleRepositoryProvider).upsert(cycle);
    ref.invalidate(okrWorkspaceControllerProvider);
  }

  Future<void> saveObjective({
    OkrObjective? original,
    required String title,
    String? description,
    required String cycleId,
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
    required OkrObjectiveStatus status,
    int? checkInFrequencyDays,
    required List<KeyResultDraft> keyResults,
  }) async {
    final now = DateTime.now();
    final objectiveId = original?.id ?? _uuid.v4();
    final objective = OkrObjective(
      id: objectiveId,
      title: title.trim(),
      description:
          description?.trim().isEmpty ?? true ? null : description?.trim(),
      cycleId: cycleId,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      status: status,
      checkInFrequencyDays: checkInFrequencyDays,
      needsReview: original?.needsReview ?? false,
      isArchived: status == OkrObjectiveStatus.archived,
      legacyGoalId: original?.legacyGoalId,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(okrObjectiveRepositoryProvider).upsert(objective);

    final keyResultRepository = ref.read(keyResultRepositoryProvider);
    final existing =
        original == null
            ? const <KeyResult>[]
            : await keyResultRepository.findByObjectiveId(objectiveId);
    final incomingIds =
        keyResults.map((item) => item.id).whereType<String>().toSet();

    for (final item in existing.where(
      (entry) => !incomingIds.contains(entry.id),
    )) {
      await keyResultRepository.delete(item.id);
    }

    for (final draft in keyResults) {
      final existingMatch =
          existing.where((item) => item.id == draft.id).toList();
      final existingItem = existingMatch.isEmpty ? null : existingMatch.first;
      final keyResult = KeyResult(
        id: draft.id ?? _uuid.v4(),
        objectiveId: objectiveId,
        title: draft.title.trim(),
        measurementType: draft.measurementType,
        initialValue: draft.initialValue,
        currentValue: draft.currentValue,
        targetValue: draft.targetValue,
        unit: draft.unit?.trim().isEmpty ?? true ? null : draft.unit?.trim(),
        weight: draft.weight,
        status:
            draft.currentValue >= draft.targetValue
                ? KeyResultStatus.completed
                : KeyResultStatus.active,
        lastCheckInAt: draft.currentValue != draft.initialValue ? now : null,
        legacyGoalId: existingItem?.legacyGoalId,
        createdAt: existingItem?.createdAt ?? now,
        updatedAt: now,
      );
      await keyResultRepository.upsert(keyResult);
    }

    ref.invalidate(okrWorkspaceControllerProvider);
  }

  Future<void> deleteObjective(String objectiveId) async {
    await ref.read(okrObjectiveRepositoryProvider).delete(objectiveId);
    await ref
        .read(keyResultRepositoryProvider)
        .deleteByObjectiveId(objectiveId);

    final activities = await ref.read(activityRepositoryProvider).getAll();
    for (final activity in activities.where(
      (item) => item.objectiveId == objectiveId,
    )) {
      await ref
          .read(activityRepositoryProvider)
          .upsert(
            activity.copyWith(
              clearObjectiveId: true,
              clearKeyResultId: true,
              updatedAt: DateTime.now(),
            ),
          );
    }

    ref.invalidate(activitiesControllerProvider);
    ref.invalidate(okrWorkspaceControllerProvider);
  }

  Future<void> submitObjectiveCheckIn({
    required String objectiveId,
    required List<KeyResultCheckInDraft> updates,
    String? note,
    required CheckInConfidence confidence,
  }) async {
    if (updates.isEmpty) return;

    final now = DateTime.now();
    final normalizedNote = note?.trim().isEmpty ?? true ? null : note?.trim();
    final keyResultRepository = ref.read(keyResultRepositoryProvider);
    final checkInRepository = ref.read(keyResultCheckInRepositoryProvider);
    final existing = await keyResultRepository.findByObjectiveId(objectiveId);
    final updatesById = {
      for (final update in updates) update.keyResultId: update,
    };

    for (final keyResult in existing) {
      final draft = updatesById[keyResult.id];
      if (draft == null) continue;

      final nextValue = draft.valueAfter;
      final updatedKeyResult = keyResult.copyWith(
        currentValue: nextValue,
        status:
            nextValue >= keyResult.targetValue
                ? KeyResultStatus.completed
                : KeyResultStatus.active,
        lastCheckInAt: now,
        updatedAt: now,
      );

      await keyResultRepository.upsert(updatedKeyResult);
      await checkInRepository.upsert(
        KeyResultCheckIn(
          id: _uuid.v4(),
          keyResultId: keyResult.id,
          valueBefore: keyResult.currentValue,
          valueAfter: nextValue,
          note: normalizedNote,
          confidence: confidence,
          createdAt: now,
        ),
      );
    }

    ref.invalidate(okrWorkspaceControllerProvider);
  }
}
