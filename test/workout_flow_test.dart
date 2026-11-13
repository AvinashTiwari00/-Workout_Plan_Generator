import 'dart:io';
import 'package:college_project/database/database_helper.dart';
import 'package:college_project/models/user_models.dart';
import 'package:college_project/models/workout_plan.dart';
import 'package:college_project/providers/user_provider.dart';
import 'package:college_project/repositories/user_repository.dart';
import 'package:college_project/repositories/workout_log_repository.dart';
import 'package:college_project/repositories/weight_repository.dart';
import 'package:college_project/screens/workoutDetail_screen.dart';
import 'package:college_project/services/workout_plan_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temp = await Directory.systemTemp.createTemp('workout_tests_');
    await databaseFactory.setDatabasesPath(temp.path);
  });
  tearDownAll(() async {
    await (await DatabaseHelper.instance.database).close();
    await temp.delete(recursive: true);
  });
  test('generation respects all goals, locations, levels and days', () {
    final service = WorkoutPlanService();
    for (final goal in UserGoal.values) {
      for (final location in WorkoutLocation.values) {
        for (final level in ExperienceLevel.values) {
          for (var days = 1; days <= 7; days++) {
            final plan = service.generateForProfile(
              UserProfile(
                userId: 1,
                goal: goal,
                workoutLocation: location,
                experienceLevel: level,
                daysPerWeek: days,
              ),
            );
            expect(plan.schedule.length, days);
            expect(plan.workoutDays, days);
            expect(plan.goal, goal);
            for (final day in plan.schedule) {
              expect(day.exercises, isNotEmpty);
              expect(
                day.exercises.first.sets,
                level == ExperienceLevel.beginner
                    ? '2'
                    : level == ExperienceLevel.advanced
                    ? '4'
                    : '3',
              );
              if (location != WorkoutLocation.gym) {
                for (final exercise in day.exercises) {
                  expect(
                    exercise.name,
                    isNot(
                      matches(
                        RegExp(
                          'barbell|dumbbell|cable|press|pulldown',
                          caseSensitive: false,
                        ),
                      ),
                    ),
                  );
                }
              }
            }
          }
        }
      }
    }
    expect(
      service.generatePlan(UserGoal.maintenance, daysPerWeek: 0).workoutDays,
      1,
    );
    expect(
      service.generatePlan(UserGoal.maintenance, daysPerWeek: 99).workoutDays,
      7,
    );
    expect(
      service
          .generateForProfile(const UserProfile(userId: 1))
          .schedule
          .first
          .name,
      contains('No Equipment'),
    );
  });
  test(
    'logs are isolated, ordered, and reflected in dashboard progress',
    () async {
      final users = UserRepository();
      final a = await users.createAccount(
        username: 'logs_a',
        password: 'pw',
        goal: UserGoal.maintenance,
      );
      final b = await users.createAccount(
        username: 'logs_b',
        password: 'pw',
        goal: UserGoal.fatLoss,
      );
      final repo = WorkoutLogRepository();
      await repo.addLog(
        userId: a.account!.id,
        workoutName: 'Old',
        completedAt: DateTime.now().subtract(const Duration(days: 14)),
      );
      await repo.addLog(userId: a.account!.id, workoutName: 'Today');
      expect(
        (await repo.logsForUser(a.account!.id)).first.workoutName,
        'Today',
      );
      expect(await repo.logsForUser(b.account!.id), isEmpty);
      final dashboard = await users.loadDashboardUser(a.account!.id);
      expect(dashboard!.completed, 2);
      expect(dashboard.thisWeek, 1);
      expect(
        dashboard.weeklyProgress.values.where((v) => v == 1),
        hasLength(1),
      );
      final weights = WeightRepository();
      await weights.addLog(userId: a.account!.id, weightKg: 72);
      await weights.addLog(userId: a.account!.id, weightKg: 71);
      expect((await weights.latest(a.account!.id))!.weightKg, 71);
      expect(await weights.latest(b.account!.id), isNull);
      expect((await users.loadDashboardUser(a.account!.id))!.weight, '71');
      await expectLater(
        weights.addLog(userId: a.account!.id, weightKg: double.nan),
        throwsArgumentError,
      );
    },
  );
  testWidgets('start does not log; repeated complete taps save once', (
    tester,
  ) async {
    final result = (await tester.runAsync(
      () => UserRepository().createAccount(
        username: 'flow',
        password: 'pw',
        goal: UserGoal.maintenance,
      ),
    ))!;
    final provider = UserProvider()
      ..setAccount(result.account!, profile: result.profile);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(
                      workoutName: 'Demo',
                      exercisesCount: 1,
                      exercises: [
                        Exercise(name: 'Squat', sets: '2', reps: '10'),
                      ],
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout'));
    await tester.pump();
    expect(
      await tester.runAsync(
        () => WorkoutLogRepository().logsForUser(result.account!.id),
      ),
      isEmpty,
    );
    await tester.scrollUntilVisible(find.text('Finish Workout'), 250);
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Finish Workout'));
      await tester.tap(find.text('Finish Workout'));
    });
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(
        () => WorkoutLogRepository().logsForUser(result.account!.id),
      ),
      hasLength(1),
    );
  });
}
