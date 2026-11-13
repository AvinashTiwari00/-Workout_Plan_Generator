import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../models/exercise_media.dart';
import '../providers/user_provider.dart';
import '../repositories/workout_log_repository.dart';
import '../utils/workout_session_clock.dart';
import '../widgets/exercise_image.dart';
import '../widgets/fitness_page.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutName;
  final int exercisesCount;
  final List<Exercise> exercises;
  final WorkoutSessionClock? sessionClock;
  const WorkoutDetailScreen({
    super.key,
    required this.workoutName,
    required this.exercisesCount,
    required this.exercises,
    this.sessionClock,
  });
  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen>
    with WidgetsBindingObserver {
  bool _started = false, _saving = false, _completed = false;
  bool _allowLeave = false, _exitDialog = false, _timerStarted = false;
  int _index = 0;
  Timer? _ticker;
  final _sessionScroll = ScrollController();
  late final WorkoutSessionClock _clock;

  @override
  void initState() {
    super.initState();
    _clock = widget.sessionClock ?? WorkoutSessionClock();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sessionScroll.dispose();
    _clock.pause();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _clock.isRunning) {
      _clock.pause();
      if (mounted) setState(() {});
    }
  }

  void _startWorkout() {
    if (_started || widget.exercises.isEmpty) return;
    setState(() => _started = true);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && _clock.isRunning) setState(() {});
    });
  }

  void _moveExercise(int delta) {
    if (_saving) return;
    final next = _index + delta;
    if (next < 0 || next >= widget.exercises.length) return;
    setState(() => _index = next);
    if (_sessionScroll.hasClients) _sessionScroll.jumpTo(0);
  }

  void _toggleTimer() {
    if (_saving) return;
    setState(() {
      if (_clock.isRunning) {
        _clock.pause();
      } else {
        _timerStarted = true;
        _clock.start();
      }
    });
  }

  Future<void> _confirmExit() async {
    if (_exitDialog || _saving || !mounted) return;
    _exitDialog = true;
    final wasRunning = _clock.isRunning;
    setState(() => _clock.pause());
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave workout?'),
        content: const Text('Your unfinished workout will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Working Out'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave Workout'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _exitDialog = false;
    if (leave == true) {
      setState(() => _allowLeave = true);
      // Allow PopScope to rebuild before asking Navigator to leave.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } else if (wasRunning) {
      setState(() => _clock.start());
    }
  }

  Future<void> _finish() async {
    if (_saving || _completed || _index != widget.exercises.length - 1) return;
    final id = context.read<UserProvider>().account?.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save a workout.')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _clock.pause();
    });
    try {
      await WorkoutLogRepository().addLog(
        userId: id,
        workoutName: widget.workoutName,
      );
      if (!mounted) return;
      setState(() {
        _completed = true;
        _saving = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save workout. Please retry.'),
          ),
        );
      }
    }
  }

  Widget _exerciseDetails(Exercise exercise) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        exercise.name,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(
        '${exercise.sets} sets / ${exercise.reps} reps',
        style: TextStyle(
          color: Colors.blue.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        ExerciseMedia.instructionFor(exercise.name),
        style: const TextStyle(height: 1.5, color: Colors.black87),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && (!_started || _completed || _allowLeave),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _started && !_saving) _confirmExit();
    },
    child: FitnessPage(
      title: widget.workoutName,
      body: !_started
          ? Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        '${widget.exercises.length} Exercises',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final exercise in widget.exercises)
                        FitnessCard(
                          child: Column(
                            children: [
                              ExerciseImage(exerciseName: exercise.name),
                              const SizedBox(height: 16),
                              _exerciseDetails(exercise),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.exercises.isEmpty
                          ? null
                          : _startWorkout,
                      child: const Text('Start Workout'),
                    ),
                  ),
                ),
              ],
            )
          : ListView(
              controller: _sessionScroll,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Exercise ${_index + 1} of ${widget.exercises.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  color: Colors.blue.shade700,
                  backgroundColor: Colors.blue.shade100,
                  value: (_index + 1) / widget.exercises.length,
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                FitnessCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExerciseImage(
                        exerciseName: widget.exercises[_index].name,
                        height: 240,
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: 'Elapsed workout time',
                        child: Text(
                          _clock.display,
                          key: const ValueKey('elapsed-time'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const Text(
                        'Elapsed time',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade800,
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                        onPressed: _saving ? null : _toggleTimer,
                        icon: Icon(
                          _clock.isRunning ? Icons.pause : Icons.play_arrow,
                        ),
                        label: Text(
                          _clock.isRunning
                              ? 'Pause Timer'
                              : _timerStarted
                              ? 'Resume Timer'
                              : 'Start Timer',
                        ),
                      ),
                      const SizedBox(height: 20),
                      _exerciseDetails(widget.exercises[_index]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade800,
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                      onPressed: _saving || _index == 0
                          ? null
                          : () => _moveExercise(-1),
                      child: const Text('Previous Exercise'),
                    ),
                    if (_index < widget.exercises.length - 1)
                      ElevatedButton(
                        onPressed: _saving ? null : () => _moveExercise(1),
                        child: const Text('Next Exercise'),
                      ),
                  ],
                ),
                if (_index == widget.exercises.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: _saving || _completed ? null : _finish,
                      child: Text(_saving ? 'Saving...' : 'Finish Workout'),
                    ),
                  ),
              ],
            ),
    ),
  );
}
