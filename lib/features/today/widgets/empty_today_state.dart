import 'package:flutter/material.dart';

class EmptyTodayState extends StatelessWidget {
  const EmptyTodayState({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.self_improvement_rounded, size: 56),
            const SizedBox(height: 14),
            Text(
              'Seu dia está livre por enquanto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre uma atividade recorrente e transforme seu dia em pequenos avanços.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Text(
              'Comece com algo simples. Consistência vem primeiro.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
