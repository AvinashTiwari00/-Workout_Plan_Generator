import 'dart:ui' as ui;
import 'package:college_project/models/exercise_media.dart';
import 'package:college_project/models/workout_plan.dart';
import 'package:college_project/widgets/exercise_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class BrokenBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object>{})!;
    }
    return ByteData.sublistView(Uint8List.fromList([1, 2, 3]));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all six actual WebP assets decode and have matching instructions',
    () async {
      expect(ExerciseMedia.entries, hasLength(6));
      for (final media in ExerciseMedia.entries.values) {
        final data = await rootBundle.load(media.path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(100));
        expect(frame.image.height, greaterThan(100));
        expect(codec.frameCount, 1);
        expect(media.instruction, isNotEmpty);
        frame.image.dispose();
        codec.dispose();
      }
      expect(
        ExerciseMedia.forExercise(' Wall Push-ups ')!.path,
        endsWith('wall_push_ups.webp'),
      );
      expect(
        identical(
          ExerciseMedia.forExercise('Bodyweight Squats'),
          ExerciseMedia.forExercise('bodyweight  squats'),
        ),
        isTrue,
      );
    },
  );

  test('category images rotate among relevant exercises only', () {
    final exercises = [
      'Bodyweight Squats',
      'Wall Push-ups',
      'Bird Dogs',
    ].map((name) => Exercise(name: name, sets: '2', reps: '10')).toList();
    expect({
      for (var i = 0; i < 3; i++) ExerciseMedia.categoryExercise(exercises, i),
    }, hasLength(3));
    expect(
      ExerciseMedia.categoryExercise([
        Exercise(name: 'Bench Press', sets: '3', reps: '10'),
      ], 0),
      isNull,
    );
  });

  testWidgets('unknown exercise retains offline fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExerciseImage(exerciseName: 'Bench Press')),
      ),
    );
    expect(find.text('Demonstration unavailable'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('failed/corrupt asset retains fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultAssetBundle(
            bundle: BrokenBundle(),
            child: const ExerciseImage(exerciseName: 'Plank'),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Demonstration unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
