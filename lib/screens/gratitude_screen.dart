import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class GratitudeScreen extends StatefulWidget {
  const GratitudeScreen({super.key});

  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  final TextEditingController _textController = TextEditingController();
  String _selectedCategory = 'Grateful for';
  bool _saving = false;
  List<Map<String, dynamic>> _entries = [];

  static const List<String> _categories = [
    'Grateful for',
    'Small win',
    'Milestone',
    'Kind act',
    'Self-care',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Grateful for': Icons.favorite_outline_rounded,
    'Small win': Icons.emoji_events_outlined,
    'Milestone': Icons.flag_outlined,
    'Kind act': Icons.volunteer_activism_outlined,
    'Self-care': Icons.spa_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final entries =
          await DatabaseService().getGratitudeEntries(user.$id, days: 7);
      if (mounted) setState(() => _entries = entries);
    } catch (_) {}
  }

  Future<void> _saveEntry() async {
    if (_textController.text.trim().isEmpty) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await DatabaseService().saveGratitudeEntry(
        userId: user.$id,
        content: _textController.text.trim(),
        category: _selectedCategory,
      );
      _textController.clear();
      await _loadEntries();
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  // Group entries by day
  Map<String, List<Map<String, dynamic>>> _groupByDay() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final entry in _entries) {
      final ts = DateTime.tryParse(entry['timestamp'] as String? ?? '');
      if (ts == null) continue;
      final key =
          '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(entry);
    }
    return grouped;
  }

  String _dayLabel(String key) {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (key == todayKey) return 'Today';
    final dt = DateTime.tryParse(key);
    if (dt == null) return key;
    final diff = now.difference(dt).inDays;
    if (diff == 1) return 'Yesterday';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  int get _weekCount => _entries.length;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay();
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.bgGradient(context),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Gratitude & Wins',
                        style: AppTypography.heroHeadingC(context),
                      ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            curve: AppTheme.gentleCurve,
                          ),
                      const SizedBox(height: 20),

                      // Add a win section
                      _buildAddWinSection(context),
                      const SizedBox(height: 24),

                      // Weekly summary
                      if (_weekCount > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.amberFdb903.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusCard),
                            border: Border.all(
                              color:
                                  AppColors.amberFdb903.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('🌟', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You logged $_weekCount win${_weekCount == 1 ? '' : 's'} this week!',
                                  style: AppTypography.bodyC(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: const Duration(milliseconds: 400)),

                      const SizedBox(height: 24),

                      // Entries grouped by day
                      ...sortedKeys.map((key) {
                        final dayEntries = grouped[key]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dayLabel(key),
                              style: AppTypography.uiLabelC(context).copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...dayEntries.asMap().entries.map((e) {
                              return _buildEntryCard(context, e.value, e.key);
                            }),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),

                      if (_entries.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  color: AppColors.tertiary(context)
                                      .withValues(alpha: 0.4),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No wins yet this week.',
                                  style: AppTypography.subtitleC(context),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Start by adding something you\'re grateful for.',
                                  style: AppTypography.captionC(context),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
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
          const SizedBox(width: 14),
          Text('Gratitude & Wins', style: AppTypography.sectionHeadingC(context)),
        ],
      ),
    );
  }

  Widget _buildAddWinSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: AppColors.dividerColor(context).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a win',
            style: AppTypography.uiLabelC(context)
                .copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          // Category chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: AppTheme.fadeInDuration,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.softIndigo.withValues(alpha: 0.12)
                        : AppColors.card(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.softIndigo.withValues(alpha: 0.4)
                          : AppColors.dividerColor(context),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _categoryIcons[cat] ?? Icons.star_outline,
                        size: 14,
                        color: isSelected
                            ? AppColors.softIndigo
                            : AppColors.secondary(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat,
                        style: AppTypography.caption(
                          color: isSelected
                              ? AppColors.softIndigo
                              : AppColors.secondary(context),
                        ).copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Text field
          TextField(
            controller: _textController,
            maxLines: 3,
            minLines: 2,
            style: AppTypography.journalBodyC(context),
            decoration: InputDecoration(
              hintText: 'What\'s your win today?',
              hintStyle: AppTypography.journalBody(
                color: AppColors.tertiary(context).withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),

          // Save button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _saving ? null : _saveEntry,
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _saving
                      ? AppColors.sageGreen.withValues(alpha: 0.15)
                      : AppColors.softIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  border: Border.all(
                    color: _saving
                        ? AppColors.sageGreen.withValues(alpha: 0.3)
                        : AppColors.softIndigo.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _saving ? Icons.check_rounded : Icons.add_rounded,
                      color: _saving
                          ? AppColors.sageGreen
                          : AppColors.softIndigo,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _saving ? 'Saved!' : 'Save',
                      style: AppTypography.caption(
                        color: _saving
                            ? AppColors.sageGreen
                            : AppColors.softIndigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: const Duration(milliseconds: 100)).fadeIn(
          duration: const Duration(milliseconds: 500),
          curve: AppTheme.gentleCurve,
        );
  }

  Widget _buildEntryCard(
      BuildContext context, Map<String, dynamic> entry, int index) {
    final content = entry['content'] as String? ?? '';
    final category = entry['category'] as String? ?? 'Grateful for';
    final timestamp = entry['timestamp'] as String? ?? '';
    final dt = DateTime.tryParse(timestamp);
    final timeStr = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: AppColors.dividerColor(context).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.softIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _categoryIcons[category] ?? Icons.star_outline,
                color: AppColors.softIndigo,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.softIndigo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: AppTypography.caption(
                            color: AppColors.softIndigo,
                          ).copyWith(fontSize: 10),
                        ),
                      ),
                      const Spacer(),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: AppTypography.caption(
                            color: AppColors.tertiary(context),
                          ).copyWith(fontSize: 10),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: AppTypography.bodyC(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(
          duration: const Duration(milliseconds: 300),
          curve: AppTheme.gentleCurve,
        )
        .slideY(begin: 0.03, end: 0, duration: const Duration(milliseconds: 300));
  }
}
