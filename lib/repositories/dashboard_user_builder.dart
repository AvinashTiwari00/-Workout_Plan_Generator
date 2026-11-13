import 'package:college_project/models/user_models.dart';
import 'package:college_project/services/workout_plan_service.dart';

/// Builds the dashboard [User] from a stored profile and that goal's plan.
User buildDashboardUser({
  required String name,
  required UserProfile profile,
  double? weightKg,
  List<WorkoutLog> workoutLogs = const [],
}) {
  final goal = profile.goal;
  if (goal == null) {
    throw ArgumentError(
      'A profile goal is required to build the dashboard user',
    );
  }

  final plan = WorkoutPlanService().generateForProfile(profile);
  var todayWorkout = '';
  var exercises = const <String>[];
  if (plan.schedule.isNotEmpty) {
    // Monday uses the first session. Shorter plans wrap through the week.
    final index = (DateTime.now().weekday - 1) % plan.schedule.length;
    final day = plan.schedule[index];
    todayWorkout = day.name;
    exercises = [for (final exercise in day.exercises) exercise.name];
  }

  return User.fromProfile(
    name: name,
    profile: profile,
    weight: _formatWeight(weightKg),
    todayWorkout: todayWorkout,
    exercises: exercises,
    completed: workoutLogs.length,
    thisWeek: _countThisWeek(workoutLogs),
    weeklyProgress: _weeklyProgress(workoutLogs),
  );
}

String _formatWeight(double? weightKg) {
  if (weightKg == null) return '';
  if (weightKg == weightKg.roundToDouble()) {
    return weightKg.toStringAsFixed(0);
  }
  return weightKg.toString();
}

Map<String, int> _weeklyProgress(List<WorkoutLog> logs) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final progress = {for (final label in labels) label: 0};
  for (final log in logs) {
    if (!_inCurrentWeek(log.completedAt)) continue;
    progress[labels[log.completedAt.toLocal().weekday - 1]] = 1;
  }
  return progress;
}

int _countThisWeek(List<WorkoutLog> logs) {
  var count = 0;
  for (final log in logs) {
    if (_inCurrentWeek(log.completedAt)) count++;
  }
  return count;
}

bool _inCurrentWeek(DateTime timestamp) {
  final now = DateTime.now();
  final start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final end = start.add(const Duration(days: 7));
  final local = timestamp.toLocal();
  return !local.isBefore(start) && local.isBefore(end);
}
