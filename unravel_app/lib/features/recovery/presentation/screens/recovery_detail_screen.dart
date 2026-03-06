import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/recovery_provider.dart';

class RecoveryDetailScreen extends ConsumerWidget {
  const RecoveryDetailScreen({super.key});

  Color _scoreColor(double score) {
    if (score >= 81) return Colors.green;
    if (score >= 41) return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(double score) {
    if (score >= 81) return 'Peak Recovery';
    if (score >= 41) return 'Moderate Recovery';
    return 'Low Recovery';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recovery = ref.watch(recoveryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Score')),
      body: recovery.when(
        data: (score) {
          if (score == null) {
            return const Center(
              child: Text(
                'No recovery data yet.\nConnect your health data in Settings.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _scoreColor(score.score), width: 6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score.score.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _scoreColor(score.score),
                        ),
                      ),
                      Text(
                        _scoreLabel(score.score),
                        style: TextStyle(
                          fontSize: 14,
                          color: _scoreColor(score.score),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _ZScoreRow(label: 'HRV', value: score.hrvZScore),
                _ZScoreRow(label: 'Resting HR', value: score.rhrZScore),
                _ZScoreRow(label: 'Sleep Quality', value: score.sleepZScore),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ZScoreRow extends StatelessWidget {
  final String label;
  final double? value;
  const _ZScoreRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value != null ? value!.toStringAsFixed(2) : 'N/A',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: value != null
                  ? (value! >= 0 ? Colors.green : Colors.red)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
