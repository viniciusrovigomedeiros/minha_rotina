import 'package:intl/intl.dart';

class DateUtilsX {
  const DateUtilsX._();

  static final DateFormat _dayKeyFormat = DateFormat('yyyy-MM-dd');

  static String toDayKey(DateTime date) => _dayKeyFormat.format(date);

  static DateTime fromDayKey(String key) => _dayKeyFormat.parseStrict(key);
}
