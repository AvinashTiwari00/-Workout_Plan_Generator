import 'package:college_project/database/database_helper.dart';
import 'package:college_project/models/user_models.dart';

class WeightRepository {
  Future<int> addLog({
    required int userId,
    required double weightKg,
    DateTime? loggedAt,
  }) async {
    if (!weightKg.isFinite || weightKg <= 0 || weightKg > 500) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Must be above 0 and up to 500',
      );
    }
    final db = await DatabaseHelper.instance.database;
    final log = WeightLog(
      userId: userId,
      weightKg: weightKg,
      loggedAt: (loggedAt ?? DateTime.now()).toUtc(),
    );
    return db.insert('weight_logs', log.toMap());
  }

  Future<List<WeightLog>> logsForUser(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'weight_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at DESC, id DESC',
    );
    return [for (final row in rows) WeightLog.fromMap(row)];
  }

  Future<WeightLog?> latest(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'weight_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeightLog.fromMap(rows.first);
  }
}
