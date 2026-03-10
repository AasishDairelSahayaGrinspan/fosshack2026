import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/doodle_refresh.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

/// Journal Screen — cream paper-style with Lora font, mood tags, prompts.
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
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _saveAnimController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_textController.text.trim().isEmpty) return;

    _saveAnimController.forward(from: 0);
    setState(() => _saved = true);

    // Save to Appwrite
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        await DatabaseService().saveJournalEntry(
          userId: user.$id,
          content: _textController.text.trim(),
          moodTag: _selectedMoodTag >= 0 ? _moodTags[_selectedMoodTag] : null,
          prompt: _selectedPrompt >= 0 ? _prompts[_selectedPrompt] : null,
        );
      } catch (_) {
        // Saved locally, sync later
      }
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _saved = false);
      }
    });
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
        // Paper background — adapts to dark mode
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBg, AppColors.darkBgSecondary, AppColors.darkSurface]
                : [
                    const Color(0xFFFAF6F0),
                    const Color(0xFFF5EDE3),
                    const Color(0xFFF0E8DB),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Top Bar ───
              _buildTopBar(),

              // ─── Content ───
              Expanded(
                child: DoodleRefresh(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ─── Heading ───
                      Text(
                        'Today\'s Reflection',
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

                      const SizedBox(height: 24),

                      // ─── Mood Tags ───
                      _buildMoodTags()
                          .animate(delay: const Duration(milliseconds: 150))
                          .fadeIn(
                            duration: const Duration(milliseconds: 500),
                            curve: AppTheme.gentleCurve,
                          ),

                      const SizedBox(height: 24),

                      // ─── Writing Field ───
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

                      // ─── Prompt Suggestions ───
                      _buildPrompts()
                          .animate(delay: const Duration(milliseconds: 350))
                          .fadeIn(
                            duration: const Duration(milliseconds: 500),
                            curve: AppTheme.gentleCurve,
                          ),

                      const SizedBox(height: 32),
                    ],
                  ),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          ),
          Text('Journal', style: AppTypography.uiLabelC(context)),
          // Save button
          GestureDetector(
            onTap: _saveEntry,
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _saved
                    ? AppColors.sageGreen.withValues(alpha: 0.15)
                    : AppColors.softIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                border: Border.all(
                  color: _saved
                      ? AppColors.sageGreen.withValues(alpha: 0.3)
                      : AppColors.softIndigo.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
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
