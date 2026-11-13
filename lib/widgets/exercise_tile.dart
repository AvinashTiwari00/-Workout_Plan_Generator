import 'package:flutter/material.dart';
import 'package:college_project/models/workout_plan.dart';

class ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final int index;

  const ExerciseTile({super.key, required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${exercise.sets} sets • ${exercise.reps} reps",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 70,
            width: 90,
            child: const Icon(
              Icons.fitness_center,
              size: 40,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
