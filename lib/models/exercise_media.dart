import 'workout_plan.dart';

class ExerciseMedia {
  const ExerciseMedia(this.path, this.instruction);
  final String path;
  final String instruction;

  static const entries = <String, ExerciseMedia>{
    'bodyweight squats': ExerciseMedia(
      'assets/exercises/bodyweight_squats.webp',
      'Stand with feet about shoulder-width apart. Bend your hips and knees, keep heels down, then stand up with control.',
    ),
    'wall push ups': ExerciseMedia(
      'assets/exercises/wall_push_ups.webp',
      'Place hands on a wall at shoulder height. Keep your body straight, bend elbows toward the wall, then push away.',
    ),
    'glute bridges': ExerciseMedia(
      'assets/exercises/glute_bridges.webp',
      'Lie on your back with knees bent and feet flat. Squeeze your glutes to lift your hips, then lower without arching your back.',
    ),
    'bird dogs': ExerciseMedia(
      'assets/exercises/bird_dogs.webp',
      'Start on hands and knees. Reach one arm and the opposite leg out while keeping your back and hips steady. Return and switch sides.',
    ),
    'standing calf raises': ExerciseMedia(
      'assets/exercises/standing_calf_raises.webp',
      'Stand tall and use a wall for balance if needed. Lift your heels, pause briefly, then lower slowly.',
    ),
    'plank': ExerciseMedia(
      'assets/exercises/plank.webp',
      'Place elbows under shoulders and support yourself on forearms and toes. Brace your core, keep your body straight, and breathe steadily.',
    ),
  };

  static ExerciseMedia? forExercise(String name) {
    final key = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[-_\u2010-\u2015]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    return entries[key];
  }

  static String instructionFor(String name) =>
      forExercise(name)?.instruction ??
      'Use controlled movement and a comfortable range. Follow the prescribed sets and reps; stop if you feel pain.';

  /// Rotate only among images that actually match this day's exercises.
  static String? categoryExercise(List<Exercise> exercises, int dayIndex) {
    final names = exercises
        .map((e) => e.name)
        .where((name) => forExercise(name) != null)
        .toSet()
        .toList();
    return names.isEmpty ? null : names[dayIndex % names.length];
  }
}
