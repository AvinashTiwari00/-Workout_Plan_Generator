import 'package:college_project/screens/workoutDetail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty workout cannot start', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WorkoutDetailScreen(
          workoutName: 'Empty',
          exercisesCount: 0,
          exercises: [],
        ),
      ),
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });
}
