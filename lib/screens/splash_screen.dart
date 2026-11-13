import '../utils/authenticated_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_project/providers/user_provider.dart';
import 'package:college_project/repositories/user_repository.dart';
import 'package:college_project/screens/welcome_screen.dart';
import 'package:college_project/utils/session_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _session = SessionStore();
  final _users = UserRepository();
  bool _checked = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _startCheck();
  }

  Future<void> _startCheck() async {
    if (_checked) return;
    _checked = true;
    if (mounted) setState(() => _error = false);

    // Small delay so navigation happens after first frame
    await Future.delayed(const Duration(seconds: 1));

    try {
      final userId = await _session.readUserId();
      if (!mounted) return;

      if (userId == null) {
        _openWelcome();
        return;
      }

      final account = await _users.getAccount(userId);
      if (!mounted) return;
      if (account == null) {
        await _session.clear();
        if (!mounted) return;
        _openWelcome();
        return;
      }

      await openAuthenticatedHome(context, account);
    } catch (e) {
      debugPrint('Splash auth error: $e');
      if (!mounted) return;
      setState(() {
        _error = true;
        _checked = false;
      });
    }
  }

  void _openWelcome() {
    context.read<UserProvider>().clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 72, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  "FitPlan",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                SizedBox(height: 24),
                if (_error) ...[
                  const Text(
                    'Could not restore your session. Please retry.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _startCheck,
                    child: const Text('Retry'),
                  ),
                ] else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
