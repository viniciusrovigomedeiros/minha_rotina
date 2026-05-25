import 'package:flutter/material.dart';

import '../../../data/models/daily_closure_entry.dart';

class DailyClosureSheetResult {
  const DailyClosureSheetResult({
    required this.bestWork,
    required this.lostStandard,
    required this.improvementForTomorrow,
  });

  final String bestWork;
  final String lostStandard;
  final String improvementForTomorrow;
}

Future<DailyClosureSheetResult?> showDailyClosureSheet({
  required BuildContext context,
  required DailyClosureEntry? existing,
}) {
  return showModalBottomSheet<DailyClosureSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _DailyClosureFormSheet(existing: existing),
  );
}

class _DailyClosureFormSheet extends StatefulWidget {
  const _DailyClosureFormSheet({required this.existing});

  final DailyClosureEntry? existing;

  @override
  State<_DailyClosureFormSheet> createState() => _DailyClosureFormSheetState();
}

class _DailyClosureFormSheetState extends State<_DailyClosureFormSheet> {
  late final TextEditingController _bestWorkController;
  late final TextEditingController _lostStandardController;
  late final TextEditingController _improvementController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _bestWorkController = TextEditingController(
      text: widget.existing?.bestWork ?? '',
    );
    _lostStandardController = TextEditingController(
      text: widget.existing?.lostStandard ?? '',
    );
    _improvementController = TextEditingController(
      text: widget.existing?.improvementForTomorrow ?? '',
    );
  }

  @override
  void dispose() {
    _bestWorkController.dispose();
    _lostStandardController.dispose();
    _improvementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fechamento diário',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Registro rápido para manter o padrão de execução.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bestWorkController,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'O que ficou excelente?',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _lostStandardController,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Onde perdeu padrão',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _improvementController,
                  maxLength: 120,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'O que melhorar amanhã?',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final isValid =
                          _formKey.currentState?.validate() ?? false;
                      if (!isValid) return;
                      Navigator.of(context).pop(
                        DailyClosureSheetResult(
                          bestWork: _bestWorkController.text.trim(),
                          lostStandard: _lostStandardController.text.trim(),
                          improvementForTomorrow:
                              _improvementController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Salvar fechamento'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Preencha este campo.';
    }
    return null;
  }
}
