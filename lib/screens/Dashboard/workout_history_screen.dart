import '../../widgets/fitness_page.dart';
import 'package:flutter/material.dart';
import '../../models/user_models.dart';
import '../../repositories/workout_log_repository.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  final int userId;
  const WorkoutHistoryScreen({super.key, required this.userId});
  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late final Future<List<WorkoutLog>> _logs = WorkoutLogRepository()
      .logsForUser(widget.userId);
  @override
  Widget build(BuildContext context) => FitnessPage(
    title: 'Workout History',
    body: FutureBuilder<List<WorkoutLog>>(
      future: _logs,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const FitnessState(
            icon: Icons.error_outline,
            message: 'Could not load history. Please reopen to retry.',
            error: true,
          );
        }
        if (!snapshot.hasData) {
          return const FitnessState(
            icon: Icons.history,
            message: 'Loading your workouts...',
            loading: true,
          );
        }
        final logs = snapshot.data!;
        if (logs.isEmpty) {
          return const FitnessState(
            icon: Icons.fitness_center,
            message:
                'No workouts completed yet.\nYour completed sessions will appear here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final log in logs)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  title: Text(
                    log.workoutName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    log.completedAt.toLocal().toString().split('.').first,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
