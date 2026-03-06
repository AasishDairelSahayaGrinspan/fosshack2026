import 'package:flutter/material.dart';
import '../../domain/models/journal_entry.dart';

class TagSelector extends StatelessWidget {
  final Set<JournalTag> selectedTags;
  final void Function(Set<JournalTag> tags) onChanged;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  Color _tagColor(JournalTag tag) {
    switch (tag) {
      case JournalTag.sleep:
        return Colors.indigo;
      case JournalTag.caffeine:
        return Colors.brown;
      case JournalTag.social:
        return Colors.pink;
      case JournalTag.exercise:
        return Colors.teal;
      case JournalTag.medication:
        return Colors.deepPurple;
      case JournalTag.therapy:
        return Colors.cyan;
      case JournalTag.other:
        return Colors.grey;
    }
  }

  String _tagLabel(JournalTag tag) {
    switch (tag) {
      case JournalTag.sleep:
        return 'Sleep';
      case JournalTag.caffeine:
        return 'Caffeine';
      case JournalTag.social:
        return 'Social';
      case JournalTag.exercise:
        return 'Exercise';
      case JournalTag.medication:
        return 'Medication';
      case JournalTag.therapy:
        return 'Therapy';
      case JournalTag.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: JournalTag.values.map((tag) {
        final isSelected = selectedTags.contains(tag);
        final color = _tagColor(tag);
        return FilterChip(
          label: Text(_tagLabel(tag)),
          selected: isSelected,
          onSelected: (selected) {
            final newSet = Set<JournalTag>.from(selectedTags);
            if (selected) {
              newSet.add(tag);
            } else {
              newSet.remove(tag);
            }
            onChanged(newSet);
          },
          selectedColor: color.withOpacity(0.2),
          checkmarkColor: color,
          labelStyle: TextStyle(
            color: isSelected ? color : null,
          ),
          side: BorderSide(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        );
      }).toList(),
    );
  }
}
