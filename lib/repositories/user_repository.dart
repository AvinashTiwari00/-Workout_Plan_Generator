import 'package:college_project/database/database_helper.dart';
import 'package:college_project/models/user_models.dart';
import 'package:college_project/models/workout_plan.dart';
import 'package:college_project/repositories/dashboard_user_builder.dart';
import 'package:college_project/repositories/weight_repository.dart';
import 'package:college_project/repositories/workout_log_repository.dart';
import 'package:college_project/utils/password_hasher.dart';
import 'package:sqflite/sqflite.dart';

class AccountResult {
  AccountResult.success({required this.account, required this.profile})
    : error = null;

  AccountResult.failure(this.error) : account = null, profile = null;

  final UserAccount? account;
  final UserProfile? profile;
  final String? error;

  bool get isSuccess => error == null && account != null && profile != null;
}

class UserRepository {
  final WeightRepository _weights = WeightRepository();
  final WorkoutLogRepository _workouts = WorkoutLogRepository();

  Future<AccountResult> createAccount({
    required String username,
    required String password,
    int? age,
    Gender? gender,
    double? heightCm,
    UserGoal? goal,
    ExperienceLevel? experienceLevel,
    WorkoutLocation? workoutLocation,
    int? daysPerWeek,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();
    if (normalizedUsername.isEmpty) {
      return AccountResult.failure('Enter a username');
    }
    if (normalizedPassword.isEmpty) {
      return AccountResult.failure('Enter a password');
    }

    final db = await DatabaseHelper.instance.database;
    if (await _usernameTaken(db, normalizedUsername)) {
      return AccountResult.failure('Username is already taken');
    }

    try {
      return await db.transaction((txn) async {
        final id = await txn.insert('users', {
          'username': normalizedUsername,
          'password_hash': PasswordHasher.hash(normalizedPassword),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        final profile = UserProfile(
          userId: id,
          age: age,
          gender: gender,
          heightCm: heightCm,
          goal: goal,
          experienceLevel: experienceLevel,
          workoutLocation: workoutLocation,
          daysPerWeek: daysPerWeek,
        );
        await txn.insert('user_profiles', profile.toMap());
        final rows = await txn.query(
          'users',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        return AccountResult.success(
          account: UserAccount.fromMap(rows.first),
          profile: profile,
        );
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        return AccountResult.failure('Username is already taken');
      }
      rethrow;
    }
  }

  Future<UserAccount?> login(String username, String password) async {
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();
    if (normalizedUsername.isEmpty || normalizedPassword.isEmpty) return null;

    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [normalizedUsername],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final account = UserAccount.fromMap(rows.first);
    if (!PasswordHasher.verify(normalizedPassword, account.passwordHash)) {
      return null;
    }
    return account;
  }

  Future<UserAccount?> getAccount(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserAccount.fromMap(rows.first);
  }

  Future<String?> updateUsername(int userId, String username) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) return 'Enter a username';

    final db = await DatabaseHelper.instance.database;
    if (await _usernameTaken(db, normalizedUsername, exceptUserId: userId)) {
      return 'Username is already taken';
    }

    try {
      await db.update(
        'users',
        {'username': normalizedUsername},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        return 'Username is already taken';
      }
      rethrow;
    }
    return null;
  }

  Future<UserProfile?> getProfile(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<bool> hasCompleteProfile(int userId) async {
    final profile = await getProfile(userId);
    if (profile == null || !profile.isComplete) return false;
    final weight = await _weights.latest(userId);
    return weight != null &&
        weight.weightKg.isFinite &&
        weight.weightKg > 0 &&
        weight.weightKg <= 500;
  }

  /// Saves onboarding atomically. Retrying unchanged data adds no weight entry.
  /// Existing workout/weight history and account credentials are retained.
  Future<String?> completeProfile({
    required String username,
    required UserProfile profile,
    required double weightKg,
  }) async {
    if (username.trim().isEmpty ||
        !profile.isComplete ||
        !weightKg.isFinite ||
        weightKg <= 0 ||
        weightKg > 500) {
      return 'Please complete all required profile fields';
    }
    final db = await DatabaseHelper.instance.database;
    try {
      return await db.transaction<String?>((txn) async {
        final account = await txn.query(
          'users',
          where: 'id = ?',
          whereArgs: [profile.userId],
        );
        if (account.isEmpty) return 'Account not found. Please log in again';
        if (await _usernameTaken(
          txn,
          username.trim(),
          exceptUserId: profile.userId,
        )) {
          return 'Username is already taken';
        }
        await txn.update(
          'users',
          {'username': username.trim()},
          where: 'id = ?',
          whereArgs: [profile.userId],
        );
        await txn.insert(
          'user_profiles',
          profile.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        final latest = await txn.query(
          'weight_logs',
          where: 'user_id = ?',
          whereArgs: [profile.userId],
          orderBy: 'logged_at DESC, id DESC',
          limit: 1,
        );
        if (latest.isEmpty ||
            (latest.first['weight_kg'] as num).toDouble() != weightKg) {
          await txn.insert(
            'weight_logs',
            WeightLog(
              userId: profile.userId,
              weightKg: weightKg,
              loggedAt: DateTime.now().toUtc(),
            ).toMap(),
          );
        }
        return null;
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) return 'Username is already taken';
      rethrow;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'user_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Loads the dashboard user from the account, profile, and logs.
  /// Returns null when the account is missing or the profile has no goal.
  Future<User?> loadDashboardUser(int userId) async {
    final account = await getAccount(userId);
    if (account == null) return null;
    final profile = await getProfile(userId);
    if (profile == null || profile.goal == null) return null;

    final latestWeight = await _weights.latest(userId);
    final workoutLogs = await _workouts.logsForUser(userId);
    return buildDashboardUser(
      name: account.username,
      profile: profile,
      weightKg: latestWeight?.weightKg,
      workoutLogs: workoutLogs,
    );
  }

  Future<bool> _usernameTaken(
    DatabaseExecutor db,
    String username, {
    int? exceptUserId,
  }) async {
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: exceptUserId == null ? 'username = ?' : 'username = ? AND id != ?',
      whereArgs: exceptUserId == null ? [username] : [username, exceptUserId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
