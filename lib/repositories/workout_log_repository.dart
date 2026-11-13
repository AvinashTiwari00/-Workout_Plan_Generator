import 'package:college_project/database/database_helper.dart';
import 'package:college_project/models/user_models.dart';

class WorkoutLogRepository {
  Future<int> addLog({
    required int userId,
    required String workoutName,
    DateTime? completedAt,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final log = WorkoutLog(
      userId: userId,
      workoutName: workoutName,
      completedAt: (completedAt ?? DateTime.now()).toUtc(),
    );
    return db.insert('workout_logs', log.toMap());
  }

  Future<List<WorkoutLog>> logsForUser(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'workout_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'completed_at DESC, id DESC',
    );
    return [for (final row in rows) WorkoutLog.fromMap(row)];
  }
}
