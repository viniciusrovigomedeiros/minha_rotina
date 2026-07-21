import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/motivation_utils.dart';
import '../models/activity.dart';
import '../models/category.dart';
import '../models/daily_activity_log.dart';
import '../models/daily_closure_entry.dart';
import '../models/daily_plan_snapshot.dart';
import '../models/key_result.dart';
import '../models/key_result_check_in.dart';
import '../models/okr_cycle.dart';
import '../models/okr_objective.dart';
import '../models/user_settings.dart';
import '../models/weekly_goal.dart';
import '../repositories/app_data_repository.dart';

class BackupResult {
  const BackupResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class JsonBackupService {
  JsonBackupService({required AppDataRepository appDataRepository})
    : _appDataRepository = appDataRepository;

  final AppDataRepository _appDataRepository;

  Future<BackupResult> exportToJsonFile() async {
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) {
        return const BackupResult(
          success: false,
          message: 'Exportação cancelada.',
        );
      }

      final snapshot = await _appDataRepository.snapshot();
      final content = const JsonEncoder.withIndent(
        '  ',
      ).convert(snapshot.toMap());

      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('$directory/minha_rotina_backup_$stamp.json');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup do app Minha Rotina',
        subject: 'Backup Minha Rotina',
      );

      return BackupResult(
        success: true,
        message:
            'Backup exportado. Escolha o WhatsApp na tela de compartilhamento para enviar.',
      );
    } catch (error) {
      return BackupResult(success: false, message: 'Falha ao exportar: $error');
    }
  }

  Future<BackupResult> importFromJsonFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (picked == null ||
          picked.files.isEmpty ||
          picked.files.first.path == null) {
        return const BackupResult(
          success: false,
          message: 'Importação cancelada.',
        );
      }

      final file = File(picked.files.first.path!);
      final content = await file.readAsString();
      final decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        return const BackupResult(
          success: false,
          message: 'Arquivo inválido: raiz JSON precisa ser um objeto.',
        );
      }

      final parse = await _parseSnapshot(decoded);
      if (!parse.success) return parse;

      return BackupResult(
        success: true,
        message: 'Dados importados com sucesso.',
      );
    } catch (error) {
      return BackupResult(success: false, message: 'Falha ao importar: $error');
    }
  }

  Future<BackupResult> _parseSnapshot(Map<String, dynamic> root) async {
    try {
      final activitiesRaw = root['activities'];
      final dailyLogsRaw = root['dailyLogs'];
      final dailyPlansRaw = root['dailyPlans'];
      final dailyClosuresRaw = root['dailyClosures'];
      final weeklyGoalsRaw = root['weeklyGoals'];
      final okrCyclesRaw = root['okrCycles'];
      final okrObjectivesRaw = root['okrObjectives'];
      final keyResultsRaw = root['keyResults'];
      final keyResultCheckInsRaw = root['keyResultCheckIns'];
      final categoriesRaw = root['categories'];
      final userSettingsRaw = root['userSettings'];
      final motivationPhrasesRaw = root['motivationPhrases'];

      if (activitiesRaw is! List ||
          dailyLogsRaw is! List ||
          categoriesRaw is! List ||
          userSettingsRaw is! Map<String, dynamic>) {
        return const BackupResult(
          success: false,
          message: 'Arquivo inválido: estrutura obrigatória ausente.',
        );
      }

      final activities =
          activitiesRaw
              .map(
                (entry) =>
                    Activity.fromMap(Map<String, dynamic>.from(entry as Map)),
              )
              .toList();

      final dailyLogs =
          dailyLogsRaw
              .map(
                (entry) => DailyActivityLog.fromMap(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList();

      final dailyPlans =
          dailyPlansRaw is List
              ? dailyPlansRaw
                  .map(
                    (entry) => DailyPlanSnapshot.fromMap(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .toList()
              : const <DailyPlanSnapshot>[];

      final dailyClosures =
          dailyClosuresRaw is List
              ? dailyClosuresRaw
                  .map(
                    (entry) => DailyClosureEntry.fromMap(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .toList()
              : const <DailyClosureEntry>[];

      final weeklyGoals =
          weeklyGoalsRaw is List
              ? weeklyGoalsRaw
                  .map(
                    (entry) => WeeklyGoal.fromMap(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .toList()
              : const <WeeklyGoal>[];

      final categories =
          categoriesRaw
              .map(
                (entry) =>
                    Category.fromMap(Map<String, dynamic>.from(entry as Map)),
              )
              .toList();

      final okrCycles =
          okrCyclesRaw is List
              ? okrCyclesRaw
                  .map(
                    (entry) => OkrCycle.fromMap(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .toList()
              : const <OkrCycle>[];

      final okrObjectives =
          okrObjectivesRaw is List
              ? okrObjectivesRaw
                  .map(
                    (entry) => OkrObjective.fromMap(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .toList()
              : const <OkrObjective>[];

      final keyResults =
          keyResultsRaw is List
              ? keyResultsRaw
                  .map(
                    (entry) => KeyResult.fromMap(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .toList()
              : const <KeyResult>[];

      final keyResultCheckIns =
          keyResultCheckInsRaw is List
              ? keyResultCheckInsRaw
                  .map(
                    (entry) => KeyResultCheckIn.fromMap(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .toList()
              : const <KeyResultCheckIn>[];

      final userSettings = UserSettings.fromMap(
        Map<String, dynamic>.from(userSettingsRaw),
      );
      final motivationPhrases =
          motivationPhrasesRaw is List
              ? motivationPhrasesRaw
                  .map((entry) => entry.toString().trim())
                  .where((entry) => entry.isNotEmpty)
                  .toList()
              : List<String>.from(MotivationUtils.defaultPhrases);

      await _appDataRepository.replaceAll(
        activities: activities,
        dailyLogs: dailyLogs,
        dailyClosures: dailyClosures,
        dailyPlans: dailyPlans,
        weeklyGoals: weeklyGoals,
        okrCycles: okrCycles,
        okrObjectives: okrObjectives,
        keyResults: keyResults,
        keyResultCheckIns: keyResultCheckIns,
        categories: categories,
        userSettings: userSettings,
        motivationPhrases: motivationPhrases,
      );

      return const BackupResult(
        success: true,
        message: 'Importação concluída.',
      );
    } catch (error) {
      return BackupResult(success: false, message: 'Arquivo inválido: $error');
    }
  }
}
