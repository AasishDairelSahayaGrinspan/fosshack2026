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
import '../widgets/doodle_refresh.dart';

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
      'language': 'Tamil',
      'mood': 'Happy',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'Uplifting energy for bright moments.',
      'spotifyUrl': 'https://open.spotify.com/search/feel%20good%20tamil',
      'youtubeUrl': 'https://www.youtube.com/results?search_query=feel+good+tamil+songs',
      'songs': [
        {'title': 'Rowdy Baby', 'artist': 'Maari 2', 'spotifyUrl': 'https://open.spotify.com/search/Rowdy%20Baby%20Maari%202', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Rowdy+Baby+Maari+2'},
        {'title': 'Vaathi Coming', 'artist': 'Master', 'spotifyUrl': 'https://open.spotify.com/search/Vaathi%20Coming%20Master', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Vaathi+Coming+Master'},
        {'title': 'Arabic Kuthu', 'artist': 'Beast', 'spotifyUrl': 'https://open.spotify.com/search/Arabic%20Kuthu%20Beast', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Arabic+Kuthu+Beast'},
      ],
    },
    {
      'title': 'Soft Tamil Evenings',
      'language': 'Tamil',
      'mood': 'Calm',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Gentle melodies for quiet moments.',
      'spotifyUrl': 'https://open.spotify.com/search/soft%20tamil%20melodies',
      'youtubeUrl': 'https://www.youtube.com/results?search_query=soft+tamil+melodies',
      'songs': [
        {'title': 'Munbe Vaa', 'artist': 'Sillunu Oru Kadhal', 'spotifyUrl': 'https://open.spotify.com/search/Munbe%20Vaa%20Sillunu%20Oru%20Kadhal', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Munbe+Vaa+Sillunu+Oru+Kadhal'},
        {'title': 'Vaseegara', 'artist': 'Minnale', 'spotifyUrl': 'https://open.spotify.com/search/Vaseegara%20Minnale', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Vaseegara+Minnale'},
        {'title': 'Nenjukkul Peidhidum', 'artist': 'Vaaranam Aayiram', 'spotifyUrl': 'https://open.spotify.com/search/Nenjukkul%20Peidhidum%20Vaaranam%20Aayiram', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Nenjukkul+Peidhidum+Vaaranam+Aayiram'},
      ],
    },
    {
      'title': 'Rise Again',
      'language': 'Tamil',
      'mood': 'Healing',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Songs for mending and moving forward.',
      'spotifyUrl': 'https://open.spotify.com/search/tamil%20healing%20songs',
      'youtubeUrl': 'https://www.youtube.com/results?search_query=tamil+healing+songs',
      'songs': [
        {'title': 'Thalli Pogathey', 'artist': 'AYM', 'spotifyUrl': 'https://open.spotify.com/search/Thalli%20Pogathey%20AYM', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Thalli+Pogathey+AYM'},
        {'title': 'Po Nee Po', 'artist': '3', 'spotifyUrl': 'https://open.spotify.com/search/Po%20Nee%20Po%203%20movie', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Po+Nee+Po+3+movie'},
        {'title': 'Kanave Kanave', 'artist': 'David', 'spotifyUrl': 'https://open.spotify.com/search/Kanave%20Kanave%20David', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Kanave+Kanave+David'},
      ],
    },
    {
      'title': 'Focus Instrumentals',
      'language': 'Instrumental',
      'mood': 'Focus',
      'icon': Icons.center_focus_strong_outlined,
      'color': AppColors.softIndigo,
      'description': 'Instrumental peace for deep focus.',
      'spotifyUrl': 'https://open.spotify.com/search/AR%20Rahman%20instrumental',
      'youtubeUrl': 'https://www.youtube.com/results?search_query=AR+Rahman+instrumental+themes',
      'songs': [
        {'title': 'Bombay Theme', 'artist': 'A.R. Rahman', 'spotifyUrl': 'https://open.spotify.com/search/Bombay%20Theme%20AR%20Rahman', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Bombay+Theme+AR+Rahman'},
        {'title': 'Roja Theme', 'artist': 'A.R. Rahman', 'spotifyUrl': 'https://open.spotify.com/search/Roja%20Theme%20AR%20Rahman', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Roja+Theme+AR+Rahman'},
        {'title': 'Alaipayuthey Theme', 'artist': 'A.R. Rahman', 'spotifyUrl': 'https://open.spotify.com/search/Alaipayuthey%20Theme%20AR%20Rahman', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Alaipayuthey+Theme+AR+Rahman'},
      ],
    },
    {
      'title': 'English Pop Hits',
      'language': 'English',
      'mood': 'Happy',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'Upbeat tracks to keep you smiling.',
      'spotifyUrl': 'https://open.spotify.com/search/feel%20good%20pop',
      'youtubeUrl': 'https://www.youtube.com/results?search_query=feel+good+pop',
      'songs': [
        {'title': 'Levitating', 'artist': 'Dua Lipa', 'spotifyUrl': 'https://open.spotify.com/search/Levitating', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Levitating+Dua+Lipa'},
        {'title': 'Blinding Lights', 'artist': 'The Weeknd', 'spotifyUrl': 'https://open.spotify.com/search/Blinding%20Lights', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Blinding+Lights+The+Weeknd'},
        {'title': 'Watermelon Sugar', 'artist': 'Harry Styles', 'spotifyUrl': 'https://open.spotify.com/search/Watermelon%20Sugar', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Watermelon+Sugar+Harry+Styles'},
      ],
    },
    {
      'title': 'Calm English Acoustics',
      'language': 'English',
      'mood': 'Calm',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Soothing acoustic melodies.',
      'spotifyUrl': 'https://open.spotify.com/search/calm%20acoustic',
      'youtubeUrl': 'https://www.youtube.com/results?search_query=calm+acoustic+songs',
      'songs': [
        {'title': 'Perfect', 'artist': 'Ed Sheeran', 'spotifyUrl': 'https://open.spotify.com/search/Perfect%20Ed%20Sheeran', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Perfect+Ed+Sheeran'},
        {'title': 'All of Me', 'artist': 'John Legend', 'spotifyUrl': 'https://open.spotify.com/search/All%20of%20Me', 'youtubeUrl': 'https://www.youtube.com/results?search_query=All+of+Me+John+Legend'},
        {'title': 'Stay With Me', 'artist': 'Sam Smith', 'spotifyUrl': 'https://open.spotify.com/search/Stay%20With%20Me', 'youtubeUrl': 'https://www.youtube.com/results?search_query=Stay+With+Me+Sam+Smith'},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredPlaylists {
    if (_selectedLanguages.isEmpty) return _playlists;
    final filtered = _playlists.where((p) => _selectedLanguages.contains(p['language'])).toList();
    if (filtered.isEmpty) return _playlists;
    return filtered;
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Playlists for your mood.',
                    style: AppTypography.subtitle(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                          IconButton(
                            onPressed: () =>
                                AppNavigationService().clearMusicRecommendation(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    'For Your Mood',
                    style: AppTypography.sectionHeading(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  ..._filteredPlaylists.map((pl) => _buildPlaylistCard(pl)),
                  const SizedBox(height: 32),
                ],
              ),
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = playlist['songs'] as List;
    final color = playlist['color'] as Color;
    final playlistSpotifyUrl = playlist['spotifyUrl'] as String?;
    final playlistYoutubeUrl = playlist['youtubeUrl'] as String?;

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
                        // Log the listen
                        final user = AuthService().currentUser;
                        if (user != null) {
                          DatabaseService().saveListenedSong(
                            userId: user.$id,
                            title: song['title']!,
                            artist: song['artist']!,
                            playlist: playlist['title'] as String,
                            mood: playlist['mood'] as String?,
                          );
                        }
                        // Open in Spotify (preferred) or YouTube
                        final spotifyUrl = song['spotifyUrl'];
                        final youtubeUrl = song['youtubeUrl'];
                        if (spotifyUrl != null) {
                          await _openUrl(spotifyUrl);
                        } else if (youtubeUrl != null) {
                          await _openUrl(youtubeUrl);
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
                              color: Colors.white.withValues(alpha: 0.45),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // ─── Spotify & YouTube Buttons ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    if (playlistSpotifyUrl != null)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openUrl(playlistSpotifyUrl),
                          child: Container(
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
                                  'Spotify',
                                  style: AppTypography.buttonText(
                                    color: const Color(0xFF1DB954),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (playlistSpotifyUrl != null && playlistYoutubeUrl != null)
                      const SizedBox(width: 12),
                    if (playlistYoutubeUrl != null)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openUrl(playlistYoutubeUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF0000).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                              border: Border.all(
                                color: const Color(0xFFFF0000).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFFFF0000),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'YouTube',
                                  style: AppTypography.buttonText(
                                    color: const Color(0xFFFF0000),
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
