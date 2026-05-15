import 'package:intl/intl.dart';

class TimeFormat {
  const TimeFormat._();

  static final DateFormat _dateLabel = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');

  static String dateLabel(DateTime date) {
    final raw = _dateLabel.format(date);
    return raw.substring(0, 1).toUpperCase() + raw.substring(1);
  }

  static String formatMinutesRange(int? startMinutes, int? endMinutes) {
    if (startMinutes == null && endMinutes == null) {
      return 'Sem horário definido';
    }
    final start = startMinutes == null ? '--:--' : _toHour(startMinutes);
    if (endMinutes == null) return start;
    return '$start - ${_toHour(endMinutes)}';
  }

  static String _toHour(int minutes) {
    final hour = minutes ~/ 60;
    final min = minutes % 60;
    final h = hour.toString().padLeft(2, '0');
    final m = min.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
