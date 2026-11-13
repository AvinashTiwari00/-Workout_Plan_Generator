import 'package:college_project/models/workout_plan.dart';
import 'package:college_project/screens/workoutDetail_screen.dart';
import 'package:college_project/utils/workout_session_clock.dart';
import 'package:college_project/widgets/exercise_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openWorkout(WidgetTester tester, WorkoutSessionClock clock) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkoutDetailScreen(
                  workoutName: 'Home',
                  exercisesCount: 2,
                  sessionClock: clock,
                  exercises: [
                    Exercise(name: 'Bodyweight Squats', sets: '2', reps: '10'),
                    Exercise(name: 'Wall Push-ups', sets: '2', reps: '10'),
                  ],
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start Workout'));
  await tester.pump();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  test(
    'clock excludes pauses, tolerates repeated controls and formats elapsed time',
    () {
      var now = Duration.zero;
      final clock = WorkoutSessionClock(now: () => now);
      clock.start();
      clock.start();
      now = const Duration(seconds: 65);
      expect(clock.display, '01:05');
      clock.pause();
      clock.pause();
      now = const Duration(seconds: 200);
      expect(clock.display, '01:05');
      clock.start();
      now = const Duration(seconds: 202);
      expect(clock.display, '01:07');
    },
  );

  testWidgets(
    'one exercise at a time, timer pause/resume, previous/next and abandonment confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = Duration.zero;
      final clock = WorkoutSessionClock(now: () => now);
      await openWorkout(tester, clock);
      expect(find.text('Exercise 1 of 2'), findsOneWidget);
      expect(find.text('Wall Push-ups'), findsNothing);
      expect(find.byType(ExerciseImage), findsOneWidget);
      await tapVisible(tester, find.text('Start Timer'));
      now = const Duration(seconds: 5);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:05'), findsOneWidget);
      await tapVisible(tester, find.text('Pause Timer'));
      now = const Duration(seconds: 100);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:05'), findsOneWidget);
      await tapVisible(tester, find.text('Resume Timer'));
      now = const Duration(seconds: 103);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:08'), findsOneWidget);
      await tapVisible(tester, find.text('Next Exercise'));
      expect(find.text('Exercise 2 of 2'), findsOneWidget);
      expect(find.text('Bodyweight Squats'), findsNothing);
      await tester.scrollUntilVisible(find.text('Finish Workout'), 200);
      expect(find.text('Finish Workout'), findsOneWidget);
      await tapVisible(tester, find.text('Previous Exercise'));
      expect(find.text('Exercise 1 of 2'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Leave workout?'), findsOneWidget);
      now = const Duration(seconds: 200);
      await tester.tap(find.text('Keep Working Out'));
      await tester.pump();
      expect(clock.elapsed, const Duration(seconds: 8));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave Workout'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(
        const Duration(seconds: 2),
      ); // disposed ticker cannot update UI
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('backgrounding pauses elapsed time until explicit resume', (
    tester,
  ) async {
    var now = Duration.zero;
    final clock = WorkoutSessionClock(now: () => now);
    await openWorkout(tester, clock);
    await tapVisible(tester, find.text('Start Timer'));
    now = const Duration(seconds: 4);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    now = const Duration(seconds: 100);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(clock.display, '00:04');
    expect(clock.isRunning, isFalse);
    await tester.pumpWidget(const SizedBox()); // dispose session/ticker
  });
}
