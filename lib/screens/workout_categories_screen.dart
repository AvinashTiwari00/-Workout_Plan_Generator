import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/user_models.dart';
import '../models/exercise_media.dart';
import '../providers/user_provider.dart';
import '../services/workout_plan_service.dart';
import '../widgets/exercise_image.dart';
import '../widgets/fitness_page.dart';

class WorkoutCategoriesScreen extends StatelessWidget {
  const WorkoutCategoriesScreen({super.key});

  List<MenuItem> _getMenuItems(User user, UserProfile? profile) {
    final plan = profile == null
        ? WorkoutPlanService().generatePlan(user.goal)
        : WorkoutPlanService().generateForProfile(profile);
    return List.generate(plan.schedule.length, (index) {
      final day = plan.schedule[index];
      return MenuItem(
        title: day.name,
        route: '/workout-detail',
        screenName: 'WorkoutDetailScreen',
        arguments: {
          'exercises': day.exercises,
          'exercisesCount': day.exercises.length,
          'imageExercise': ExerciseMedia.categoryExercise(day.exercises, index),
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ModalRoute.of(context)!.settings.arguments as User;
    final items = _getMenuItems(user, context.watch<UserProvider>().profile);
    return FitnessPage(
      title: 'Workout Categories',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      Navigator.pushNamed(context, item.route, arguments: item),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.blue.shade50],
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final details = Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${(item.arguments as Map)['exercisesCount']} Exercises',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'View Workout',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                        final image = ExerciseImage(
                          exerciseName:
                              (item.arguments as Map)['imageExercise']
                                  as String? ??
                              '',
                          height: 160,
                        );
                        return constraints.maxWidth < 400
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [image, details],
                              )
                            : Row(
                                children: [
                                  Expanded(child: details),
                                  SizedBox(width: 160, child: image),
                                ],
                              );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
