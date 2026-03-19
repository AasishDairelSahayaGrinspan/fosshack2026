import 'package:flutter/material.dart';
import '../models/avatar_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/avatar_parts.dart';
import '../widgets/avatar_renderer.dart';
import '../widgets/gradient_background.dart';
import '../services/user_preferences_service.dart';

/// Snapchat-like avatar customization screen.
/// Categories: Face, Hair, Eyes, Mouth, Accessories, Clothing.
class AvatarCustomizationScreen extends StatefulWidget {
  /// If true, show as a full screen. If false, show as a compact mini-version (for onboarding).
  final bool fullScreen;
  final VoidCallback? onSaved;

  const AvatarCustomizationScreen({
    super.key,
    this.fullScreen = true,
    this.onSaved,
  });

  @override
  State<AvatarCustomizationScreen> createState() => _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends State<AvatarCustomizationScreen> {
  late AvatarConfig _config;
  int _selectedCategory = 0;

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Face', 'icon': Icons.face_outlined},
    {'label': 'Hair', 'icon': Icons.content_cut_rounded},
    {'label': 'Eyes', 'icon': Icons.visibility_outlined},
    {'label': 'Mouth', 'icon': Icons.sentiment_satisfied_outlined},
    {'label': 'Accessories', 'icon': Icons.star_outline_rounded},
    {'label': 'Clothing', 'icon': Icons.checkroom_outlined},
  ];

  @override
  void initState() {
    super.initState();
    final prefs = UserPreferencesService();
    if (prefs.avatarData != null && prefs.avatarData!.isNotEmpty) {
      _config = AvatarConfig.fromJsonString(prefs.avatarData!);
    } else {
      _config = AvatarConfig();
    }
    // In compact mode, ensure initial config is written to prefs
    if (!widget.fullScreen) {
      UserPreferencesService().avatarData = _config.toJsonString();
    }
  }

  Future<void> _save() async {
    final prefs = UserPreferencesService();
    prefs.avatarData = _config.toJsonString();
    await prefs.saveToRemote();
    widget.onSaved?.call();
    if (widget.fullScreen && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _randomize() {
    setState(() {
      _config = AvatarConfig.random();
    });
    _syncToPrefsIfCompact();
  }

  /// In compact (onboarding) mode, write config to prefs on every change
  /// so it's available when the parent screen finishes.
  void _syncToPrefsIfCompact() {
    if (!widget.fullScreen) {
      UserPreferencesService().avatarData = _config.toJsonString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fullScreen) {
      return _buildCompactVersion();
    }

    return Scaffold(
      body: GradientBackground(
        colors: AppColors.bgGradient(context),
        secondaryColors: AppColors.bgGradientAlt(context),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 8),

              // ─── Avatar Preview ───
              _buildPreview(200),

              const SizedBox(height: 16),

              // ─── Randomize Button ───
              _buildRandomizeButton(),

              const SizedBox(height: 20),

              // ─── Category Tabs ───
              _buildCategoryTabs(),

              const SizedBox(height: 16),

              // ─── Options for Selected Category ───
              Expanded(child: _buildCategoryOptions()),

              // ─── Save Button ───
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact version for embedding in onboarding.
  Widget _buildCompactVersion() {
    return Column(
      children: [
        _buildPreview(120),
        const SizedBox(height: 16),
        _buildRandomizeButton(),
        const SizedBox(height: 16),
        _buildCategoryTabs(),
        const SizedBox(height: 12),
        SizedBox(height: 180, child: _buildCategoryOptions()),
      ],
    );
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
          Text('Customize Avatar', style: AppTypography.uiLabelC(context)),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildPreview(double size) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card(context),
          border: Border.all(
            color: AppColors.softIndigo.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.softIndigo.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipOval(
          child: AvatarRenderer(config: _config, size: size),
        ),
      ),
    );
  }

  Widget _buildRandomizeButton() {
    return GestureDetector(
      onTap: _randomize,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.softIndigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.softIndigo.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shuffle_rounded, size: 16, color: AppColors.softIndigo),
            const SizedBox(width: 6),
            Text(
              'Randomize',
              style: AppTypography.caption(color: AppColors.softIndigo)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.softIndigo.withValues(alpha: 0.15)
                    : AppColors.card(context),
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
                    _categories[i]['icon'] as IconData,
                    size: 16,
                    color: isSelected
                        ? AppColors.softIndigo
                        : AppColors.tertiary(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _categories[i]['label'] as String,
                    style: AppTypography.caption(
                      color: isSelected
                          ? AppColors.softIndigo
                          : AppColors.secondary(context),
                    ).copyWith(
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryOptions() {
    switch (_selectedCategory) {
      case 0: // Face
        return _buildFaceOptions();
      case 1: // Hair
        return _buildHairOptions();
      case 2: // Eyes
        return _buildEyeOptions();
      case 3: // Mouth
        return _buildMouthOptions();
      case 4: // Accessories
        return _buildAccessoryOptions();
      case 5: // Clothing
        return _buildClothingOptions();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFaceOptions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Presentation'),
          _buildOptionRow(
            itemCount: AvatarParts.presentationLabels.length,
            selectedIndex: _config.presentation,
            labels: AvatarParts.presentationLabels,
            onSelect: (i) {
              setState(() {
                _config.presentation = i;
                final allowed = AvatarParts.hairStyleIndicesForPresentation(i);
                if (!allowed.contains(_config.hairStyle)) {
                  _config.hairStyle = allowed.first;
                }
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('Face Shape'),
          _buildOptionRow(
            itemCount: AvatarParts.faceShapeNames.length,
            selectedIndex: _config.faceShape,
            labels: AvatarParts.faceShapeNames,
            onSelect: (i) => setState(() => _config.faceShape = i),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('Skin Tone'),
          _buildColorRow(
            colors: AvatarParts.skinTones,
            selectedIndex: _config.skinTone,
            onSelect: (i) => setState(() => _config.skinTone = i),
          ),
        ],
      ),
    );
  }

  Widget _buildHairOptions() {
    final allowedStyles = AvatarParts.hairStyleIndicesForPresentation(
      _config.presentation,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Hair Style'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allowedStyles.map((styleIndex) {
              final isSelected = _config.hairStyle == styleIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _config.hairStyle = styleIndex);
                  _syncToPrefsIfCompact();
                },
                child: AnimatedContainer(
                  duration: AppTheme.fadeInDuration,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.softIndigo.withValues(alpha: 0.15)
                        : AppColors.card(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.softIndigo.withValues(alpha: 0.5)
                          : AppColors.dividerColor(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    AvatarParts.hairStyleNames[styleIndex],
                    style: AppTypography.caption(
                      color: isSelected
                          ? AppColors.softIndigo
                          : AppColors.secondary(context),
                    ).copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w300,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('Hair Color'),
          _buildColorRow(
            colors: AvatarParts.hairColors,
            selectedIndex: _config.hairColor,
            onSelect: (i) => setState(() => _config.hairColor = i),
          ),
        ],
      ),
    );
  }

  Widget _buildEyeOptions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Eye Style'),
          _buildOptionRow(
            itemCount: AvatarParts.eyeStyleNames.length,
            selectedIndex: _config.eyeStyle,
            labels: AvatarParts.eyeStyleNames,
            onSelect: (i) => setState(() => _config.eyeStyle = i),
          ),
        ],
      ),
    );
  }

  Widget _buildMouthOptions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Mouth Style'),
          _buildOptionRow(
            itemCount: AvatarParts.mouthStyleNames.length,
            selectedIndex: _config.mouthStyle,
            labels: AvatarParts.mouthStyleNames,
            onSelect: (i) => setState(() => _config.mouthStyle = i),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoryOptions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Accessory'),
          _buildOptionRow(
            itemCount: AvatarParts.accessoryNames.length,
            selectedIndex: _config.accessory,
            labels: AvatarParts.accessoryNames,
            onSelect: (i) => setState(() => _config.accessory = i),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingOptions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Clothing Style'),
          _buildOptionRow(
            itemCount: AvatarParts.clothingStyleNames.length,
            selectedIndex: _config.clothing,
            labels: AvatarParts.clothingStyleNames,
            onSelect: (i) => setState(() => _config.clothing = i),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('Clothing Color'),
          _buildColorRow(
            colors: AvatarParts.clothingColors,
            selectedIndex: _config.clothingColor,
            onSelect: (i) => setState(() => _config.clothingColor = i),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: AppTypography.uiLabel(color: AppColors.secondary(context)),
      ),
    );
  }

  Widget _buildOptionRow({
    required int itemCount,
    required int selectedIndex,
    required List<String> labels,
    required void Function(int) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(itemCount, (i) {
        final isSelected = selectedIndex == i;
        return GestureDetector(
          onTap: () {
            onSelect(i);
            _syncToPrefsIfCompact();
          },
          child: AnimatedContainer(
            duration: AppTheme.fadeInDuration,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.softIndigo.withValues(alpha: 0.15)
                  : AppColors.card(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              border: Border.all(
                color: isSelected
                    ? AppColors.softIndigo.withValues(alpha: 0.5)
                    : AppColors.dividerColor(context),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              i < labels.length ? labels[i] : '$i',
              style: AppTypography.caption(
                color: isSelected
                    ? AppColors.softIndigo
                    : AppColors.secondary(context),
              ).copyWith(
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                fontSize: 11,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildColorRow({
    required List<Color> colors,
    required int selectedIndex,
    required void Function(int) onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(colors.length, (i) {
        final isSelected = selectedIndex == i;
        return GestureDetector(
          onTap: () {
            onSelect(i);
            _syncToPrefsIfCompact();
          },
          child: AnimatedContainer(
            duration: AppTheme.fadeInDuration,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors[i],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.softIndigo
                    : AppColors.dividerColor(context),
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.softIndigo.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _save,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.softIndigo.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            boxShadow: [
              BoxShadow(
                color: AppColors.softIndigo.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Save Avatar',
              style: AppTypography.buttonText(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
