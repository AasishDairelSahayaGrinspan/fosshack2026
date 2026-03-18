import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

/// Journal Screen — cream paper-style with Lora font, mood tags, prompts.
/// Includes a "Past entries" section so users can view saved journals.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedMoodTag = -1;
  int _selectedPrompt = -1;
  bool _saved = false;
  bool _showHistory = false;
  List<Map<String, dynamic>> _entries = [];

  late AnimationController _saveAnimController;

  static const List<String> _moodTags = [
    'Grateful',
    'Calm',
    'Anxious',
    'Hopeful',
    'Tired',
    'Reflective',
  ];

  static const List<String> _prompts = [
    'What made you smile today?',
    'What\'s weighing on your mind?',
    'What are you grateful for?',
    'How did you take care of yourself?',
    'What would you tell your younger self?',
  ];

  @override
  void initState() {
    super.initState();
    _saveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadEntries();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _saveAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final result = await DatabaseService().getJournalEntries(user.$id, limit: 50);
      if (!mounted) return;
      setState(() {
        _entries = result.rows.map((r) => r.data).toList();
      });
    } catch (e, st) {
      developer.log('Failed to load journal entries', name: 'JournalScreen', error: e, stackTrace: st);
    }
  }

  Future<void> _saveEntry() async {
    if (_textController.text.trim().isEmpty) return;

    _saveAnimController.forward(from: 0);
    setState(() => _saved = true);

    final user = AuthService().currentUser;
    if (user != null) {
      try {
        await DatabaseService().saveJournalEntry(
          userId: user.$id,
          content: _textController.text.trim(),
          moodTag: _selectedMoodTag >= 0 ? _moodTags[_selectedMoodTag] : null,
          prompt: _selectedPrompt >= 0 ? _prompts[_selectedPrompt] : null,
        );
        _textController.clear();
        _selectedMoodTag = -1;
        _selectedPrompt = -1;
        await _loadEntries();
      } catch (e, st) {
        developer.log('Failed to save journal entry', name: 'JournalScreen', error: e, stackTrace: st);
      }
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _saved = false);
      }
    });
  }

  Future<void> _deleteEntry(String entryId) async {
    try {
      await DatabaseService().deleteJournalEntry(entryId);
      await _loadEntries();
    } catch (e, st) {
      developer.log('Failed to delete journal entry', name: 'JournalScreen', error: e, stackTrace: st);
    }
  }

  void _usePrompt(int index) {
    setState(() {
      _selectedPrompt = index;
      if (_textController.text.isEmpty) {
        _textController.text = '${_prompts[index]}\n\n';
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBg, AppColors.darkBgSecondary, AppColors.darkSurface]
                : [
                    AppColors.cream,
                    AppColors.lightBlush,
                    AppColors.softPeach,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Heading
                        Text(
                          _showHistory ? 'Past Reflections' : 'Today\'s Reflection',
                          style: AppTypography.heroHeadingC(context),
                        )
                            .animate()
                            .fadeIn(
                              duration: const Duration(milliseconds: 600),
                              curve: AppTheme.gentleCurve,
                            ),

                        const SizedBox(height: 4),
                        Text(
                          _formattedDate(),
                          style: AppTypography.captionC(context),
                        )
                            .animate()
                            .fadeIn(
                              duration: const Duration(milliseconds: 600),
                              curve: AppTheme.gentleCurve,
                            ),

                        const SizedBox(height: 16),

                        // Toggle Write / History
                        _buildViewToggle(),

                        const SizedBox(height: 20),

                        if (_showHistory)
                          _buildEntriesList()
                        else ...[
                          _buildMoodTags()
                              .animate(delay: const Duration(milliseconds: 150))
                              .fadeIn(
                                duration: const Duration(milliseconds: 500),
                                curve: AppTheme.gentleCurve,
                              ),
                          const SizedBox(height: 24),
                          _buildWritingField()
                              .animate(delay: const Duration(milliseconds: 250))
                              .fadeIn(
                                duration: const Duration(milliseconds: 500),
                                curve: AppTheme.gentleCurve,
                              )
                              .slideY(
                                begin: 0.04,
                                end: 0,
                                duration: const Duration(milliseconds: 500),
                                curve: AppTheme.gentleCurve,
                              ),
                          const SizedBox(height: 20),
                          _buildPrompts()
                              .animate(delay: const Duration(milliseconds: 350))
                              .fadeIn(
                                duration: const Duration(milliseconds: 500),
                                curve: AppTheme.gentleCurve,
                              ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildViewToggle() {
    return Row(
      children: [
        _buildToggleChip('Write', !_showHistory, () => setState(() => _showHistory = false)),
        const SizedBox(width: 8),
        _buildToggleChip(
          'Past entries${_entries.isNotEmpty ? ' (${_entries.length})' : ''}',
          _showHistory,
          () => setState(() => _showHistory = true),
        ),
      ],
    );
  }

  Widget _buildToggleChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fadeInDuration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.softIndigo.withValues(alpha: 0.12)
              : AppColors.card(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          border: Border.all(
            color: isActive
                ? AppColors.softIndigo.withValues(alpha: 0.4)
                : AppColors.dividerColor(context),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption(
            color: isActive ? AppColors.softIndigo : AppColors.secondary(context),
          ).copyWith(fontWeight: isActive ? FontWeight.w500 : FontWeight.w300),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (Navigator.of(context).canPop())
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary(context).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.secondary(context),
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 42),
          Text('Journal', style: AppTypography.uiLabelC(context)),
          // Save button
          GestureDetector(
            onTap: _showHistory ? null : _saveEntry,
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _saved
                    ? AppColors.sageGreen.withValues(alpha: 0.15)
                    : _showHistory
                        ? Colors.transparent
                        : AppColors.softIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                border: Border.all(
                  color: _saved
                      ? AppColors.sageGreen.withValues(alpha: 0.3)
                      : _showHistory
                          ? Colors.transparent
                          : AppColors.softIndigo.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: _showHistory
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _saved ? Icons.check_rounded : Icons.save_outlined,
                            key: ValueKey<bool>(_saved),
                            color: _saved
                                ? AppColors.sageGreen
                                : AppColors.softIndigo,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _saved ? 'Saved' : 'Save',
                          style: AppTypography.caption(
                            color: _saved
                                ? AppColors.sageGreen
                                : AppColors.softIndigo,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList() {
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.book_outlined,
                color: AppColors.tertiary(context).withValues(alpha: 0.4),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No entries yet.',
                style: AppTypography.subtitleC(context),
              ),
              const SizedBox(height: 6),
              Text(
                'Write your first reflection today.',
                style: AppTypography.captionC(context),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _entries.asMap().entries.map((entry) {
        final i = entry.key;
        final data = entry.value;
        return _buildEntryCard(data, i);
      }).toList(),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> data, int index) {
    final content = data['content'] as String? ?? '';
    final moodTag = data['moodTag'] as String?;
    final timestamp = data['timestamp'] as String?;
    final entryId = data['id'] as String?;

    String dateStr = '';
    if (timestamp != null) {
      final dt = DateTime.tryParse(timestamp);
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dateStr = '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card(context).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: AppColors.dividerColor(context).withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor(context),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — date + mood tag + delete
            Row(
              children: [
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: AppTypography.caption(
                      color: AppColors.tertiary(context),
                    ).copyWith(fontSize: 11),
                  ),
                if (moodTag != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.softIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    ),
                    child: Text(
                      moodTag,
                      style: AppTypography.caption(
                        color: AppColors.softIndigo,
                      ).copyWith(fontSize: 10),
                    ),
                  ),
                ],
                const Spacer(),
                if (entryId != null)
                  GestureDetector(
                    onTap: () => _confirmDelete(entryId),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.tertiary(context).withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Content
            Text(
              content,
              style: AppTypography.journalBodyC(context),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: const Duration(milliseconds: 300), curve: AppTheme.gentleCurve)
        .slideY(begin: 0.03, end: 0, duration: const Duration(milliseconds: 300));
  }

  void _confirmDelete(String entryId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text('Delete entry?', style: AppTypography.uiLabelC(context)),
        content: Text(
          'This reflection will be removed permanently.',
          style: AppTypography.bodyC(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.caption(color: AppColors.tertiary(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteEntry(entryId);
            },
            child: Text('Delete', style: AppTypography.caption(color: AppColors.warmCoral)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: AppTypography.uiLabel(color: AppColors.secondary(context)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_moodTags.length, (i) {
            final isSelected = _selectedMoodTag == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedMoodTag = i),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.softIndigo.withValues(alpha: 0.12)
                      : AppColors.card(context).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.softIndigo.withValues(alpha: 0.4)
                        : AppColors.dividerColor(context),
                    width: 1,
                  ),
                ),
                child: Text(
                  _moodTags[i],
                  style: AppTypography.caption(
                    color: isSelected
                        ? AppColors.softIndigo
                        : AppColors.secondary(context),
                  ).copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w500 : FontWeight.w300,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWritingField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: AppColors.dividerColor(context).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        minLines: 8,
        style: AppTypography.journalBodyC(context),
        decoration: InputDecoration(
          hintText: 'Begin writing...',
          hintStyle: AppTypography.journalBody(
            color: AppColors.tertiary(context).withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildPrompts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need a starting point?',
          style: AppTypography.uiLabel(color: AppColors.secondary(context)),
        ),
        const SizedBox(height: 12),
        ...List.generate(_prompts.length, (i) {
          final isSelected = _selectedPrompt == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _usePrompt(i),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.sageGreen.withValues(alpha: 0.08)
                      : AppColors.card(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.sageGreen.withValues(alpha: 0.3)
                        : AppColors.dividerColor(context).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: isSelected
                          ? AppColors.sageGreen
                          : AppColors.tertiary(context),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _prompts[i],
                        style: AppTypography.body(
                          color: isSelected
                              ? AppColors.sageGreen
                              : AppColors.secondary(context),
                        ).copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
