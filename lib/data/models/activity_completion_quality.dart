enum ActivityCompletionQuality { low, medium, high }

extension ActivityCompletionQualityValues on ActivityCompletionQuality {
  String get value => name;

  String get label => switch (this) {
    ActivityCompletionQuality.low => 'Ruim',
    ActivityCompletionQuality.medium => 'Ok',
    ActivityCompletionQuality.high => 'Muito boa',
  };

  String get description => switch (this) {
    ActivityCompletionQuality.low => 'Feita sem muita presença ou capricho',
    ActivityCompletionQuality.medium => 'Feita de forma consistente',
    ActivityCompletionQuality.high => 'Feita com foco e boa execução',
  };

  double get weight => switch (this) {
    ActivityCompletionQuality.low => 0.5,
    ActivityCompletionQuality.medium => 1.0,
    ActivityCompletionQuality.high => 1.25,
  };

  int get rank => switch (this) {
    ActivityCompletionQuality.low => 1,
    ActivityCompletionQuality.medium => 2,
    ActivityCompletionQuality.high => 3,
  };
}

class ActivityCompletionQualityX {
  const ActivityCompletionQualityX._();

  static ActivityCompletionQuality fromValue(String value) {
    return ActivityCompletionQuality.values.firstWhere(
      (item) => item.value == value,
      orElse: () => ActivityCompletionQuality.medium,
    );
  }

  static double averageRank(Iterable<ActivityCompletionQuality> qualities) {
    final values = qualities.toList();
    if (values.isEmpty) return 0;

    final total = values.fold<int>(0, (sum, item) => sum + item.rank);
    return total / values.length;
  }

  static String averageLabel(double average) {
    if (average < 1.5) return ActivityCompletionQuality.low.label;
    if (average < 2.5) return ActivityCompletionQuality.medium.label;
    return ActivityCompletionQuality.high.label;
  }
}
