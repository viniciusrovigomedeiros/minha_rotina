import 'package:flutter/material.dart';

class TimeOfDayUtils {
  const TimeOfDayUtils._();

  static int toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  static TimeOfDay fromMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final min = minutes % 60;
    return TimeOfDay(hour: hour, minute: min);
  }

  static String format(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }
}
