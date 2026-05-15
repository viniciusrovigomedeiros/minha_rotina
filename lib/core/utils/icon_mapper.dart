import 'package:flutter/material.dart';

class IconMapper {
  const IconMapper._();

  static const Map<String, IconData> _iconByKey = {
    'favorite': Icons.favorite_rounded,
    'work': Icons.work_rounded,
    'school': Icons.school_rounded,
    'bolt': Icons.bolt_rounded,
    'home': Icons.home_rounded,
    'person': Icons.person_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'menu_book': Icons.menu_book_rounded,
    'fitness': Icons.fitness_center_rounded,
    'checklist': Icons.checklist_rounded,
    'run': Icons.directions_run_rounded,
    'water': Icons.water_drop_rounded,
    'bed': Icons.bed_rounded,
    'alarm': Icons.alarm_rounded,
    'book': Icons.book_rounded,
    'code': Icons.code_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'calendar': Icons.calendar_month_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'shopping': Icons.shopping_cart_rounded,
    'car': Icons.directions_car_rounded,
    'flight': Icons.flight_takeoff_rounded,
    'music': Icons.music_note_rounded,
    'movie': Icons.movie_rounded,
    'camera': Icons.camera_alt_rounded,
    'clean': Icons.cleaning_services_rounded,
    'restaurant': Icons.restaurant_rounded,
    'pets': Icons.pets_rounded,
    'nature': Icons.park_rounded,
    'meditation': Icons.spa_rounded,
    'phone': Icons.phone_android_rounded,
    'mail': Icons.mail_rounded,
    'chat': Icons.chat_rounded,
    'family': Icons.family_restroom_rounded,
    'medicine': Icons.medication_rounded,
    'heart': Icons.monitor_heart_rounded,
    'target': Icons.track_changes_rounded,
    'trophy': Icons.emoji_events_rounded,
    'lightbulb': Icons.lightbulb_rounded,
    'star': Icons.star_rounded,
    'sun': Icons.wb_sunny_rounded,
    'moon': Icons.nightlight_round_rounded,
    'build': Icons.build_rounded,
    'brush': Icons.brush_rounded,
    'language': Icons.language_rounded,
    'public': Icons.public_rounded,
    'security': Icons.security_rounded,
    'volunteer': Icons.volunteer_activism_rounded,
    'payments': Icons.payments_rounded,
    'savings': Icons.savings_rounded,
  };

  static IconData fromKey(String? key) {
    return _iconByKey[key] ?? Icons.check_circle_outline_rounded;
  }

  static String toKey(IconData icon) {
    return _iconByKey.entries
        .firstWhere(
          (entry) => entry.value == icon,
          orElse: () => const MapEntry('checklist', Icons.checklist_rounded),
        )
        .key;
  }
}
