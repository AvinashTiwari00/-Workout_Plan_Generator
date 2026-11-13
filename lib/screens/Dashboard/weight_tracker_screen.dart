import '../../widgets/fitness_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_models.dart';
import '../../providers/user_provider.dart';
import '../../repositories/weight_repository.dart';

class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});
  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  final _controller = TextEditingController();
  final _repository = WeightRepository();
  List<WeightLog> _logs = [];
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final id = context.read<UserProvider>().account?.id;
      if (id == null) throw StateError('No session');
      final logs = await _repository.logsForUser(id);
      if (mounted) {
        setState(() {
          _logs = logs;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load weights. Reopen to retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final weight = double.tryParse(_controller.text.trim());
    if (weight == null || !weight.isFinite || weight <= 0 || weight > 500) {
      setState(() => _error = 'Enter a weight above 0 and up to 500 kg.');
      return;
    }
    final provider = context.read<UserProvider>();
    final id = provider.account?.id;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await _repository.addLog(userId: id, weightKg: weight);
      _controller.clear();
      await _load();
      await provider.refresh();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not update weight. Reopen to check before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FitnessPage(
    title: 'Weight Tracker',
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade900],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.monitor_weight_outlined,
                size: 36,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                _logs.isEmpty
                    ? 'No weight recorded'
                    : '${_logs.first.weightKg} kg',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Latest recorded weight',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FitnessCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Record your weight',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Loading...'),
                        ],
                      )
                    : const Text('Save Weight'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Weight History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (_logs.isEmpty && !_busy)
          const FitnessCard(
            child: Column(
              children: [
                Icon(Icons.insights, color: Colors.blue, size: 32),
                SizedBox(height: 8),
                Text(
                  'Your weight entries will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        for (final log in _logs)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: Colors.blue.shade700,
                ),
              ),
              title: Text(
                '${log.weightKg} kg',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                log.loggedAt.toLocal().toString().split('.').first,
              ),
            ),
          ),
      ],
    ),
  );
}
