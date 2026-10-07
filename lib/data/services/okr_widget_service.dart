import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OkrWidgetPayload {
  const OkrWidgetPayload({
    required this.objectiveTitle,
    required this.cycleLabel,
    required this.objectiveProgress,
    required this.objectivePercentText,
    required this.keyResultTitle,
    required this.keyResultProgress,
    required this.keyResultPercentText,
    required this.keyResultValueText,
    required this.statusText,
    required this.promptText,
    required this.daysRemaining,
    required this.daysRemainingText,
    required this.cycleEndTimestamp,
    required this.updatedAtTimestamp,
  });

  final String objectiveTitle;
  final String cycleLabel;
  final double objectiveProgress;
  final String objectivePercentText;
  final String keyResultTitle;
  final double keyResultProgress;
  final String keyResultPercentText;
  final String keyResultValueText;
  final String statusText;
  final String promptText;
  final int daysRemaining;
  final String daysRemainingText;
  final double cycleEndTimestamp;
  final double updatedAtTimestamp;

  Map<String, Object> toMap() {
    return {
      'objectiveTitle': objectiveTitle,
      'cycleLabel': cycleLabel,
      'objectiveProgress': objectiveProgress.clamp(0, 1),
      'objectivePercentText': objectivePercentText,
      'keyResultTitle': keyResultTitle,
      'keyResultProgress': keyResultProgress.clamp(0, 1),
      'keyResultPercentText': keyResultPercentText,
      'keyResultValueText': keyResultValueText,
      'statusText': statusText,
      'promptText': promptText,
      'daysRemaining': daysRemaining,
      'daysRemainingText': daysRemainingText,
      'cycleEndTimestamp': cycleEndTimestamp,
      'updatedAtTimestamp': updatedAtTimestamp,
    };
  }
}

class OkrWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'app.minharotina.mobile/okr_widgets',
  );

  Future<void> sync(OkrWidgetPayload payload) async {
    if (!_isSupportedPlatform) return;
    await _channel.invokeMethod<void>('syncOkrWidget', payload.toMap());
  }

  Future<void> clear() async {
    if (!_isSupportedPlatform) return;
    await _channel.invokeMethod<void>('clearOkrWidget');
  }

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
