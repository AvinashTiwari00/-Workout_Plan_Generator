import 'package:flutter/material.dart';
import '../models/exercise_media.dart';

class ExerciseImage extends StatelessWidget {
  const ExerciseImage({
    super.key,
    required this.exerciseName,
    this.height = 180,
  });
  final String exerciseName;
  final double height;

  Widget _fallback() => Container(
    height: height,
    width: double.infinity,
    color: const Color(0xFFF4F7FF),
    alignment: Alignment.center,
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.fitness_center, color: Colors.blue, size: 32),
        SizedBox(height: 8),
        Text(
          'Demonstration unavailable',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final media = ExerciseMedia.forExercise(exerciseName);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: media == null
          ? _fallback()
          : Image.asset(
              media.path,
              width: double.infinity,
              height: height,
              fit: BoxFit.contain,
              semanticLabel: '$exerciseName illustration',
              errorBuilder: (_, __, ___) => _fallback(),
            ),
    );
  }
}
