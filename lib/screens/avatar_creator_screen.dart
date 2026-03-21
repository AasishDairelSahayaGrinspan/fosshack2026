import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/avatar_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/gradient_background.dart';
import '../services/user_preferences_service.dart';

class AvatarCreatorScreen extends StatefulWidget {
  final AvatarConfig? initialConfig;
  const AvatarCreatorScreen({super.key, this.initialConfig});

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  late AvatarConfig _config;
  int _selectedTab = 0;

  static const List<String> _tabs = [
    'Body',
    'Skin',
    'Hair',
    'Shirt',
    'Pants',
    'Shoes',
    'Extras',
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig ?? const AvatarConfig();
  }

  void _save() {
    final prefs = UserPreferencesService();
    prefs.avatarConfigMap = _config.toMap();
    prefs.saveToRemote();
    Navigator.of(context).pop(_config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: AppColors.bgGradient(context),
        secondaryColors: AppColors.bgGradientAlt(context),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.primary(context),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Create Avatar',
                      style: AppTypography.sectionHeadingC(context),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softIndigo,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusButton,
                          ),
                        ),
                        child: Text(
                          'Done',
                          style: AppTypography.buttonText(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Live preview
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card(context),
                  border: Border.all(
                    color: AppColors.softIndigo.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.softIndigo.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: CustomAvatar(config: _config, size: 140),
              ).animate().fadeIn(duration: const Duration(milliseconds: 500)),

              // Category tabs
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = _selectedTab == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: AnimatedContainer(
                        duration: AppTheme.fadeInDuration,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.softIndigo.withValues(alpha: 0.15)
                              : AppColors.card(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.softIndigo.withValues(alpha: 0.4)
                                : AppColors.dividerColor(context),
                          ),
                        ),
                        child: Text(
                          _tabs[i],
                          style:
                              AppTypography.caption(
                                color: selected
                                    ? AppColors.softIndigo
                                    : AppColors.tertiary(context),
                              ).copyWith(
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Options area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(
                      color: AppColors.cardBorder(context),
                      width: 0.8,
                    ),
                  ),
                  child: _buildOptions(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions() {
    switch (_selectedTab) {
      case 0:
        return _buildChipSelector(
          'Body Type',
          ['Slim', 'Average', 'Broad'],
          _config.bodyType,
          (i) => setState(() => _config = _config.copyWith(bodyType: i)),
        );
      case 1:
        return _buildColorGrid(
          'Skin Color',
          AvatarConfig.skinColors,
          _config.skinColor,
          (c) => setState(() => _config = _config.copyWith(skinColor: c)),
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChipSelector(
              'Hair Style',
              AvatarConfig.hairStyleNames,
              _config.hairStyle,
              (i) => setState(() => _config = _config.copyWith(hairStyle: i)),
            ),
            const SizedBox(height: 16),
            _buildColorGrid(
              'Hair Color',
              AvatarConfig.hairColors,
              _config.hairColor,
              (c) => setState(() => _config = _config.copyWith(hairColor: c)),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChipSelector(
              'Shirt Style',
              AvatarConfig.shirtStyleNames,
              _config.shirtStyle,
              (i) => setState(() => _config = _config.copyWith(shirtStyle: i)),
            ),
            const SizedBox(height: 16),
            _buildColorGrid(
              'Shirt Color',
              AvatarConfig.shirtColors,
              _config.shirtColor,
              (c) => setState(() => _config = _config.copyWith(shirtColor: c)),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChipSelector(
              'Pants Style',
              AvatarConfig.pantsStyleNames,
              _config.pantsStyle,
              (i) => setState(() => _config = _config.copyWith(pantsStyle: i)),
            ),
            const SizedBox(height: 16),
            _buildColorGrid(
              'Pants Color',
              AvatarConfig.pantsColors,
              _config.pantsColor,
              (c) => setState(() => _config = _config.copyWith(pantsColor: c)),
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChipSelector(
              'Shoe Style',
              AvatarConfig.shoeStyleNames,
              _config.shoeStyle,
              (i) => setState(() => _config = _config.copyWith(shoeStyle: i)),
            ),
            const SizedBox(height: 16),
            _buildColorGrid(
              'Shoe Color',
              AvatarConfig.shoeColors,
              _config.shoeColor,
              (c) => setState(() => _config = _config.copyWith(shoeColor: c)),
            ),
          ],
        );
      case 6:
        return _buildAccessories();
      default:
        return const SizedBox();
    }
  }

  Widget _buildChipSelector(
    String label,
    List<String> options,
    int selected,
    ValueChanged<int> onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionC(
            context,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(options.length, (i) {
            final isSelected = selected == i;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.softIndigo.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.softIndigo.withValues(alpha: 0.4)
                        : AppColors.dividerColor(context),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  options[i],
                  style:
                      AppTypography.caption(
                        color: isSelected
                            ? AppColors.softIndigo
                            : AppColors.primary(context),
                      ).copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildColorGrid(
    String label,
    List<Color> colors,
    Color selected,
    ValueChanged<Color> onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionC(
            context,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((c) {
            final isSelected = c.toARGB32() == selected.toARGB32();
            return GestureDetector(
              onTap: () => onSelect(c),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.softIndigo
                        : AppColors.dividerColor(context),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: c.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAccessories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accessories',
          style: AppTypography.captionC(
            context,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AvatarConfig.accessoryNames.map((name) {
            final isSelected = _config.accessories.contains(name);
            return GestureDetector(
              onTap: () {
                final list = List<String>.from(_config.accessories);
                if (isSelected) {
                  list.remove(name);
                } else {
                  list.add(name);
                }
                setState(() => _config = _config.copyWith(accessories: list));
              },
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.softIndigo.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.softIndigo.withValues(alpha: 0.4)
                        : AppColors.dividerColor(context),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _accessoryIcon(name),
                      size: 16,
                      color: isSelected
                          ? AppColors.softIndigo
                          : AppColors.tertiary(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name[0].toUpperCase() + name.substring(1),
                      style:
                          AppTypography.caption(
                            color: isSelected
                                ? AppColors.softIndigo
                                : AppColors.primary(context),
                          ).copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _accessoryIcon(String name) {
    switch (name) {
      case 'sunglasses':
        return Icons.visibility_outlined;
      case 'chain':
        return Icons.link_rounded;
      case 'hat':
        return Icons.catching_pokemon;
      case 'earring':
        return Icons.circle_outlined;
      default:
        return Icons.star_outline_rounded;
    }
  }
}
