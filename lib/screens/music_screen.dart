import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_navigation_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/music_service.dart';
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
  String? _recommendation;
  final AudioPlayer _player = AudioPlayer();

  List<MusicTrackData> _sessionTracks = <MusicTrackData>[];
  int _activeTrackIndex = 0;
  bool _isPlaying = false;
  bool _loadingSession = true;
  String? _sessionError;

  static const List<String> _languages = [
    'English',
    'Tamil',
    'Hindi',
    'Telugu',
    'Malayalam',
    'Korean',
    'Japanese',
    'Instrumental',
  ];

  List<String> get _selectedLanguages =>
      UserPreferencesService().musicLanguages;

  static const List<Map<String, dynamic>> _playlists = [
    // ── Tamil ──
    {
      'title': 'Feel Good Tamil',
      'mood': 'Happy',
      'language': 'Tamil',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'Uplifting energy for bright moments.',
      'songs': [
        {'title': 'Rowdy Baby', 'artist': 'Dhanush & Dhee'},
        {'title': 'Vaathi Coming', 'artist': 'Anirudh Ravichander'},
        {'title': 'Arabic Kuthu', 'artist': 'Anirudh Ravichander'},
        {'title': 'Aalaporan Thamizhan', 'artist': 'A.R. Rahman'},
        {'title': 'Enjoy Enjaami', 'artist': 'Dhee ft. Arivu'},
        {'title': 'Otha Sollaala', 'artist': 'Anirudh Ravichander'},
        {'title': 'Udhungada Sangu', 'artist': 'Anirudh Ravichander'},
        {'title': 'Why This Kolaveri', 'artist': 'Dhanush'},
        {'title': 'Sodakku', 'artist': 'Anirudh Ravichander'},
        {'title': 'Vaanga Machan', 'artist': 'Anirudh Ravichander'},
        {'title': 'Kutti Story', 'artist': 'Anirudh Ravichander'},
        {'title': 'Jolly O Gymkhana', 'artist': 'Anirudh Ravichander'},
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
        {'title': 'Munbe Vaa', 'artist': 'A.R. Rahman'},
        {'title': 'New York Nagaram', 'artist': 'A.R. Rahman'},
        {'title': 'Nallai Allai', 'artist': 'A.R. Rahman'},
        {'title': 'Vaseegara', 'artist': 'Bombay Jayashri'},
        {'title': 'Anbil Avan', 'artist': 'A.R. Rahman'},
        {'title': 'Pachai Nirame', 'artist': 'A.R. Rahman'},
        {'title': 'Enna Solla Pogirai', 'artist': 'A.R. Rahman'},
        {'title': 'Nenjukkul Peidhidum', 'artist': 'Harris Jayaraj'},
        {'title': 'Moongil Thottam', 'artist': 'A.R. Rahman'},
        {'title': 'Vellai Pookal', 'artist': 'A.R. Rahman'},
        {'title': 'Kannazhaga', 'artist': 'Dhanush & Shruti Haasan'},
        {'title': 'Oru Devadhai', 'artist': 'Vijay Antony'},
      ],
    },
    {
      'title': 'Rise Again Tamil',
      'mood': 'Healing',
      'language': 'Tamil',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Songs for mending and moving forward.',
      'songs': [
        {'title': 'Thalli Pogathey', 'artist': 'Sid Sriram'},
        {'title': 'Po Nee Po', 'artist': 'Anirudh Ravichander'},
        {'title': 'Kadhal Kan Kattudhe', 'artist': 'Anirudh Ravichander'},
        {'title': 'Aaromale', 'artist': 'A.R. Rahman'},
        {'title': 'Ennodu Nee Irundhaal', 'artist': 'A.R. Rahman'},
        {'title': 'Unakkenna Venum Sollu', 'artist': 'Anirudh Ravichander'},
        {'title': 'Kanave Kanave', 'artist': 'Anirudh Ravichander'},
        {'title': 'Theera Ulaa', 'artist': 'A.R. Rahman'},
        {'title': 'Usure Pogudhey', 'artist': 'A.R. Rahman'},
        {'title': 'Nenjame', 'artist': 'Hariharan'},
      ],
    },
    {
      'title': 'Tamil Instrumental',
      'mood': 'Focus',
      'language': 'Tamil',
      'icon': Icons.center_focus_strong_outlined,
      'color': AppColors.softIndigo,
      'description': 'Instrumental peace for deep focus.',
      'songs': [
        {'title': 'Bombay Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Alaipayuthey Theme', 'artist': 'A.R. Rahman'},
        {'title': 'VTV Instrumental', 'artist': 'A.R. Rahman'},
        {'title': 'Roja Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Minnale Violin Theme', 'artist': 'Harris Jayaraj'},
        {'title': 'Anjali Theme', 'artist': 'Ilaiyaraaja'},
        {'title': 'Kaatru Veliyidai Instrumental', 'artist': 'A.R. Rahman'},
        {'title': 'Uyire Background Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Iruvar Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Rhythm Theme', 'artist': 'A.R. Rahman'},
      ],
    },
    // ── English ──
    {
      'title': 'Feel Good English',
      'mood': 'Happy',
      'language': 'English',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'Instant mood lift, every time.',
      'songs': [
        {'title': 'Happy', 'artist': 'Pharrell Williams'},
        {'title': 'Good as Hell', 'artist': 'Lizzo'},
        {'title': 'On Top of the World', 'artist': 'Imagine Dragons'},
        {'title': 'Best Day of My Life', 'artist': 'American Authors'},
        {'title': 'Walking on Sunshine', 'artist': 'Katrina & The Waves'},
        {'title': 'Uptown Funk', 'artist': 'Bruno Mars'},
        {'title': "Can't Stop the Feeling", 'artist': 'Justin Timberlake'},
        {'title': 'Shake It Off', 'artist': 'Taylor Swift'},
        {'title': "Don't Stop Me Now", 'artist': 'Queen'},
        {'title': 'Here Comes the Sun', 'artist': 'The Beatles'},
      ],
    },
    {
      'title': 'Calm English',
      'mood': 'Calm',
      'language': 'English',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Breathe easy with soft melodies.',
      'songs': [
        {'title': 'Weightless', 'artist': 'Marconi Union'},
        {'title': 'Sunset Lover', 'artist': 'Petit Biscuit'},
        {'title': 'Bloom', 'artist': 'ODESZA'},
        {'title': 'Experience', 'artist': 'Ludovico Einaudi'},
        {'title': 'Skinny Love', 'artist': 'Bon Iver'},
        {'title': 'Holocene', 'artist': 'Bon Iver'},
        {'title': 'The Night We Met', 'artist': 'Lord Huron'},
        {'title': 'Ocean Eyes', 'artist': 'Billie Eilish'},
        {'title': 'Breathe Me', 'artist': 'Sia'},
        {'title': 'Rivers and Roads', 'artist': 'The Head and the Heart'},
      ],
    },
    {
      'title': 'Healing English',
      'mood': 'Healing',
      'language': 'English',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Music that heals and empowers.',
      'songs': [
        {'title': 'Fix You', 'artist': 'Coldplay'},
        {'title': 'Let It Be', 'artist': 'The Beatles'},
        {'title': 'Vienna', 'artist': 'Billy Joel'},
        {'title': 'Better Days', 'artist': 'Dermot Kennedy'},
        {'title': 'Stronger', 'artist': 'Kanye West'},
        {'title': 'Titanium', 'artist': 'David Guetta ft. Sia'},
        {'title': 'Unstoppable', 'artist': 'Sia'},
        {'title': 'Rise Up', 'artist': 'Andra Day'},
        {'title': 'Fight Song', 'artist': 'Rachel Platten'},
        {'title': 'Hall of Fame', 'artist': 'The Script ft. will.i.am'},
      ],
    },
    {
      'title': 'Focus English',
      'mood': 'Focus',
      'language': 'English',
      'icon': Icons.center_focus_strong_outlined,
      'color': AppColors.softIndigo,
      'description': 'Ambient and cinematic for deep work.',
      'songs': [
        {'title': 'Clair de Lune', 'artist': 'Debussy'},
        {'title': 'Gymnop\u00e9die No.1', 'artist': 'Erik Satie'},
        {'title': 'Intro', 'artist': 'The xx'},
        {'title': 'Midnight City', 'artist': 'M83'},
        {'title': 'Retrograde', 'artist': 'James Blake'},
        {'title': 'Re:Stacks', 'artist': 'Bon Iver'},
        {'title': 'Nuvole Bianche', 'artist': 'Ludovico Einaudi'},
        {'title': 'River Flows in You', 'artist': 'Yiruma'},
        {'title': "Comptine d'un autre \u00e9t\u00e9", 'artist': 'Yann Tiersen'},
        {'title': 'Arrival of the Birds', 'artist': 'The Cinematic Orchestra'},
      ],
    },
    // ── Hindi ──
    {
      'title': 'Bollywood Beats',
      'mood': 'Happy',
      'language': 'Hindi',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'Bollywood bangers to get you moving.',
      'songs': [
        {'title': 'Badtameez Dil', 'artist': 'Benny Dayal'},
        {'title': 'Balam Pichkari', 'artist': 'Vishal Dadlani & Shalmali'},
        {'title': 'London Thumakda', 'artist': 'Labh Janjua & Sonu Kakkar'},
        {'title': 'Gallan Goodiyan', 'artist': 'Shankar Mahadevan'},
        {'title': 'Kar Gayi Chull', 'artist': 'Badshah & Neha Kakkar'},
        {'title': 'Desi Girl', 'artist': 'Vishal Dadlani & Shankar Mahadevan'},
        {'title': 'Ainvayi Ainvayi', 'artist': 'Salim Merchant'},
        {'title': 'Mauja Hi Mauja', 'artist': 'Mika Singh'},
        {'title': 'Senorita', 'artist': 'Farhan Akhtar & Hrithik Roshan'},
        {'title': 'Ghungroo', 'artist': 'Arijit Singh & Shilpa Rao'},
      ],
    },
    {
      'title': 'Hindi Calm',
      'mood': 'Calm',
      'language': 'Hindi',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Soothing Bollywood for quiet moments.',
      'songs': [
        {'title': 'Tum Hi Ho', 'artist': 'Arijit Singh'},
        {'title': 'Agar Tum Saath Ho', 'artist': 'Arijit Singh & Alka Yagnik'},
        {'title': 'Channa Mereya', 'artist': 'Arijit Singh'},
        {'title': 'Kabira', 'artist': 'Arijit Singh & Tochi Raina'},
        {'title': 'Tere Bina', 'artist': 'A.R. Rahman'},
        {'title': 'Iktara', 'artist': 'Amit Trivedi & Kavita Seth'},
        {'title': 'Phir Le Aaya Dil', 'artist': 'Arijit Singh'},
        {'title': 'Tujhe Kitna Chahne Lage', 'artist': 'Arijit Singh'},
        {'title': 'Hawayein', 'artist': 'Arijit Singh'},
        {'title': 'Raabta', 'artist': 'Arijit Singh'},
      ],
    },
    {
      'title': 'Hindi Healing',
      'mood': 'Healing',
      'language': 'Hindi',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Motivational Hindi anthems.',
      'songs': [
        {'title': 'Kun Faya Kun', 'artist': 'A.R. Rahman & Javed Ali'},
        {'title': 'Jai Ho', 'artist': 'A.R. Rahman & Sukhwinder Singh'},
        {'title': 'Zinda', 'artist': 'Shankar Mahadevan'},
        {'title': 'Chak De India', 'artist': 'Sukhwinder Singh'},
        {'title': 'Dangal Title Track', 'artist': 'Daler Mehndi'},
        {'title': 'Sultan Title Track', 'artist': 'Sukhwinder Singh'},
        {'title': 'Apna Time Aayega', 'artist': 'Ranveer Singh'},
        {'title': 'Kar Har Maidaan Fateh', 'artist': 'Sukhwinder Singh'},
        {'title': 'Brothers Anthem', 'artist': 'Vishal Dadlani'},
        {'title': 'Lakshya Title Track', 'artist': 'Shankar Mahadevan'},
      ],
    },
    // ── Telugu ──
    {
      'title': 'Telugu Energy',
      'mood': 'Happy',
      'language': 'Telugu',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'High-energy Telugu chart-toppers.',
      'songs': [
        {'title': 'Buttabomma', 'artist': 'Armaan Malik'},
        {'title': 'Samajavaragamana', 'artist': 'Sid Sriram'},
        {'title': 'Ramuloo Ramulaa', 'artist': 'Anurag Kulkarni & Mangli'},
        {'title': 'Butta Bomma', 'artist': 'Armaan Malik'},
        {'title': 'Srivalli', 'artist': 'Sid Sriram'},
        {'title': 'Oo Antava', 'artist': 'Indravathi Chauhan'},
        {'title': 'Naatu Naatu', 'artist': 'Rahul Sipligunj & Kaala Bhairava'},
        {'title': 'Rangamma Mangamma', 'artist': 'M.M. Keeravani'},
        {'title': 'Mind Block', 'artist': 'Blaaze & Ranina Reddy'},
        {'title': 'Nuvvu Ready', 'artist': 'Thaman S'},
      ],
    },
    {
      'title': 'Telugu Calm',
      'mood': 'Calm',
      'language': 'Telugu',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Tender Telugu melodies for the soul.',
      'songs': [
        {'title': 'Ye Maaya Chesave', 'artist': 'A.R. Rahman'},
        {'title': 'Nee Jathaga', 'artist': 'Haricharan'},
        {'title': 'Emai Poyave', 'artist': 'Sid Sriram'},
        {'title': 'Inkem Inkem', 'artist': 'Sid Sriram'},
        {'title': 'Manasu Maree', 'artist': 'S.P. Balasubrahmanyam'},
        {'title': 'Vachinde', 'artist': 'Anirudh Ravichander'},
        {'title': 'Yenti Yenti', 'artist': 'Chinmayi'},
        {'title': 'Pillaa Raa', 'artist': 'Sid Sriram'},
        {'title': 'Undiporaadhey', 'artist': 'Sid Sriram'},
        {'title': 'Saranga Dariya', 'artist': 'Mangli'},
      ],
    },
    // ── Malayalam ──
    {
      'title': 'Malayalam Vibes',
      'mood': 'Happy',
      'language': 'Malayalam',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'Feel-good Malayalam favourites.',
      'songs': [
        {'title': 'Jimikki Kammal', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Entammede Jimikki Kammal', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Appangal Embadum', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Lailakame', 'artist': 'Vijay Yesudas'},
        {'title': 'Poomaram', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Kaathirunnu Kaathirunnu', 'artist': 'K.J. Yesudas'},
        {'title': 'Malare', 'artist': 'Vijay Yesudas'},
        {'title': 'Premam Theme', 'artist': 'Rajesh Murugesan'},
        {'title': 'Uyiril Thodum', 'artist': 'Sujatha Mohan'},
        {'title': 'Minungum', 'artist': 'Vineeth Sreenivasan'},
      ],
    },
    {
      'title': 'Malayalam Calm',
      'mood': 'Calm',
      'language': 'Malayalam',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Peaceful Malayalam melodies.',
      'songs': [
        {'title': 'Aaromale', 'artist': 'A.R. Rahman'},
        {'title': 'Aaro Nee Aaro', 'artist': 'Haricharan'},
        {'title': 'Kannum Kannum', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Karale Kunnimani', 'artist': 'K.J. Yesudas'},
        {'title': 'Nee Himamazhayayi', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Pavizha Mazha', 'artist': 'Harisankar'},
        {'title': 'Mazhaye Mazhaye', 'artist': 'Hariharan'},
        {'title': 'Vathikkalu Vellaripravu', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Etho Varmukilin', 'artist': 'K.J. Yesudas'},
        {'title': 'Minnunnunde Mullapole', 'artist': 'M.G. Sreekumar'},
      ],
    },
    // ── Korean ──
    {
      'title': 'K-Pop Energy',
      'mood': 'Happy',
      'language': 'Korean',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'High-energy K-Pop hits.',
      'songs': [
        {'title': 'Dynamite', 'artist': 'BTS'},
        {'title': 'How You Like That', 'artist': 'BLACKPINK'},
        {'title': 'Gangnam Style', 'artist': 'PSY'},
        {'title': 'Love Shot', 'artist': 'EXO'},
        {"title": "God's Menu", 'artist': 'Stray Kids'},
        {'title': 'LALISA', 'artist': 'Lisa'},
        {'title': 'Next Level', 'artist': 'aespa'},
        {'title': 'Butter', 'artist': 'BTS'},
        {'title': 'Pink Venom', 'artist': 'BLACKPINK'},
        {'title': 'Super', 'artist': 'Seventeen'},
      ],
    },
    {
      'title': 'Korean Calm',
      'mood': 'Calm',
      'language': 'Korean',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Soft K-Pop ballads and chill vibes.',
      'songs': [
        {'title': 'Spring Day', 'artist': 'BTS'},
        {'title': 'Through the Night', 'artist': 'IU'},
        {'title': 'Love Poem', 'artist': 'IU'},
        {'title': 'Palette', 'artist': 'IU'},
        {'title': 'Eight', 'artist': 'IU & Suga'},
        {'title': 'Still With You', 'artist': 'Jungkook'},
        {'title': 'My Universe', 'artist': 'BTS & Coldplay'},
        {'title': 'Film Out', 'artist': 'BTS'},
        {'title': 'Stay', 'artist': 'BLACKPINK'},
        {'title': 'Celebrity', 'artist': 'IU'},
      ],
    },
    // ── Japanese ──
    {
      'title': 'J-Pop Vibes',
      'mood': 'Happy',
      'language': 'Japanese',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'Energetic J-Pop and anime bangers.',
      'songs': [
        {'title': 'Lemon', 'artist': 'Kenshi Yonezu'},
        {'title': 'Pretender', 'artist': 'Official HIGE DANdism'},
        {'title': 'Gurenge', 'artist': 'LiSA'},
        {'title': 'Shinzo wo Sasageyo', 'artist': 'Linked Horizon'},
        {'title': 'Unravel', 'artist': 'TK from Ling Tosite Sigure'},
        {'title': 'Sparkle', 'artist': 'RADWIMPS'},
        {'title': 'Kaikai Kitan', 'artist': 'Eve'},
        {'title': 'Idol', 'artist': 'YOASOBI'},
        {'title': 'Zankyosanka', 'artist': 'Aimer'},
        {'title': 'Homura', 'artist': 'LiSA'},
      ],
    },
    {
      'title': 'Japanese Calm',
      'mood': 'Calm',
      'language': 'Japanese',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Studio Ghibli and serene Japanese sounds.',
      'songs': [
        {'title': 'Nandemonaiya', 'artist': 'RADWIMPS'},
        {'title': 'Kataware Doki', 'artist': 'RADWIMPS'},
        {"title": "One Summer's Day", 'artist': 'Joe Hisaishi'},
        {'title': 'Merry-Go-Round of Life', 'artist': 'Joe Hisaishi'},
        {'title': 'The Rain', 'artist': 'Joe Hisaishi'},
        {'title': 'A Town With an Ocean View', 'artist': 'Joe Hisaishi'},
        {'title': 'Summer', 'artist': 'Joe Hisaishi'},
        {'title': 'Always With Me', 'artist': 'Joe Hisaishi'},
        {'title': 'Path of the Wind', 'artist': 'Joe Hisaishi'},
        {'title': 'Carrying You', 'artist': 'Joe Hisaishi'},
      ],
    },
    // ── Instrumental ──
    {
      'title': 'Classical Focus',
      'mood': 'Focus',
      'language': 'Instrumental',
      'icon': Icons.center_focus_strong_outlined,
      'color': AppColors.softIndigo,
      'description': 'Timeless classical pieces for concentration.',
      'songs': [
        {'title': 'Clair de Lune', 'artist': 'Claude Debussy'},
        {'title': 'Moonlight Sonata', 'artist': 'Ludwig van Beethoven'},
        {'title': 'Gymnop\u00e9die No.1', 'artist': 'Erik Satie'},
        {'title': 'Nocturne Op.9 No.2', 'artist': 'Fr\u00e9d\u00e9ric Chopin'},
        {'title': 'Canon in D', 'artist': 'Johann Pachelbel'},
        {'title': 'Air on G String', 'artist': 'Johann Sebastian Bach'},
        {'title': 'The Four Seasons: Spring', 'artist': 'Antonio Vivaldi'},
        {'title': 'F\u00fcr Elise', 'artist': 'Ludwig van Beethoven'},
        {'title': 'R\u00eaverie', 'artist': 'Claude Debussy'},
        {'title': 'Arabesque No.1', 'artist': 'Claude Debussy'},
      ],
    },
    {
      'title': 'Nature Sounds',
      'mood': 'Calm',
      'language': 'Instrumental',
      'icon': Icons.spa_outlined,
      'color': AppColors.sageGreen,
      'description': 'Immersive nature soundscapes.',
      'songs': [
        {'title': 'Ocean Waves', 'artist': 'Nature Sounds'},
        {'title': 'Rain on Leaves', 'artist': 'Nature Sounds'},
        {'title': 'Forest Birds', 'artist': 'Nature Sounds'},
        {'title': 'Gentle Stream', 'artist': 'Nature Sounds'},
        {'title': 'Thunderstorm', 'artist': 'Nature Sounds'},
        {'title': 'Wind in Trees', 'artist': 'Nature Sounds'},
        {'title': 'Campfire', 'artist': 'Nature Sounds'},
        {'title': 'Whale Song', 'artist': 'Nature Sounds'},
        {'title': 'Night Crickets', 'artist': 'Nature Sounds'},
        {'title': 'Morning Dew', 'artist': 'Nature Sounds'},
      ],
    },
    {
      'title': 'Lo-fi Beats',
      'mood': 'Focus',
      'language': 'Instrumental',
      'icon': Icons.center_focus_strong_outlined,
      'color': AppColors.softIndigo,
      'description': 'Chill lo-fi for study and work.',
      'songs': [
        {'title': 'Snowman', 'artist': 'Lo-fi Beats'},
        {'title': 'Coffee', 'artist': 'Lo-fi Beats'},
        {'title': 'Daylight', 'artist': 'Lo-fi Beats'},
        {'title': 'Affection', 'artist': 'Lo-fi Beats'},
        {'title': 'Biscuit', 'artist': 'Lo-fi Beats'},
        {'title': 'Maple Leaf Rag Lofi', 'artist': 'Lo-fi Beats'},
        {'title': 'Moonlight Lofi', 'artist': 'Lo-fi Beats'},
        {'title': 'Rainy Day', 'artist': 'Lo-fi Beats'},
        {'title': 'Study Session', 'artist': 'Lo-fi Beats'},
        {'title': 'Late Night', 'artist': 'Lo-fi Beats'},
      ],
    },
    // ── Smart Playlists ──
    {
      'title': 'Daily Reset',
      'mood': 'Happy',
      'language': 'All',
      'icon': Icons.refresh_rounded,
      'color': AppColors.warmCoral,
      'description': 'A multilingual energy boost for your day.',
      'songs': [
        {'title': 'Happy', 'artist': 'Pharrell Williams'},
        {'title': 'Rowdy Baby', 'artist': 'Dhanush & Dhee'},
        {'title': 'Dynamite', 'artist': 'BTS'},
        {'title': 'Badtameez Dil', 'artist': 'Benny Dayal'},
        {'title': 'Naatu Naatu', 'artist': 'Rahul Sipligunj & Kaala Bhairava'},
        {'title': 'Jimikki Kammal', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Gurenge', 'artist': 'LiSA'},
        {'title': 'Uptown Funk', 'artist': 'Bruno Mars'},
        {'title': 'Vaathi Coming', 'artist': 'Anirudh Ravichander'},
        {'title': 'Gangnam Style', 'artist': 'PSY'},
      ],
    },
    {
      'title': 'Sleep Mode',
      'mood': 'Calm',
      'language': 'All',
      'icon': Icons.nightlight_round,
      'color': AppColors.sageGreen,
      'description': 'Drift off with ambient and slow melodies.',
      'songs': [
        {'title': 'Weightless', 'artist': 'Marconi Union'},
        {'title': 'Ocean Waves', 'artist': 'Nature Sounds'},
        {'title': 'Munbe Vaa', 'artist': 'A.R. Rahman'},
        {'title': 'Nandemonaiya', 'artist': 'RADWIMPS'},
        {'title': 'Night Crickets', 'artist': 'Nature Sounds'},
        {'title': 'Through the Night', 'artist': 'IU'},
        {'title': 'Rain on Leaves', 'artist': 'Nature Sounds'},
        {'title': 'Tum Hi Ho', 'artist': 'Arijit Singh'},
        {'title': 'Always With Me', 'artist': 'Joe Hisaishi'},
        {'title': 'Gentle Stream', 'artist': 'Nature Sounds'},
      ],
    },
    {
      'title': 'Focus Mode',
      'mood': 'Focus',
      'language': 'All',
      'icon': Icons.center_focus_strong_outlined,
      'color': AppColors.softIndigo,
      'description': 'Instrumental and lo-fi for deep work.',
      'songs': [
        {'title': 'Clair de Lune', 'artist': 'Claude Debussy'},
        {'title': 'River Flows in You', 'artist': 'Yiruma'},
        {'title': 'Bombay Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Study Session', 'artist': 'Lo-fi Beats'},
        {'title': 'Nuvole Bianche', 'artist': 'Ludovico Einaudi'},
        {'title': 'Merry-Go-Round of Life', 'artist': 'Joe Hisaishi'},
        {'title': 'Moonlight Sonata', 'artist': 'Ludwig van Beethoven'},
        {'title': 'Coffee', 'artist': 'Lo-fi Beats'},
        {'title': 'Roja Theme', 'artist': 'A.R. Rahman'},
        {'title': 'Canon in D', 'artist': 'Johann Pachelbel'},
      ],
    },
    {
      'title': 'Deep Calm',
      'mood': 'Calm',
      'language': 'All',
      'icon': Icons.self_improvement_rounded,
      'color': AppColors.sageGreen,
      'description': 'Meditation soundscapes for inner peace.',
      'songs': [
        {'title': 'Whale Song', 'artist': 'Nature Sounds'},
        {'title': 'Experience', 'artist': 'Ludovico Einaudi'},
        {'title': 'Wind in Trees', 'artist': 'Nature Sounds'},
        {'title': 'Kataware Doki', 'artist': 'RADWIMPS'},
        {'title': 'Morning Dew', 'artist': 'Nature Sounds'},
        {'title': 'Pachai Nirame', 'artist': 'A.R. Rahman'},
        {'title': 'Campfire', 'artist': 'Nature Sounds'},
        {'title': 'Spring Day', 'artist': 'BTS'},
        {'title': 'Pavizha Mazha', 'artist': 'Harisankar'},
        {'title': 'Holocene', 'artist': 'Bon Iver'},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredPlaylists {
    if (_selectedLanguages.isEmpty) return _playlists;
    final filtered = _playlists
        .where((pl) =>
            pl['language'] == 'All' ||
            _selectedLanguages.contains(pl['language']))
        .toList();
    return filtered.isEmpty ? _playlists : filtered;
  }

  @override
  void initState() {
    super.initState();
    _recommendation = AppNavigationService().musicRecommendation.value;
    AppNavigationService().musicRecommendation.addListener(_onRecommendation);
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
      });
    });
    _loadCalmSession();
  }

  @override
  void dispose() {
    AppNavigationService()
        .musicRecommendation
        .removeListener(_onRecommendation);
    _player.dispose();
    super.dispose();
  }

  void _onRecommendation() {
    if (!mounted) return;
    setState(() {
      _recommendation = AppNavigationService().musicRecommendation.value;
    });
  }

  Future<void> _loadCalmSession() async {
    setState(() {
      _loadingSession = true;
      _sessionError = null;
    });

    try {
      final tracks = await MusicService().getCalmSessionTracks(count: 7);
      if (!mounted) return;
      setState(() {
        _sessionTracks = tracks;
        _activeTrackIndex = 0;
      });

      if (_sessionTracks.isNotEmpty) {
        await _playTrackAt(0, autoplay: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sessionError = 'Failed to load calm session.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSession = false;
        });
      }
    }
  }

  Future<void> _playTrackAt(int index, {bool autoplay = false}) async {
    if (index < 0 || index >= _sessionTracks.length) return;
    final track = _sessionTracks[index];

    try {
      if (track.fromCloud) {
        await _player.setUrl(track.sourceUrl);
      } else {
        await _player.setAsset(track.sourceUrl);
      }

      if (!mounted) return;
      setState(() {
        _activeTrackIndex = index;
      });

      if (autoplay) {
        await _player.play();
      }

      final user = AuthService().currentUser;
      if (user != null) {
        await DatabaseService().saveListenedSong(
          userId: user.$id,
          title: track.title,
          artist: track.artist,
          playlist: 'Calm Session',
          mood: track.mood,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sessionError = 'Could not play selected track.';
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (_sessionTracks.isEmpty) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2A38), Color(0xFF38546B), Color(0xFF7A8FA8)],
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
                  'Sound Space',
                  style: AppTypography.heroHeading(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Playlists curated for your mood.',
                  style: AppTypography.subtitle(
                    color: Colors.white.withValues(alpha: 0.7),
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
                const SizedBox(height: 16),
                _buildCalmSessionCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalmSessionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.sageGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.self_improvement_rounded,
                  size: 18,
                  color: AppColors.sageGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calm Music Session',
                      style: AppTypography.uiLabel(color: Colors.white),
                    ),
                    Text(
                      'Auto-plays from Appwrite Cloud (fallback to local)',
                      style: AppTypography.caption(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _sessionTracks.isEmpty ? null : _togglePlayback,
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingSession)
            const LinearProgressIndicator(minHeight: 3)
          else if (_sessionError != null)
            Text(
              _sessionError!,
              style: AppTypography.caption(color: AppColors.warmCoral),
            )
          else
            Column(
              children: List.generate(_sessionTracks.length, (i) {
                final track = _sessionTracks[i];
                final isActive = i == _activeTrackIndex;
                return GestureDetector(
                  onTap: () => _playTrackAt(i, autoplay: true),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.sageGreen.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? AppColors.sageGreen.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${i + 1}',
                          style: AppTypography.caption(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: AppTypography.caption(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${track.mood} · ${track.fromCloud ? 'Cloud' : 'Local'}',
                                style: AppTypography.caption(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isActive && _isPlaying
                              ? Icons.graphic_eq_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    final color = playlist['color'] as Color;
    final songs = playlist['songs'] as List;

    return GestureDetector(
      onTap: () => _openPlaylistDetail(playlist),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                playlist['icon'] as IconData,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist['title'] as String,
                    style: AppTypography.uiLabel(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist['description']}  \u00b7  ${songs.length} tracks',
                    style: AppTypography.caption(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 300),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                color: Colors.white),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.45),
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
                    final title =
                        Uri.encodeComponent(playlist['title'] as String);
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusButton),
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
