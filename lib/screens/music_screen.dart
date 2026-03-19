import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_navigation_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_preferences_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
/// Music Screen - mood-aware playlist companion.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  bool _setupDone = false;
  final Set<String> _selectedLanguages = <String>{};
  String? _recommendation;

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

  static const List<Map<String, dynamic>> _playlists = [
    {
      'title': 'Feel Good Tamil',
      'mood': 'Happy',
      'language': 'Tamil',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'Uplifting energy for bright moments.',
      'songs': [
        {'title': 'Rowdy Baby', 'artist': 'Maari 2'},
        {'title': 'Vaathi Coming', 'artist': 'Master'},
        {'title': 'Arabic Kuthu', 'artist': 'Beast'},
      ],
    },
    {
      'title': 'Soft Tamil Evenings',
      'mood': 'Calm',
      'language': 'Tamil',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Gentle melodies for quiet moments.',
      'songs': [
        {'title': 'Munbe Vaa', 'artist': 'Sillunu Oru Kadhal'},
        {'title': 'Vaseegara', 'artist': 'Minnale'},
        {'title': 'Nenjukkul Peidhidum', 'artist': 'Vaaranam Aayiram'},
      ],
    },
    {
      'title': 'Rise Again',
      'mood': 'Healing',
      'language': 'Tamil',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Songs for mending and moving forward.',
      'songs': [
        {'title': 'Thalli Pogathey', 'artist': 'AYM'},
        {'title': 'Po Nee Po', 'artist': '3'},
        {'title': 'Kanave Kanave', 'artist': 'David'},
      ],
    },
    {
      'title': 'Focus Instrumentals',
      'mood': 'Focus',
      'language': 'Instrumental',
      'icon': Icons.center_focus_strong_outlined,
      'color': AppColors.softIndigo,
      'description': 'Instrumental peace for deep focus.',
      'songs': [
        {'title': 'Bombay Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Roja Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Alaipayuthey Theme', 'artist': 'A.R. Rahman'},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredPlaylists {
    if (_selectedLanguages.isEmpty) return _playlists;
    final filtered = _playlists
        .where((pl) => _selectedLanguages.contains(pl['language']))
        .toList();
    return filtered.isEmpty ? _playlists : filtered;
  }

  @override
  void initState() {
    super.initState();
    final prefs = UserPreferencesService();
    _selectedLanguages.addAll(prefs.musicLanguages);
    _setupDone = prefs.hasMusicSetup;

    _recommendation = AppNavigationService().musicRecommendation.value;
    AppNavigationService().musicRecommendation.addListener(_onRecommendation);
  }

  @override
  void dispose() {
    AppNavigationService().musicRecommendation.removeListener(_onRecommendation);
    super.dispose();
  }

  void _onRecommendation() {
    if (!mounted) return;
    setState(() {
      _recommendation = AppNavigationService().musicRecommendation.value;
    });
  }

  Future<void> _completeSetup() async {
    if (_selectedLanguages.isEmpty) return;
    final prefs = UserPreferencesService();
    prefs.musicLanguages = _selectedLanguages.toList();
    await prefs.saveToRemote();
    if (!mounted) return;
    setState(() => _setupDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_setupDone) return _buildLanguageSetup(context);
    return _buildMusicHome(context);
  }

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
                ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
                const SizedBox(height: 12),
                Text(
                  'Choose the languages you enjoy listening to.',
                  style: AppTypography.subtitleC(context),
                ),
                const SizedBox(height: 28),
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
                                ? AppColors.softIndigo.withValues(alpha: 0.5)
                                : AppColors.cardBorder(context),
                          ),
                        ),
                        child: Text(
                          lang,
                          style: AppTypography.uiLabel(
                            color: isSelected
                                ? AppColors.softIndigo
                                : AppColors.secondary(context),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
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

  Widget _buildMusicHome(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.ink304057, AppColors.coralDa5e5a],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                  Text(
                    'Music',
                    style: AppTypography.heroHeading(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Playlists for your mood.',
                    style: AppTypography.subtitle(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_recommendation != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.amberFdb903.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.amberFdb903.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: AppColors.amberFdb903,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _recommendation!,
                              style: AppTypography.caption(color: Colors.white),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              AppNavigationService().clearMusicRecommendation();
                              setState(() => _recommendation = null);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'For Your Mood',
                    style: AppTypography.sectionHeading(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ..._filteredPlaylists.map((pl) => _buildPlaylistCard(pl)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
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
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white.withValues(alpha: 0.45),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _openPlaylistDetail(Map<String, dynamic> playlist) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }
}

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
            colors: [AppColors.ink304057, AppColors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                            style: AppTypography.sectionHeading(color: Colors.white),
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
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: songs.length,
                  itemBuilder: (context, i) {
                    final song = songs[i] as Map<String, String>;
                    return GestureDetector(
                      onTap: () async {
                        final user = AuthService().currentUser;
                        if (user != null) {
                          await DatabaseService().saveListenedSong(
                            userId: user.$id,
                            title: song['title']!,
                            artist: song['artist']!,
                            playlist: playlist['title'] as String,
                            mood: playlist['mood'] as String?,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${i + 1}',
                              style: AppTypography.caption(
                                color: color.withValues(alpha: 0.75),
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
                                      color: Colors.white.withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.play_circle_outline_rounded,
                              color: Colors.white.withValues(alpha: 0.25),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () {
                    final title = Uri.encodeComponent(playlist['title'] as String);
                    launchUrl(
                      Uri.parse('https://open.spotify.com/search/$title'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
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
                        const Icon(
                          Icons.music_note_rounded,
                          color: Color(0xFF1DB954),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
