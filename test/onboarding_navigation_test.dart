import 'dart:io';
import 'package:college_project/database/database_helper.dart';
import 'package:college_project/main.dart';
import 'package:college_project/models/user_models.dart';
import 'package:college_project/models/workout_plan.dart';
import 'package:college_project/providers/user_provider.dart';
import 'package:college_project/repositories/user_repository.dart';
import 'package:college_project/repositories/weight_repository.dart';
import 'package:college_project/repositories/workout_log_repository.dart';
import 'package:college_project/screens/dashboard_screen.dart';
import 'package:college_project/screens/login_screen.dart';
import 'package:college_project/screens/signup_screen.dart';
import 'package:college_project/screens/user_input_screen.dart';
import 'package:college_project/screens/welcome_screen.dart';
import 'package:college_project/utils/session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Finder field(String label) => find.ancestor(
  of: find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  ),
  matching: find.byType(TextFormField),
);

Future<void> flush(WidgetTester tester) async {
  // FFI database work needs real event-loop turns between fake-clock frames.
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (i > 3 &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty &&
        tester.binding.transientCallbackCount == 0) {
      break;
    }
  }
}

Future<void> boot(WidgetTester tester, UserProvider provider) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(value: provider, child: const WorkoutApp()),
  );
  await tester.pump(const Duration(seconds: 1));
  await flush(tester);
}

Future<void> press(WidgetTester tester, Finder finder) async {
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.runAsync(() async {
    await tester.tap(finder);
  });
  await flush(tester);
}

Future<UserAccount> seed(String name, {bool complete = true}) async {
  final users = UserRepository();
  final result = await users.createAccount(
    username: name,
    password: 'secret',
    goal: UserGoal.fatLoss,
  );
  final account = result.account!;
  if (complete) {
    expect(
      await users.completeProfile(
        username: name,
        profile: UserProfile(
          userId: account.id,
          age: 30,
          gender: Gender.other,
          heightCm: 175,
          goal: UserGoal.fatLoss,
          experienceLevel: ExperienceLevel.advanced,
          workoutLocation: WorkoutLocation.gym,
          daysPerWeek: 5,
        ),
        weightKg: 72.5,
      ),
      isNull,
    );
  }
  return account;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temp = await Directory.systemTemp.createTemp('onboarding_tests_');
    await databaseFactory.setDatabasesPath(temp.path);
    await DatabaseHelper.instance.database;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDownAll(() async {
    await (await DatabaseHelper.instance.database).close();
    await temp.delete(recursive: true);
  });

  testWidgets(
    'Get Started creates one account then profile then Dashboard; Back cannot return to auth',
    (tester) async {
      final provider = UserProvider();
      await boot(tester, provider);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Skip for now'), findsNothing);
      await press(tester, find.text('Get Started'));
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      await tester.enterText(field('Name'), 'NewUser1');
      await tester.enterText(field('Password'), 'secret');
      await press(tester, find.widgetWithText(ElevatedButton, 'Sign Up'));
      expect(find.byType(UserInputScreen), findsOneWidget);
      final id = provider.account!.id;
      expect(await tester.runAsync(() => SessionStore().readUserId()), id);
      expect(
        await tester.runAsync(() => WeightRepository().logsForUser(id)),
        isEmpty,
      );
      expect(
        Navigator.of(tester.element(find.byType(UserInputScreen))).canPop(),
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(SignupScreen), findsNothing);
      expect(find.byType(UserInputScreen), findsOneWidget);
      await tester.enterText(field('Age'), '25');
      await tester.enterText(field('Weight (kg)'), '70.5');
      await tester.enterText(field('Height (cm)'), '172');
      final button = find.widgetWithText(ElevatedButton, 'Continue');
      await tester.pump();
      await tester.ensureVisible(button);
      await tester.runAsync(() async {
        await tester.tap(button);
        await tester.tap(button);
      });
      await flush(tester);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(provider.account!.username, 'NewUser1');
      expect(provider.profile!.isComplete, isTrue);
      expect(
        await tester.runAsync(() => WeightRepository().logsForUser(id)),
        hasLength(1),
      );
      final accounts = await tester.runAsync(
        () async => (await DatabaseHelper.instance.database).query(
          'users',
          where: 'username = ?',
          whereArgs: ['NewUser1'],
        ),
      );
      expect(accounts, hasLength(1));
      expect(
        Navigator.of(tester.element(find.byType(DashboardScreen))).canPop(),
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(SignupScreen), findsNothing);
      expect(find.byType(UserInputScreen), findsNothing);
    },
  );

  testWidgets(
    'returning login uses complete profile and clears auth routes without resetting data',
    (tester) async {
      final account = (await tester.runAsync(() => seed('Returning1')))!;
      final provider = UserProvider();
      await boot(tester, provider);
      await press(tester, find.text('Login'));
      await tester.enterText(field('Name'), account.username);
      await tester.enterText(field('Password'), 'secret');
      await press(tester, find.widgetWithText(ElevatedButton, 'Login'));
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(provider.profile!.workoutLocation, WorkoutLocation.gym);
      expect(provider.profile!.experienceLevel, ExperienceLevel.advanced);
      expect(provider.profile!.daysPerWeek, 5);
      expect(provider.user!.weight, '72.5');
      expect(
        await tester.runAsync(() => WeightRepository().logsForUser(account.id)),
        hasLength(1),
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsNothing);
    },
  );

  testWidgets(
    'persisted complete session bypasses Welcome through app Splash',
    (tester) async {
      final account = (await tester.runAsync(() => seed('Persisted1')))!;
      await tester.runAsync(() => SessionStore().saveUserId(account.id));
      final provider = UserProvider();
      await boot(tester, provider);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(provider.account!.id, account.id);
      expect(
        Navigator.of(tester.element(find.byType(DashboardScreen))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets(
    'goal-only profile is incomplete on login and survives interrupted setup',
    (tester) async {
      final account = (await tester.runAsync(
        () => seed('Interrupted1', complete: false),
      ))!;
      await boot(tester, UserProvider());
      await press(tester, find.text('Login'));
      await tester.enterText(field('Name'), account.username);
      await tester.enterText(field('Password'), 'secret');
      await press(tester, find.widgetWithText(ElevatedButton, 'Login'));
      expect(find.byType(UserInputScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      expect(
        tester.widget<TextFormField>(field('Full Name')).controller!.text,
        account.username,
      );
      // Simulate process restart with a new provider/app, retaining disk session.
      await tester.pumpWidget(const SizedBox());
      final restarted = UserProvider();
      await boot(tester, restarted);
      expect(find.byType(UserInputScreen), findsOneWidget);
      expect(restarted.account!.id, account.id);
      expect(restarted.profile!.goal, UserGoal.fatLoss);
      expect(
        await tester.runAsync(() => WeightRepository().logsForUser(account.id)),
        isEmpty,
      );
      expect(
        Navigator.of(tester.element(find.byType(UserInputScreen))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets(
    'legacy partial profile pre-fills saved preferences and weight without adding entries',
    (tester) async {
      final account = (await tester.runAsync(
        () => seed('Legacy1', complete: false),
      ))!;
      await tester.runAsync(() async {
        await UserRepository().saveProfile(
          UserProfile(
            userId: account.id,
            age: 41,
            heightCm: 180,
            goal: UserGoal.maintenance,
            experienceLevel: ExperienceLevel.intermediate,
            workoutLocation: WorkoutLocation.outdoor,
            daysPerWeek: 4,
          ),
        );
        await WeightRepository().addLog(userId: account.id, weightKg: 81);
        await SessionStore().saveUserId(account.id);
      });
      final provider = UserProvider();
      await boot(tester, provider);
      expect(find.byType(UserInputScreen), findsOneWidget);
      expect(tester.widget<TextFormField>(field('Age')).controller!.text, '41');
      expect(
        tester.widget<TextFormField>(field('Weight (kg)')).controller!.text,
        '81',
      );
      final button = find.widgetWithText(ElevatedButton, 'Continue');
      await press(tester, button);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(provider.profile!.experienceLevel, ExperienceLevel.intermediate);
      expect(provider.profile!.workoutLocation, WorkoutLocation.outdoor);
      expect(provider.profile!.daysPerWeek, 4);
      expect(provider.profile!.goal, UserGoal.maintenance);
      expect(
        await tester.runAsync(() => WeightRepository().logsForUser(account.id)),
        hasLength(1),
      );
    },
  );

  test(
    'profile save retries do not duplicate weight; conflicts preserve profile and logs',
    () async {
      final account = await seed('Atomic1');
      await seed('Taken1');
      final users = UserRepository();
      final original = (await users.getProfile(account.id))!;
      await WorkoutLogRepository().addLog(
        userId: account.id,
        workoutName: 'Keep workout',
      );
      expect(
        await users.completeProfile(
          username: account.username,
          profile: original,
          weightKg: 72.5,
        ),
        isNull,
      );
      expect(
        await users.completeProfile(
          username: 'Taken1',
          profile: original.copyWith(age: 50),
          weightKg: 80,
        ),
        'Username is already taken',
      );
      expect((await users.getProfile(account.id))!.age, 30);
      expect(await WeightRepository().logsForUser(account.id), hasLength(1));
      expect(
        await WorkoutLogRepository().logsForUser(account.id),
        hasLength(1),
      );
      expect(await users.hasCompleteProfile(account.id), isTrue);
      expect(
        await users
            .createAccount(username: 'atomic1', password: 'other')
            .then((r) => r.isSuccess),
        isFalse,
      );
    },
  );
  test('completeness checks every required stored field', () {
    const complete = UserProfile(
      userId: 1,
      age: 20,
      gender: Gender.female,
      heightCm: 165,
      goal: UserGoal.muscleGain,
      experienceLevel: ExperienceLevel.beginner,
      workoutLocation: WorkoutLocation.home,
      daysPerWeek: 3,
    );
    expect(complete.isComplete, isTrue);
    for (final field in [
      'age',
      'gender',
      'height_cm',
      'goal',
      'experience_level',
      'workout_location',
      'days_per_week',
    ]) {
      final map = complete.toMap()..[field] = null;
      expect(UserProfile.fromMap(map).isComplete, isFalse, reason: field);
    }
    expect(complete.copyWith(daysPerWeek: 0).isComplete, isFalse);
    expect(complete.copyWith(daysPerWeek: 8).isComplete, isFalse);
  });

  test('complete fitness fields still require a weight entry', () async {
    final account = await seed('NoWeight1');
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'weight_logs',
      where: 'user_id = ?',
      whereArgs: [account.id],
    );
    expect(await UserRepository().hasCompleteProfile(account.id), isFalse);
  });
}
