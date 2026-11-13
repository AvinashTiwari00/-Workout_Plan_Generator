import 'package:college_project/models/user_models.dart';
import 'package:college_project/models/workout_plan.dart';
import 'package:college_project/utils/password_hasher.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'college_project.db';
  static const _dbVersion = 2;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profiles (
        user_id INTEGER NOT NULL UNIQUE,
        age INTEGER,
        gender TEXT,
        height_cm REAL,
        goal TEXT,
        experience_level TEXT,
        workout_location TEXT,
        days_per_week INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_logs (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        logged_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_logs (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        workout_name TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  /// v1 kept login fields and body stats on one row, and logs had no user.
  /// Existing accounts are copied forward; plaintext passwords are hashed
  /// so the same password still logs in.
  Future<void> _migrateToV2(Database db) async {
    await db.execute('ALTER TABLE users RENAME TO users_v1');
    await db.execute('ALTER TABLE weight_logs RENAME TO weight_logs_v1');
    await db.execute(
      'ALTER TABLE workout_history RENAME TO workout_history_v1',
    );
    await _createSchema(db);

    final oldUsers = await db.query('users_v1');
    final usedNames = <String>{};
    final migratedAt = DateTime.now().toUtc().toIso8601String();

    for (final row in oldUsers) {
      final id = row['id'];
      if (id is! int) continue;

      final rawName = row['name'];
      if (rawName is! String || rawName.trim().isEmpty) continue;

      final username = _uniqueUsername(rawName, usedNames, id);
      final plainPassword = row['password'] is String
          ? row['password'] as String
          : '';

      await db.insert('users', {
        'id': id,
        'username': username,
        'password_hash': PasswordHasher.hash(plainPassword),
        'created_at': migratedAt,
      });

      await db.insert('user_profiles', {
        'user_id': id,
        'age': row['age'] is int ? row['age'] : null,
        'gender': null,
        'height_cm': row['height'] is num
            ? (row['height'] as num).toDouble()
            : null,
        'goal': _goalStorageValue(row['goal']),
        'experience_level': _experienceStorageValue(row['experience_level']),
        'workout_location': null,
        'days_per_week': null,
      });

      final weight = row['weight'];
      if (weight is num && weight > 0) {
        await db.insert('weight_logs', {
          'user_id': id,
          'weight_kg': weight.toDouble(),
          'logged_at': migratedAt,
        });
      }
    }

    // v1 logs were not tied to a user. Keep them on the earliest account
    // so the rows are not dropped by the new foreign key.
    final owners = await db.query(
      'users',
      columns: ['id'],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (owners.isNotEmpty) {
      final ownerId = owners.first['id'] as int;
      final oldWeights = await db.query('weight_logs_v1');
      for (final row in oldWeights) {
        final weight = row['weight'];
        if (weight is! num) continue;
        await db.insert('weight_logs', {
          'user_id': ownerId,
          'weight_kg': weight.toDouble(),
          'logged_at': _isoTimestamp(row['date']),
        });
      }

      final oldWorkouts = await db.query('workout_history_v1');
      for (final row in oldWorkouts) {
        final name = row['workout_name'];
        await db.insert('workout_logs', {
          'user_id': ownerId,
          'workout_name': name is String ? name : '',
          'completed_at': _isoTimestamp(row['date']),
        });
      }
    }

    await db.execute('DROP TABLE workout_history_v1');
    await db.execute('DROP TABLE weight_logs_v1');
    await db.execute('DROP TABLE users_v1');
  }
}

/// v1 usernames were not unique ignoring case. Suffix the id so both rows survive.
String _uniqueUsername(String raw, Set<String> used, int id) {
  var candidate = raw.trim();
  var key = candidate.toLowerCase();
  if (!used.contains(key)) {
    used.add(key);
    return candidate;
  }

  candidate = '$candidate$id';
  key = candidate.toLowerCase();
  var extra = 2;
  while (used.contains(key)) {
    candidate = '$raw$id$extra';
    key = candidate.toLowerCase();
    extra++;
  }
  used.add(key);
  return candidate;
}

String? _goalStorageValue(Object? raw) {
  if (raw is! String) return null;
  final compact = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  switch (compact) {
    case 'musclegain':
      return UserGoal.muscleGain.name;
    case 'fatloss':
      return UserGoal.fatLoss.name;
    case 'maintenance':
    case 'stayfit':
      return UserGoal.maintenance.name;
    default:
      return null;
  }
}

String? _experienceStorageValue(Object? raw) {
  if (raw is! String) return null;
  final compact = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  for (final level in ExperienceLevel.values) {
    if (level.name.toLowerCase() == compact) return level.name;
  }
  return null;
}

String _isoTimestamp(Object? raw) {
  if (raw is String) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toUtc().toIso8601String();
  }
  return DateTime.now().toUtc().toIso8601String();
}
