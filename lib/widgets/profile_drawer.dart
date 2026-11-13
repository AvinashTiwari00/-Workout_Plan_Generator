import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../providers/user_provider.dart';
import '../providers/workout_provider.dart';
import '../screens/welcome_screen.dart';
import '../utils/session_store.dart';

/// Uses the saved session/profile already loaded by authenticated onboarding.
class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key, this.sessionStore});
  final SessionStore? sessionStore;

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  bool _confirming = false;
  bool _loggingOut = false;
  String? _error;

  Future<void> _logout() async {
    if (_confirming || _loggingOut) return;
    setState(() => _confirming = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (confirmed != true) return;

    final navigator = Navigator.of(context);
    final users = context.read<UserProvider>();
    final workouts = context.read<WorkoutProvider?>();
    setState(() {
      _loggingOut = true;
      _error = null;
    });
    try {
      // Do not clear memory or navigate unless durable session removal succeeds.
      await (widget.sessionStore ?? SessionStore()).clear();
      users.clear();
      workouts?.clearPlan();
      if (!navigator.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _loggingOut = false;
          _error =
              'Could not log out. Your session is still active. Please retry.';
        });
      }
    }
  }

  Widget _detail(IconData icon, String label, String? value) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    leading: Icon(icon, color: Colors.blue.shade700),
    title: Text(
      label,
      style: const TextStyle(fontSize: 13, color: Colors.black54),
    ),
    subtitle: Text(
      value == null || value.isEmpty ? 'Not set' : value,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final session = context.watch<UserProvider>();
    final account = session.account;
    final profile = account == null ? null : session.profile;
    final weight = session.user?.weight;
    return PopScope(
      canPop: !_loggingOut,
      child: Drawer(
        width: MediaQuery.sizeOf(context).width.clamp(0, 360).toDouble(),
        backgroundColor: const Color(0xFFF5F6FA),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade600, Colors.blue.shade900],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Close profile',
                                onPressed: _loggingOut
                                    ? null
                                    : () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            account?.username ?? 'Not signed in',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your fitness profile',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (account == null)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Sign in to view your saved profile.'),
                      )
                    else ...[
                      _detail(
                        Icons.flag_outlined,
                        'Fitness goal',
                        profile?.goal?.label,
                      ),
                      _detail(
                        Icons.fitness_center,
                        'Experience level',
                        profile?.experienceLevel?.label,
                      ),
                      _detail(
                        Icons.location_on_outlined,
                        'Workout location',
                        profile?.workoutLocation?.label,
                      ),
                      _detail(
                        Icons.calendar_month_outlined,
                        'Days per week',
                        profile?.daysPerWeek?.toString(),
                      ),
                      _detail(
                        Icons.cake_outlined,
                        'Age',
                        profile?.age?.toString(),
                      ),
                      _detail(
                        Icons.height,
                        'Height',
                        profile?.heightCm == null
                            ? null
                            : '${profile!.heightCm} cm',
                      ),
                      _detail(
                        Icons.monitor_weight_outlined,
                        'Latest weight',
                        weight == null || weight.isEmpty ? null : '$weight kg',
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      key: const ValueKey('profile-logout'),
                      onPressed: account == null || _confirming || _loggingOut
                          ? null
                          : _logout,
                      icon: _loggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.logout),
                      label: Text(_loggingOut ? 'Logging out...' : 'Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
