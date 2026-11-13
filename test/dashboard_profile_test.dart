import 'dart:async';
import 'dart:io';
import 'package:college_project/database/database_helper.dart';
import 'package:college_project/models/user_models.dart';
import 'package:college_project/models/workout_plan.dart';
import 'package:college_project/providers/user_provider.dart';
import 'package:college_project/providers/workout_provider.dart';
import 'package:college_project/repositories/user_repository.dart';
import 'package:college_project/repositories/weight_repository.dart';
import 'package:college_project/repositories/workout_log_repository.dart';
import 'package:college_project/screens/dashboard_screen.dart';
import 'package:college_project/screens/Dashboard/weight_tracker_screen.dart';
import 'package:college_project/screens/Dashboard/workout_history_screen.dart';
import 'package:college_project/screens/welcome_screen.dart';
import 'package:college_project/utils/session_store.dart';
import 'package:college_project/widgets/profile_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ControlledSessionStore extends SessionStore {
  final gate = Completer<void>();
  int calls = 0;
  bool fail = true;
  @override
  Future<void> clear() async {
    calls++;
    await gate.future;
    if (fail) throw StateError('test session removal failure');
    await super.clear();
  }
}

Future<void> flush(WidgetTester tester) async {
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

Future<UserProvider> seed(String name) async {
  final users = UserRepository();
  final result = await users.createAccount(username: name, password: 'secret');
  final account = result.account!;
  await users.completeProfile(
    username: name,
    profile: UserProfile(
      userId: account.id,
      age: 29,
      gender: Gender.other,
      heightCm: 174,
      goal: UserGoal.fatLoss,
      experienceLevel: ExperienceLevel.intermediate,
      workoutLocation: WorkoutLocation.home,
      daysPerWeek: 4,
    ),
    weightKg: 69.5,
  );
  await WorkoutLogRepository().addLog(
    userId: account.id,
    workoutName: 'Saved workout',
  );
  await SessionStore().saveUserId(account.id);
  return UserProvider()..setSession(
    account: account,
    user: (await users.loadDashboardUser(account.id))!,
    profile: (await users.getProfile(account.id))!,
  );
}

Future<void> showDashboard(
  WidgetTester tester,
  UserProvider users,
  WorkoutProvider workouts,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: users),
        ChangeNotifierProvider.value(value: workouts),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardScreen(user: users.user!),
                ),
              ),
              child: const Text('Open dashboard'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open dashboard'));
  await flush(tester);
}

Future<void> openProfile(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Profile'));
  await tester.pumpAndSettle();
}

Finder get logoutButton => find.byKey(const ValueKey('profile-logout'));
Finder get confirmLogout => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(TextButton, 'Logout'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temp = await Directory.systemTemp.createTemp('dashboard_tests_');
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
    'drawer renders saved values safely on narrow screen; cancellation preserves session',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final users = (await tester.runAsync(() => seed('ProfileUser')))!;
      final workouts = WorkoutProvider()..generatePlan(UserGoal.fatLoss);
      final id = users.account!.id;
      await showDashboard(tester, users, workouts);
      await openProfile(tester);
      for (final value in [
        'ProfileUser',
        'Fat Loss',
        'Intermediate',
        'Home',
        '4',
      ]) {
        expect(
          find.descendant(of: find.byType(Drawer), matching: find.text(value)),
          findsOneWidget,
        );
      }
      expect(find.text(users.account!.passwordHash), findsNothing);
      final latest = find.text('69.5 kg');
      await tester.ensureVisible(latest);
      await tester.pump();
      expect(
        tester.getBottomLeft(latest).dy,
        lessThan(tester.getTopLeft(logoutButton).dy),
      );
      expect(logoutButton.hitTestable(), findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(users.account!.id, id);
      expect(await tester.runAsync(() => SessionStore().readUserId()), id);
      expect(workouts.currentPlan, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'confirmed logout clears all session state and stack; login restores saved data',
    (tester) async {
      final users = (await tester.runAsync(() => seed('RestoreUser')))!;
      final workouts = WorkoutProvider()..generatePlan(UserGoal.fatLoss);
      final id = users.account!.id;
      await showDashboard(tester, users, workouts);
      await openProfile(tester);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(confirmLogout);
      });
      await flush(tester);
      expect(await tester.runAsync(() => SessionStore().readUserId()), isNull);
      expect(users.account, isNull);
      expect(users.profile, isNull);
      expect(users.user, isNull);
      expect(workouts.currentPlan, isNull);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      expect(
        Navigator.of(tester.element(find.byType(WelcomeScreen))).canPop(),
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DashboardScreen), findsNothing);
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'RestoreUser');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret');
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      });
      await flush(tester);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(users.account!.id, id);
      expect(users.user!.weight, '69.5');
      expect(users.user!.completed, 1);
      expect(users.profile!.daysPerWeek, 4);
      expect(
        await tester.runAsync(() => WeightRepository().logsForUser(id)),
        hasLength(1),
      );
      expect(
        await tester.runAsync(() => WorkoutLogRepository().logsForUser(id)),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'logout failure preserves state, blocks repeated taps, and can be retried',
    (tester) async {
      final users = (await tester.runAsync(() => seed('FailureUser')))!;
      final workouts = WorkoutProvider()..generatePlan(UserGoal.maintenance);
      final store = ControlledSessionStore();
      final id = users.account!.id;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: users),
            ChangeNotifierProvider.value(value: workouts),
          ],
          child: MaterialApp(
            home: Scaffold(
              endDrawer: ProfileDrawer(sessionStore: store),
              appBar: AppBar(),
              body: const Text('Session page'),
            ),
          ),
        ),
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).openEndDrawer();
      await tester.pumpAndSettle();
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();
      await tester.tap(confirmLogout);
      await tester.pump();
      expect(store.calls, 1);
      expect(tester.widget<ElevatedButton>(logoutButton).onPressed, isNull);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(users.account!.id, id);
      store.gate.complete();
      await flush(tester);
      expect(find.textContaining('Could not log out.'), findsOneWidget);
      expect(await tester.runAsync(() => SessionStore().readUserId()), id);
      expect(users.user, isNotNull);
      expect(users.profile, isNotNull);
      expect(workouts.currentPlan, isNotNull);
      store.fail = false;
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(confirmLogout);
      });
      await flush(tester);
      expect(store.calls, 2);
      expect(users.account, isNull);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    },
  );

  testWidgets('drawer missing profile values use placeholders', (tester) async {
    final users = (await tester.runAsync(() => seed('PartialUser')))!;
    users.setAccount(
      users.account!,
      profile: UserProfile(userId: users.account!.id),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: users,
        child: const MaterialApp(home: Scaffold(endDrawer: ProfileDrawer())),
      ),
    );
    tester.state<ScaffoldState>(find.byType(Scaffold)).openEndDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Not set'), findsWidgets);
    expect(find.text('PartialUser'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard entry cards still open tracker and history', (
    tester,
  ) async {
    final users = (await tester.runAsync(() => seed('CardsUser')))!;
    await showDashboard(tester, users, WorkoutProvider());
    await tester.ensureVisible(find.text('Weight Tracker'));
    await tester.pump();
    await tester.tap(find.text('Weight Tracker'));
    await flush(tester);
    expect(find.byType(WeightTrackerScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Workout History'));
    await tester.pump();
    await tester.tap(find.text('Workout History'));
    await flush(tester);
    expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
    expect(find.text('Saved workout'), findsOneWidget);
  });
}
