import 'package:college_project/models/workout_plan.dart';

class User {
  final String name;
  final String todayWorkout;
  final int exercisesCount;
  final int completed;
  final int thisWeek;
  final String weight;
  final List<String> exercises;
  final Map<String, int> weeklyProgress;
  final UserGoal goal;
  //final List<WorkoutHistory> history;

  User({
    required this.name,
    required this.todayWorkout,
    required this.completed,
    required this.thisWeek,
    required this.exercisesCount,
    required this.exercises,
    required this.weight,
    required this.weeklyProgress,
    required this.goal,
    // required this.history,
  });

  /// Dashboard view built from the stored profile and that goal's plan.
  factory User.fromProfile({
    required String name,
    required UserProfile profile,
    required String weight,
    required String todayWorkout,
    required List<String> exercises,
    required int completed,
    required int thisWeek,
    required Map<String, int> weeklyProgress,
  }) {
    final goal = profile.goal;
    if (goal == null) {
      throw ArgumentError('Cannot build a dashboard user without a goal');
    }
    return User(
      name: name,
      todayWorkout: todayWorkout,
      completed: completed,
      thisWeek: thisWeek,
      exercisesCount: exercises.length,
      exercises: exercises,
      weight: weight,
      weeklyProgress: weeklyProgress,
      goal: goal,
    );
  }
}

class WorkoutHistory {
  final String category;
  final int exercises;
  final int calories;
  final DateTime date;

  WorkoutHistory({
    required this.category,
    required this.exercises,
    required this.calories,
    required this.date,
  });
}

enum ExperienceLevel {
  beginner,
  intermediate,
  advanced;

  String get label {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }

  static ExperienceLevel? fromStorage(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final level in ExperienceLevel.values) {
      if (level.name == value) return level;
    }
    return null;
  }
}

enum WorkoutLocation {
  home,
  gym,
  outdoor;

  String get label {
    switch (this) {
      case WorkoutLocation.home:
        return 'Home';
      case WorkoutLocation.gym:
        return 'Gym';
      case WorkoutLocation.outdoor:
        return 'Outdoor';
    }
  }

  static WorkoutLocation? fromStorage(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final location in WorkoutLocation.values) {
      if (location.name == value) return location;
    }
    return null;
  }
}

enum Gender {
  male,
  female,
  other;

  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  static Gender? fromStorage(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final gender in Gender.values) {
      if (gender.name == value) return gender;
    }
    return null;
  }

  static Gender? byLabel(String label) {
    for (final gender in Gender.values) {
      if (gender.label == label) return gender;
    }
    return null;
  }
}

extension UserGoalLabel on UserGoal {
  String get label {
    switch (this) {
      case UserGoal.muscleGain:
        return 'Muscle Gain';
      case UserGoal.fatLoss:
        return 'Fat Loss';
      case UserGoal.maintenance:
        return 'Stay Fit';
    }
  }

  static UserGoal? fromStorage(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final goal in UserGoal.values) {
      if (goal.name == value) return goal;
    }
    return null;
  }

  static UserGoal? byLabel(String label) {
    for (final goal in UserGoal.values) {
      if (goal.label == label) return goal;
    }
    return null;
  }
}

class UserAccount {
  const UserAccount({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  final int id;
  final String username;
  final String passwordHash;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory UserAccount.fromMap(Map<String, Object?> map) {
    return UserAccount(
      id: _requiredInt(map['id']),
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.userId,
    this.age,
    this.gender,
    this.heightCm,
    this.goal,
    this.experienceLevel,
    this.workoutLocation,
    this.daysPerWeek,
  });

  final int userId;
  final int? age;
  final Gender? gender;
  final double? heightCm;
  final UserGoal? goal;
  final ExperienceLevel? experienceLevel;
  final WorkoutLocation? workoutLocation;
  final int? daysPerWeek;

  /// Required fitness fields; weight is checked separately in weight_logs.
  bool get isComplete =>
      age != null &&
      age! >= 1 &&
      age! <= 120 &&
      gender != null &&
      heightCm != null &&
      heightCm!.isFinite &&
      heightCm! > 0 &&
      heightCm! <= 300 &&
      goal != null &&
      experienceLevel != null &&
      workoutLocation != null &&
      daysPerWeek != null &&
      daysPerWeek! >= 1 &&
      daysPerWeek! <= 7;

  UserProfile copyWith({
    int? userId,
    int? age,
    Gender? gender,
    double? heightCm,
    UserGoal? goal,
    ExperienceLevel? experienceLevel,
    WorkoutLocation? workoutLocation,
    int? daysPerWeek,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'age': age,
      'gender': gender?.name,
      'height_cm': heightCm,
      'goal': goal?.name,
      'experience_level': experienceLevel?.name,
      'workout_location': workoutLocation?.name,
      'days_per_week': daysPerWeek,
    };
  }

  factory UserProfile.fromMap(Map<String, Object?> map) {
    return UserProfile(
      userId: _requiredInt(map['user_id']),
      age: _optionalInt(map['age']),
      gender: Gender.fromStorage(map['gender'] as String?),
      heightCm: _optionalDouble(map['height_cm']),
      goal: UserGoalLabel.fromStorage(map['goal'] as String?),
      experienceLevel: ExperienceLevel.fromStorage(
        map['experience_level'] as String?,
      ),
      workoutLocation: WorkoutLocation.fromStorage(
        map['workout_location'] as String?,
      ),
      daysPerWeek: _optionalInt(map['days_per_week']),
    );
  }
}

class WeightLog {
  const WeightLog({
    this.id,
    required this.userId,
    required this.weightKg,
    required this.loggedAt,
  });

  final int? id;
  final int userId;
  final double weightKg;
  final DateTime loggedAt;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'weight_kg': weightKg,
      'logged_at': loggedAt.toUtc().toIso8601String(),
    };
  }

  factory WeightLog.fromMap(Map<String, Object?> map) {
    return WeightLog(
      id: _optionalInt(map['id']),
      userId: _requiredInt(map['user_id']),
      weightKg: _requiredDouble(map['weight_kg']),
      loggedAt: DateTime.parse(map['logged_at'] as String),
    );
  }
}

class WorkoutLog {
  const WorkoutLog({
    this.id,
    required this.userId,
    required this.workoutName,
    required this.completedAt,
  });

  final int? id;
  final int userId;
  final String workoutName;
  final DateTime completedAt;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'workout_name': workoutName,
      'completed_at': completedAt.toUtc().toIso8601String(),
    };
  }

  factory WorkoutLog.fromMap(Map<String, Object?> map) {
    return WorkoutLog(
      id: _optionalInt(map['id']),
      userId: _requiredInt(map['user_id']),
      workoutName: map['workout_name'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }
}

int _requiredInt(Object? value) {
  final parsed = _optionalInt(value);
  if (parsed == null) {
    throw ArgumentError('Expected an integer, got $value');
  }
  return parsed;
}

int? _optionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _requiredDouble(Object? value) {
  final parsed = _optionalDouble(value);
  if (parsed == null) {
    throw ArgumentError('Expected a number, got $value');
  }
  return parsed;
}

double? _optionalDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
