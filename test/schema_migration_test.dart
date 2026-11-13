import 'dart:io';

import 'package:college_project/database/database_helper.dart';
import 'package:college_project/models/user_models.dart';
import 'package:college_project/models/workout_plan.dart';
import 'package:college_project/repositories/user_repository.dart';
import 'package:college_project/utils/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v1 users migrate and login uses the stored profile', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final temp = await Directory.systemTemp.createTemp('migration_test_');
    await databaseFactory.setDatabasesPath(temp.path);
    addTearDown(() async {
      await (await DatabaseHelper.instance.database).close();
      await temp.delete(recursive: true);
    });
    final dir = await getDatabasesPath();
    final path = join(dir, 'college_project.db');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    final v1 = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            name TEXT,
            password TEXT,
            age INTEGER,
            height REAL,
            weight REAL,
            goal TEXT,
            experience_level TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_history (
            id INTEGER PRIMARY KEY,
            workout_name TEXT,
            date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE weight_logs (
            id INTEGER PRIMARY KEY,
            weight REAL,
            date TEXT
          )
        ''');
      },
    );

    await v1.insert('users', {
      'name': 'Ava',
      'password': 'secret',
      'age': 21,
      'height': 170.5,
      'weight': 60,
      'goal': 'Fat Loss',
      'experience_level': 'Beginner',
    });
    await v1.insert('users', {
      'name': 'ava',
      'password': 'other',
      'age': 22,
      'height': 160,
      'weight': 55,
      'goal': 'muscleGain',
      'experience_level': 'nope',
    });
    await v1.insert('users', {
      'name': 'Sam',
      'password': 'pw',
      'age': 40,
      'height': 180,
      'weight': 80,
      'goal': 'Stay Fit',
      'experience_level': 'Advanced',
    });
    await v1.insert('weight_logs', {
      'weight': 61.5,
      'date': '2024-01-02T00:00:00.000',
    });
    await v1.insert('workout_history', {
      'workout_name': 'Legs',
      'date': '2024-01-03',
    });
    await v1.close();

    final db = await DatabaseHelper.instance.database;
    final users = await db.query('users', orderBy: 'id ASC');
    expect(users, hasLength(3));
    expect(users[0]['username'], 'Ava');
    expect(users[1]['username'], isNot('ava'));
    expect(
      PasswordHasher.verify('secret', users[0]['password_hash'] as String),
      isTrue,
    );
    expect(
      PasswordHasher.verify('other', users[1]['password_hash'] as String),
      isTrue,
    );

    final profiles = await db.query('user_profiles', orderBy: 'user_id ASC');
    expect(profiles[0]['goal'], 'fatLoss');
    expect(profiles[0]['experience_level'], 'beginner');
    expect(profiles[0]['height_cm'], 170.5);
    expect(profiles[1]['goal'], 'muscleGain');
    expect(profiles[1]['experience_level'], isNull);
    expect(profiles[2]['goal'], 'maintenance');
    expect(profiles[2]['experience_level'], 'advanced');

    final workouts = await db.query('workout_logs');
    expect(workouts, hasLength(1));
    expect(workouts.single['workout_name'], 'Legs');
    expect(workouts.single['user_id'], users[0]['id']);

    final repo = UserRepository();
    final account = await repo.login('ava', 'secret');
    expect(account, isNotNull);
    expect(account!.username, 'Ava');

    final profile = await repo.getProfile(account.id);
    expect(profile?.goal, UserGoal.fatLoss);

    final dashboard = await repo.loadDashboardUser(account.id);
    expect(dashboard, isNotNull);
    expect(dashboard!.goal, UserGoal.fatLoss);
    expect(dashboard.todayWorkout, isNot('Chest Day'));
    expect(dashboard.todayWorkout, isNotEmpty);
    expect(dashboard.weight, '60');

    final taken = await repo.createAccount(username: 'AVA', password: 'x');
    expect(taken.isSuccess, isFalse);
    expect(taken.error, 'Username is already taken');

    final created = await repo.createAccount(
      username: 'NewUser',
      password: 'pw',
      age: 30,
      heightCm: 180,
      goal: UserGoal.maintenance,
      experienceLevel: ExperienceLevel.intermediate,
      workoutLocation: WorkoutLocation.gym,
    );
    expect(created.isSuccess, isTrue);

    final createdUser = await repo.loadDashboardUser(created.account!.id);
    expect(createdUser?.goal, UserGoal.maintenance);
    expect(createdUser?.todayWorkout, isNot('Chest Day'));

    await db.delete('users', where: 'id = ?', whereArgs: [created.account!.id]);
    final leftover = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [created.account!.id],
    );
    expect(leftover, isEmpty);

    final fk = await db.rawQuery('PRAGMA foreign_keys');
    expect(fk.first.values.first, 1);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = [for (final row in tables) row['name']];
    expect(names, contains('users'));
    expect(names, contains('user_profiles'));
    expect(names, contains('weight_logs'));
    expect(names, contains('workout_logs'));
    expect(names, isNot(contains('users_v1')));
    expect(names, isNot(contains('workout_history')));
  });
}
