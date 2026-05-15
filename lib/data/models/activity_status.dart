enum ActivityStatus { pending, completed, skipped }

extension ActivityStatusX on ActivityStatus {
  String get label {
    switch (this) {
      case ActivityStatus.pending:
        return 'Pendente';
      case ActivityStatus.completed:
        return 'Concluída';
      case ActivityStatus.skipped:
        return 'Pulada';
    }
  }

  String get value => name;

  static ActivityStatus fromValue(String value) {
    return ActivityStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ActivityStatus.pending,
    );
  }
}
