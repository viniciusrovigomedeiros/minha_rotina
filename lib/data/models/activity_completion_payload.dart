import 'activity_completion_quality.dart';

class ActivityCompletionPayload {
  const ActivityCompletionPayload({
    required this.completionQuality,
    required this.qualityScore,
    required this.checklistCheckedCount,
    required this.checklistTotalCount,
  });

  final ActivityCompletionQuality completionQuality;
  final int qualityScore;
  final int checklistCheckedCount;
  final int checklistTotalCount;

  bool get isChecklistComplete => checklistCheckedCount >= checklistTotalCount;
}
