import 'package:flutter/material.dart';

import '../../settings/screens/settings_screen.dart';

class SettingsActionButton extends StatelessWidget {
  const SettingsActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Ajustes',
    );
  }
}
