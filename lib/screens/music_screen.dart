import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/doodle_refresh.dart';
import '../services/user_preferences_service.dart';

/// Music Screen — mood-aware Tamil playlist companion.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  bool _setupDone = false;
  final Set<String> _selectedLanguages = {};

  @override
  void initState() {
    super.initState();
    _loadSavedLanguages();
  }

  void _loadSavedLanguages() {
    final saved = UserPreferencesService().musicLanguages;
    if (saved.isNotEmpty) {
      _selectedLanguages.addAll(saved);
      _setupDone = true;
      if (mounted) setState(() {});
    }
  }

  static const List<String> _languages = [
    'English',
    'Tamil',
    'Hindi',
    'Telugu',
    'Malayalam',
    'Korean',
    'Japanese',
    'Instrumental',
    'Others',
  ];

  // Tamil playlists data
  static const List<Map<String, dynamic>> _playlists = [
    {
      'title': 'Feel Good Tamil',
      'mood': 'Happy',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': Color(0xFFE8A598),
      'description': 'Uplifting energy for bright moments.',
      'songs': [
        {'title': 'Rowdy Baby', 'artist': 'Maari 2'},
        {'title': 'Vaathi Coming', 'artist': 'Master'},
        {'title': 'Arabic Kuthu', 'artist': 'Beast'},
        {'title': 'Aalaporan Thamizhan', 'artist': 'Mersal'},
        {'title': 'Enjoy Enjaami', 'artist': 'Dhee'},
        {'title': 'Otha Sollaala', 'artist': 'Aadukalam'},
        {'title': 'Udhungada Sangu', 'artist': 'VIP'},
        {'title': 'Why This Kolaveri', 'artist': '3'},
        {'title': 'Sodakku', 'artist': 'TSK'},
        {'title': 'Vaanga Machan', 'artist': 'Vada Chennai'},
      ],
    },
    {
      'title': 'Soft Tamil Evenings',
      'mood': 'Calm',
      'icon': Icons.spa_outlined,
      'color': Color(0xFF9CB5A0),
      'description': 'Gentle melodies for quiet moments.',
      'songs': [
        {'title': 'Munbe Vaa', 'artist': 'Sillunu Oru Kadhal'},
        {'title': 'New York Nagaram', 'artist': 'Sillunu Oru Kadhal'},
        {'title': 'Nallai Allai', 'artist': 'Kaatru Veliyidai'},
        {'title': 'Vaseegara', 'artist': 'Minnale'},
        {'title': 'Anbil Avan', 'artist': 'Vinnaithaandi Varuvaayaa'},
        {'title': 'Pachai Nirame', 'artist': 'Alaipayuthey'},
        {'title': 'Enna Solla Pogirai', 'artist': 'Kandukondain'},
        {'title': 'Nenjukkul Peidhidum', 'artist': 'Vaaranam Aayiram'},
        {'title': 'Moongil Thottam', 'artist': 'Kadal'},
        {'title': 'Vellai Pookal', 'artist': 'Kannathil Muthamittal'},
      ],
    },
    {
      'title': 'Rise Again',
      'mood': 'Healing',
      'icon': Icons.healing_outlined,
      'color': Color(0xFFB8A9C9),
      'description': 'Songs for mending and moving forward.',
      'songs': [
        {'title': 'Thalli Pogathey', 'artist': 'AYM'},
        {'title': 'Po Nee Po', 'artist': '3'},
        {'title': 'Kadhal Kan Kattudhe', 'artist': 'Kaaki Sattai'},
        {'title': 'Aaromale', 'artist': 'Vinnaithaandi Varuvaayaa'},
        {'title': 'Ennodu Nee Irundhaal', 'artist': 'I'},
        {'title': 'Unakkenna Venum Sollu', 'artist': 'Yennai Arindhaal'},
        {'title': 'Kanave Kanave', 'artist': 'David'},
        {'title': 'Theera Ulaa', 'artist': 'O Kadhal Kanmani'},
        {'title': 'Usure Pogudhey', 'artist': 'Raavanan'},
        {'title': 'Nenjame', 'artist': 'Doctor'},
      ],
    },
    {
      'title': 'Tamil Instrumental Calm',
      'mood': 'Focus',
      'icon': Icons.center_focus_strong_outlined,
      'color': Color(0xFF9BA4CC),
      'description': 'Instrumental peace for deep focus.',
      'songs': [
        {'title': 'Bombay Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Alaipayuthey Theme', 'artist': 'A.R. Rahman'},
        {'title': 'VTV Instrumental', 'artist': 'A.R. Rahman'},
        {'title': 'Yanni Inspired Tamil Piano', 'artist': 'Various'},
        {'title': 'Roja Theme Instrumental', 'artist': 'A.R. Rahman'},
        {'title': 'Interstellar Tamil Piano', 'artist': 'Various'},
        {'title': 'Uyire Background Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Minnale Violin Theme', 'artist': 'Harris Jayaraj'},
        {'title': 'Anjali Theme', 'artist': 'Ilaiyaraaja'},
        {'title': 'Kaatru Veliyidai Instrumental', 'artist': 'A.R. Rahman'},
      ],
    },
  ];

  // Smart playlists
  static const List<Map<String, dynamic>> _smartPlaylists = [
    {
      'title': 'Daily Reset',
      'subtitle': 'Morning energy',
      'icon': Icons.wb_sunny_outlined,
      'color': Color(0xFFE8A598),
    },
    {
      'title': 'Sleep Mode',
      'subtitle': 'Slow ambient',
      'icon': Icons.nightlight_outlined,
      'color': Color(0xFF9BA4CC),
    },
    {
      'title': 'Focus Mode',
      'subtitle': 'Concentration',
      'icon': Icons.center_focus_strong_outlined,
      'color': Color(0xFF9CB5A0),
    },
    {
      'title': 'Deep Calm',
      'subtitle': 'Meditation',
      'icon': Icons.self_improvement_outlined,
      'color': Color(0xFFB8A9C9),
    },
  ];

  void _completeSetup() {
    if (_selectedLanguages.isEmpty) return;
    setState(() => _setupDone = true);

    // Persist language preferences
    final prefs = UserPreferencesService();
    prefs.musicLanguages = _selectedLanguages.toList();
    prefs.saveToRemote();
  }

  @override
  Widget build(BuildContext context) {
    if (!_setupDone) return _buildLanguageSetup(context);
    return _buildMusicHome(context);
  }

  // ─── Language Setup (First Time) ───
  Widget _buildLanguageSetup(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.bgGradient(context),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 1),

                Text(
                  'Music can shift\nthe mind.',
                  style: AppTypography.heroHeadingC(context),
                ).animate().fadeIn(duration: const Duration(milliseconds: 700)),

                const SizedBox(height: 12),
                Text(
                      'Choose the languages you enjoy listening to.',
                      style: AppTypography.subtitleC(context),
                    )
                    .animate(delay: const Duration(milliseconds: 200))
                    .fadeIn(duration: const Duration(milliseconds: 500)),

                const SizedBox(height: 32),

                Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _languages.map((lang) {
                        final isSelected = _selectedLanguages.contains(lang);
                        return GestureDetector(
                          onTap: () => setState(() {
                            isSelected
                                ? _selectedLanguages.remove(lang)
                                : _selectedLanguages.add(lang);
                          }),
                          child: AnimatedContainer(
                            duration: AppTheme.fadeInDuration,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.softIndigo.withValues(alpha: 0.15)
                                  : AppColors.card(context),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusButton,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.softIndigo.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.cardBorder(context),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.softIndigo.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              lang,
                              style:
                                  AppTypography.uiLabel(
                                    color: isSelected
                                        ? AppColors.softIndigo
                                        : AppColors.secondary(context),
                                  ).copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w400
                                        : FontWeight.w300,
                                  ),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                    .animate(delay: const Duration(milliseconds: 300))
                    .fadeIn(duration: const Duration(milliseconds: 500)),

                const Spacer(flex: 2),

                GestureDetector(
                  onTap: _completeSetup,
                  child: AnimatedContainer(
                    duration: AppTheme.fadeInDuration,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedLanguages.isNotEmpty
                          ? AppColors.softIndigo.withValues(alpha: 0.85)
                          : AppColors.dividerColor(context),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusButton,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Continue',
                        style: AppTypography.buttonText(
                          color: _selectedLanguages.isNotEmpty
                              ? Colors.white
                              : AppColors.tertiary(context),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Music Home ───
  Widget _buildMusicHome(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D3561), Color(0xFFD8C8E8)],
          ),
        ),
        child: SafeArea(
          child: DoodleRefresh(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  Text(
                    'Music',
                    style: AppTypography.heroHeading(color: Colors.white),
                  ).animate().fadeIn(
                    duration: const Duration(milliseconds: 600),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    'Playlists for your mood.',
                    style: AppTypography.subtitle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ).animate().fadeIn(
                    duration: const Duration(milliseconds: 600),
                  ),

                  const SizedBox(height: 28),

                  // ─── Smart Playlists Row ───
                  Text(
                        'Quick Listen',
                        style: AppTypography.sectionHeading(
                          color: Colors.white,
                        ),
                      )
                      .animate(delay: const Duration(milliseconds: 150))
                      .fadeIn(duration: const Duration(milliseconds: 400)),

                  const SizedBox(height: 14),

                  SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _smartPlaylists.length,
                          separatorBuilder: (_, i) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final sp = _smartPlaylists[i];
                            return Container(
                              width: 140,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusCard,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    sp['icon'] as IconData,
                                    color: sp['color'] as Color,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sp['title'] as String,
                                    style:
                                        AppTypography.uiLabel(
                                          color: Colors.white,
                                        ).copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                  Text(
                                    sp['subtitle'] as String,
                                    style: AppTypography.caption(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ).copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                      .animate(delay: const Duration(milliseconds: 200))
                      .fadeIn(duration: const Duration(milliseconds: 400)),

                  const SizedBox(height: 28),

                  // ─── Mood Playlists ───
                  Text(
                    'For Your Mood',
                    style: AppTypography.sectionHeading(color: Colors.white),
                  ),

                  const SizedBox(height: 14),

                  RepaintBoundary(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: _playlists.length * 110.0,
                      ),
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _playlists.length,
                        itemBuilder: (context, i) {
                          final pl = _playlists[i];
                          return _buildPlaylistCard(pl, i);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist, int index) {
    return GestureDetector(
      onTap: () => _openPlaylistDetail(playlist),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: (playlist['color'] as Color).withValues(alpha: 0.2),
              ),
              child: Icon(
                playlist['icon'] as IconData,
                color: playlist['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist['title'] as String,
                    style: AppTypography.buttonText(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    playlist['description'] as String,
                    style: AppTypography.caption(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(playlist['songs'] as List).length} tracks',
                    style: AppTypography.caption(
                      color: (playlist['color'] as Color).withValues(
                        alpha: 0.8,
                      ),
                    ).copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _openPlaylistDetail(Map<String, dynamic> playlist) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (ctx, a1, a2) => _PlaylistDetailScreen(playlist: playlist),
        transitionsBuilder: (ctx, animation, a2, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppTheme.gentleCurve,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

/// Playlist Detail Screen — list of songs with Spotify placeholder.
class _PlaylistDetailScreen extends StatelessWidget {
  final Map<String, dynamic> playlist;

  const _PlaylistDetailScreen({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final songs = playlist['songs'] as List;
    final color = playlist['color'] as Color;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D3561), Color(0xFF1B1F3B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist['title'] as String,
                            style: AppTypography.sectionHeading(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${songs.length} tracks',
                            style: AppTypography.caption(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Songs list
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: songs.length,
                  itemBuilder: (context, i) {
                    final song = songs[i] as Map<String, String>;
                    return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${i + 1}',
                                style: AppTypography.caption(
                                  color: color.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song['title']!,
                                      style: AppTypography.uiLabel(
                                        color: Colors.white,
                                      ).copyWith(fontWeight: FontWeight.w400),
                                    ),
                                    Text(
                                      song['artist']!,
                                      style: AppTypography.caption(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.play_circle_outline_rounded,
                                color: Colors.white.withValues(alpha: 0.2),
                                size: 22,
                              ),
                            ],
                          ),
                        )
                        .animate(delay: Duration(milliseconds: i * 50))
                        .fadeIn(duration: const Duration(milliseconds: 300));
                  },
                ),
              ),

              // Spotify button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    border: Border.all(
                      color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        color: const Color(0xFF1DB954),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Play on Spotify',
                        style: AppTypography.buttonText(
                          color: const Color(0xFF1DB954),
                        ),
                      ),
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
}
