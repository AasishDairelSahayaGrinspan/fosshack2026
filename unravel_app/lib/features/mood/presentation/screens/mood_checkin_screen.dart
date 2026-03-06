import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/circumplex_data.dart';
import '../../domain/providers/mood_provider.dart';
import '../widgets/circumplex_wheel.dart';
import '../widgets/emotion_word_grid.dart';

enum _CheckinStep { quadrant, emotion, note }

class MoodCheckinScreen extends ConsumerStatefulWidget {
  const MoodCheckinScreen({super.key});
  @override
  ConsumerState<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends ConsumerState<MoodCheckinScreen> {
  _CheckinStep _step = _CheckinStep.quadrant;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Reset circumplex state when entering check-in
    Future.microtask(() {
      ref.read(circumplexStateProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  MoodQuadrant? _parseQuadrant(String? name) {
    if (name == null) return null;
    return MoodQuadrant.values.firstWhere(
      (q) => q.name == name,
      orElse: () => MoodQuadrant.highEnergyPleasant,
    );
  }

  Future<void> _submit() async {
    final position = ref.read(circumplexStateProvider);
    if (position.selectedWord == null || position.selectedQuadrant == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(moodHistoryProvider.notifier).submitMood(
            valence: position.valence,
            arousal: position.arousal,
            emotionWord: position.selectedWord!,
            quadrant: position.selectedQuadrant!,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood logged!')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save mood: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(circumplexStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Check-in'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step indicator
            LinearProgressIndicator(
              value: switch (_step) {
                _CheckinStep.quadrant => 0.33,
                _CheckinStep.emotion => 0.66,
                _CheckinStep.note => 1.0,
              },
            ),
            const SizedBox(height: 24),

            // Step title
            Text(
              switch (_step) {
                _CheckinStep.quadrant => 'How are you feeling?',
                _CheckinStep.emotion => 'Pick the word that fits best',
                _CheckinStep.note => 'Add a note (optional)',
              },
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Step content
            Expanded(
              child: switch (_step) {
                _CheckinStep.quadrant => CircumplexWheel(
                    onQuadrantSelected: (quadrant) {
                      ref
                          .read(circumplexStateProvider.notifier)
                          .selectQuadrant(quadrant.name);
                      setState(() => _step = _CheckinStep.emotion);
                    },
                  ),
                _CheckinStep.emotion => SingleChildScrollView(
                    child: EmotionWordGrid(
                      quadrant: _parseQuadrant(position.selectedQuadrant)!,
                      onEmotionSelected: (word) {
                        ref
                            .read(circumplexStateProvider.notifier)
                            .selectEmotion(word);
                        setState(() => _step = _CheckinStep.note);
                      },
                    ),
                  ),
                _CheckinStep.note => Column(
                    children: [
                      if (position.selectedWord != null)
                        Chip(
                          label: Text(position.selectedWord!),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText:
                                'What\'s on your mind? (optional)',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
              },
            ),

            // Back button for steps 2 and 3
            if (_step != _CheckinStep.quadrant)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _step = _step == _CheckinStep.note
                          ? _CheckinStep.emotion
                          : _CheckinStep.quadrant;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
