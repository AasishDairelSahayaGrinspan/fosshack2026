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

/// Music Screen - mood-aware playlist companion with language-first organization.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  String? _recommendation;
  String? _selectedLanguage; // Language-first approach

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
        {
          'title': "Comptine d'un autre \u00e9t\u00e9",
          'artist': 'Yann Tiersen',
        },
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
    // ── English: Stressed & Sleep ──
    {
      'title': 'Stressed to Calm English',
      'mood': 'Stressed',
      'language': 'English',
      'icon': Icons.bolt_rounded,
      'color': AppColors.warmCoral,
      'description': 'Release tension and ease anxiety.',
      'songs': [
        {'title': 'Let It Be', 'artist': 'The Beatles'},
        {'title': 'Skinny Love', 'artist': 'Bon Iver'},
        {'title': 'Fix You', 'artist': 'Coldplay'},
        {'title': 'Creep', 'artist': 'Radiohead'},
        {'title': 'Someone Like You', 'artist': 'Adele'},
        {'title': 'Tears in Heaven', 'artist': 'Eric Clapton'},
        {'title': 'Black', 'artist': 'Pearl Jam'},
        {'title': 'Hallelujah', 'artist': 'Leonard Cohen'},
        {'title': 'Wonderwall', 'artist': 'Oasis'},
        {'title': 'The Night We Met', 'artist': 'Lord Huron'},
      ],
    },
    {
      'title': 'Sleep English',
      'mood': 'Sleep',
      'language': 'English',
      'icon': Icons.nightlight_outlined,
      'color': AppColors.softIndigo,
      'description': 'Drift into peaceful slumber.',
      'songs': [
        {'title': 'Weightless', 'artist': 'Marconi Union'},
        {'title': 'Golden Slumbers', 'artist': 'The Beatles'},
        {'title': 'Falling Slowly', 'artist': 'Glen Hansard & Markéta Irglová'},
        {'title': 'Ocean Avenue', 'artist': 'Yellowcard'},
        {'title': 'Sunset', 'artist': 'The Midnight'},
        {'title': 'Night Owl', 'artist': 'Glee Cast'},
        {'title': 'Lullaby', 'artist': 'The Cure'},
        {'title': 'Dreaming of Sleep', 'artist': 'Big Light'},
        {'title': 'Sleep', 'artist': 'MC Yogi'},
        {'title': 'Sleepwalking', 'artist': 'The Chain Gang of 1974'},
      ],
    },
    // ── Tamil: Stressed & Sleep ──
    {
      'title': 'Stressed Tamil',
      'mood': 'Stressed',
      'language': 'Tamil',
      'icon': Icons.bolt_rounded,
      'color': AppColors.warmCoral,
      'description': 'Release tension with soothing Tamil tracks.',
      'songs': [
        {'title': 'Veere Veere', 'artist': 'Kaavalan'},
        {'title': 'Mazhai Kuruvi', 'artist': 'Nikhil Siddhartha'},
        {'title': 'Yen Irundhaal', 'artist': 'Jee'},
        {'title': 'Aasa Kooda Irundhu', 'artist': 'Dhanush'},
        {'title': 'Yethu Uruppada', 'artist': 'Thaman'},
        {'title': 'Vaayai Moodi Pesavum', 'artist': 'Rahman'},
        {'title': 'Vaanam Kottatum', 'artist': 'Govind Vasantha'},
        {'title': 'Kathaipoma', 'artist': 'Shabareesh Varma'},
        {'title': 'Nermaiyil', 'artist': 'Rajesh Murugesan'},
        {'title': 'Unna Naan Sollren', 'artist': 'GV Prakash Kumar'},
      ],
    },
    {
      'title': 'Sleep Tamil',
      'mood': 'Sleep',
      'language': 'Tamil',
      'icon': Icons.nightlight_outlined,
      'color': AppColors.softIndigo,
      'description': 'Restful Tamil melodies for bedtime.',
      'songs': [
        {'title': 'Nadhi Chirukili', 'artist': 'Karthik'},
        {'title': 'Irukkum Kanda', 'artist': 'Thaman'},
        {'title': 'Unakum Enakum', 'artist': 'Jee'},
        {'title': 'Mazhai Pozhiyum', 'artist': 'Govind Vasantha'},
        {'title': 'Apo Nee Enna Solla', 'artist': 'Anirudh'},
        {'title': 'Kathanandhan', 'artist': 'Thaman'},
        {'title': 'Thani Oruvan', 'artist': 'Jee'},
        {'title': 'Irukkum Vaalkai', 'artist': 'Govind Vasantha'},
        {'title': 'Kadhal Kili', 'artist': 'Jee'},
        {'title': 'Idhayam Padikatu', 'artist': 'Thaman'},
      ],
    },
    // ── Hindi: Stressed, Sleep, Focus ──
    {
      'title': 'Stressed Hindi',
      'mood': 'Stressed',
      'language': 'Hindi',
      'icon': Icons.bolt_rounded,
      'color': AppColors.warmCoral,
      'description': 'Soothing Hindi tracks for tense moments.',
      'songs': [
        {'title': 'Main Aur Mera Tanhaayi', 'artist': 'Mohit Chauhan'},
        {'title': 'Tum Ho', 'artist': 'Anushka Manchanda'},
        {'title': 'Akele Hain', 'artist': 'A.R. Rahman'},
        {'title': 'Pehla Pehla Pyaar', 'artist': 'Rishi Kapoor'},
        {'title': 'Jiya Jaye', 'artist': 'Vishal Dadlani'},
        {'title': 'Aankhein Khuli Ho Ya Bandh', 'artist': 'Shankar Mahadevan'},
        {'title': 'Ek Pal Ka Jeena', 'artist': 'Sonu Nigam'},
        {'title': 'Yaad Aa Raha Hai', 'artist': 'Sonu Nigam'},
        {'title': 'Tere Naina', 'artist': 'A.R. Rahman'},
        {'title': 'Jaane Nahi Denge Tummhe', 'artist': 'Shankar Mahadevan'},
      ],
    },
    {
      'title': 'Sleep Hindi',
      'mood': 'Sleep',
      'language': 'Hindi',
      'icon': Icons.nightlight_outlined,
      'color': AppColors.softIndigo,
      'description': 'Gentle Hindi lullabies for restful sleep.',
      'songs': [
        {'title': 'Sukhiyaan', 'artist': 'A.R. Rahman'},
        {'title': 'Sone De', 'artist': 'Shankar Mahadevan'},
        {'title': 'Rat Bhar', 'artist': 'Sonu Nigam'},
        {'title': 'Raaste Se Jayenge', 'artist': 'A.R. Rahman'},
        {'title': 'Raatein Bhar', 'artist': 'Sunidhi Chauhan'},
        {'title': 'Chanda Hai Tu', 'artist': 'Sonu Nigam'},
        {'title': 'Neend Na Aaye', 'artist': 'Shankar Mahadevan'},
        {'title': 'Khwaab Dekhta Hoon', 'artist': 'A.R. Rahman'},
        {'title': 'Nindiya Se Bhara', 'artist': 'Suresh Wadkar'},
        {'title': 'Sapne Mein', 'artist': 'Sunidhi Chauhan'},
      ],
    },
    {
      'title': 'Focus Hindi',
      'mood': 'Focus',
      'language': 'Hindi',
      'icon': Icons.school_rounded,
      'color': AppColors.softIndigo,
      'description': 'Instrumental and lo-fi Hindi for concentration.',
      'songs': [
        {'title': 'Yahan Rahta Nahi', 'artist': 'A.R. Rahman'},
        {'title': 'Khamoshiyan', 'artist': 'A.R. Rahman'},
        {'title': 'Chandni Raat', 'artist': 'A.R. Rahman'},
        {'title': 'Rabba', 'artist': 'Shankar Mahadevan'},
        {'title': 'Tere Haathon Mein', 'artist': 'A.R. Rahman'},
        {'title': 'Shuddh Desi', 'artist': 'Raftaar'},
        {'title': 'Teri Umeed', 'artist': 'Shankar Mahadevan'},
        {'title': 'Arziyan', 'artist': 'A.R. Rahman'},
        {'title': 'Dilse Re', 'artist': 'A.R. Rahman'},
        {'title': 'Maa', 'artist': 'Shankar Mahadevan'},
      ],
    },
    // ── Telugu: Healing, Stressed, Focus, Sleep ──
    {
      'title': 'Telugu Healing',
      'mood': 'Healing',
      'language': 'Telugu',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Motivational Telugu anthems for recovery.',
      'songs': [
        {'title': 'Arere O Priya', 'artist': 'M.M. Keeravani'},
        {'title': 'Rangu Rangu', 'artist': 'Sid Sriram'},
        {'title': 'Chandamama', 'artist': 'Haricharan'},
        {'title': 'Velalo', 'artist': 'Anirudh Ravichander'},
        {'title': 'Chandni Raathon Mein', 'artist': 'Sid Sriram'},
        {'title': 'Thogata Chusthava', 'artist': 'M.M. Keeravani'},
        {'title': 'Arjun Reddy Title', 'artist': 'Radhan'},
        {'title': 'Vennela Pothe', 'artist': 'Chandrabose'},
        {'title': 'Manasulona', 'artist': 'Haricharan'},
        {'title': 'Prema Khandana', 'artist': 'Sid Sriram'},
      ],
    },
    {
      'title': 'Telugu Stressed',
      'mood': 'Stressed',
      'language': 'Telugu',
      'icon': Icons.bolt_rounded,
      'color': AppColors.warmCoral,
      'description': 'Soothing Telugu tracks to ease tension.',
      'songs': [
        {'title': 'Nee Siggu', 'artist': 'Haricharan'},
        {'title': 'Nela Ticket', 'artist': 'Anirudh Ravichander'},
        {'title': 'Oye Manasunda', 'artist': 'Radhan'},
        {'title': 'Chinnadi Chinnadi', 'artist': 'Sid Sriram'},
        {'title': 'Rana Khandaya', 'artist': 'M.M. Keeravani'},
        {'title': 'Mandara', 'artist': 'Haricharan'},
        {'title': 'Thanam', 'artist': 'Anirudh Ravichander'},
        {'title': 'Telangana', 'artist': 'M.M. Keeravani'},
        {'title': 'Ninninchuke Vartha', 'artist': 'Haricharan'},
        {'title': 'Nee Kavali', 'artist': 'Radhan'},
      ],
    },
    {
      'title': 'Telugu Focus',
      'mood': 'Focus',
      'language': 'Telugu',
      'icon': Icons.school_rounded,
      'color': AppColors.softIndigo,
      'description': 'Instrumental Telugu for deep work.',
      'songs': [
        {'title': 'Vasantam', 'artist': 'Anirudh Ravichander'},
        {'title': 'Taratam', 'artist': 'M.M. Keeravani'},
        {'title': 'Pranam', 'artist': 'Radhan'},
        {'title': 'Sukhinchutundi', 'artist': 'Haricharan'},
        {'title': 'Naa Helane', 'artist': 'Sid Sriram'},
        {'title': 'Kotha Kathalu', 'artist': 'Anirudh Ravichander'},
        {'title': 'Ananda Bhairava', 'artist': 'M.M. Keeravani'},
        {'title': 'Chandra Chakram', 'artist': 'Radhan'},
        {'title': 'Mandala', 'artist': 'Haricharan'},
        {'title': 'Rhythmic Telugu', 'artist': 'Anirudh Ravichander'},
      ],
    },
    {
      'title': 'Telugu Sleep',
      'mood': 'Sleep',
      'language': 'Telugu',
      'icon': Icons.nightlight_outlined,
      'color': AppColors.softIndigo,
      'description': 'Gentle Telugu melodies for sleep.',
      'songs': [
        {'title': 'Sukhapradam', 'artist': 'Haricharan'},
        {'title': 'Nidra Gaanam', 'artist': 'M.M. Keeravani'},
        {'title': 'Chandrika', 'artist': 'Anirudh Ravichander'},
        {'title': 'Sukham Chuva', 'artist': 'Sid Sriram'},
        {'title': 'Vennelu', 'artist': 'Radhan'},
        {'title': 'Shanti Geetam', 'artist': 'Haricharan'},
        {'title': 'Ratri Raagam', 'artist': 'M.M. Keeravani'},
        {'title': 'Nishaachara', 'artist': 'Anirudh Ravichander'},
        {'title': 'Svapna Geetam', 'artist': 'Radhan'},
        {'title': 'Nidrikari', 'artist': 'Sid Sriram'},
      ],
    },
    // ── Malayalam: Healing, Stressed, Focus, Sleep ──
    {
      'title': 'Malayalam Healing',
      'mood': 'Healing',
      'language': 'Malayalam',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Uplifting Malayalam songs for recovery.',
      'songs': [
        {'title': 'Aaro Njan', 'artist': 'Vijay Yesudas'},
        {'title': 'Aniruddhan Vandana', 'artist': 'K.J. Yesudas'},
        {'title': 'Mazha Pozhiyunna', 'artist': 'Sujatha Mohan'},
        {'title': 'Njangalil', 'artist': 'Haricharan'},
        {'title': 'Sthithapragna', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Thava Tharavum', 'artist': 'Sujatha Mohan'},
        {'title': 'Aananda Bhairava', 'artist': 'K.J. Yesudas'},
        {'title': 'Guruvayurappan', 'artist': 'Haricharan'},
        {'title': 'Puthumazhayil', 'artist': 'Vijay Yesudas'},
        {'title': 'Malikamaavu', 'artist': 'Sujatha Mohan'},
      ],
    },
    {
      'title': 'Malayalam Stressed',
      'mood': 'Stressed',
      'language': 'Malayalam',
      'icon': Icons.bolt_rounded,
      'color': AppColors.warmCoral,
      'description': 'Soothing Malayalam for tense moments.',
      'songs': [
        {'title': 'Chandavrutha', 'artist': 'K.J. Yesudas'},
        {'title': 'Neerikili', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Thiruvananthapuram', 'artist': 'Haricharan'},
        {'title': 'Vaneetha Vadanam', 'artist': 'Sujatha Mohan'},
        {'title': 'Kripa Sagar', 'artist': 'Vijay Yesudas'},
        {'title': 'Prabhandha', 'artist': 'K.J. Yesudas'},
        {'title': 'Dakshinamurti', 'artist': 'Haricharan'},
        {'title': 'Sarvaprani', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Shankara Narayana', 'artist': 'Sujatha Mohan'},
        {'title': 'Ananda Lahari', 'artist': 'Vijay Yesudas'},
      ],
    },
    {
      'title': 'Malayalam Focus',
      'mood': 'Focus',
      'language': 'Malayalam',
      'icon': Icons.school_rounded,
      'color': AppColors.softIndigo,
      'description': 'Instrumental Malayalam for concentration.',
      'songs': [
        {'title': 'Ragam Ganam', 'artist': 'K.J. Yesudas'},
        {'title': 'Taalam', 'artist': 'Haricharan'},
        {'title': 'Ragas Rekha', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Rasa Vilas', 'artist': 'Sujatha Mohan'},
        {'title': 'Priya Raga', 'artist': 'Vijay Yesudas'},
        {'title': 'Sabda Brahman', 'artist': 'K.J. Yesudas'},
        {'title': 'Chitra Raga', 'artist': 'Haricharan'},
        {'title': 'Ardhanareeswara', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Bhaava Ganam', 'artist': 'Sujatha Mohan'},
        {'title': 'Rasa Tantra', 'artist': 'Vijay Yesudas'},
      ],
    },
    {
      'title': 'Malayalam Sleep',
      'mood': 'Sleep',
      'language': 'Malayalam',
      'icon': Icons.nightlight_outlined,
      'color': AppColors.softIndigo,
      'description': 'Gentle Malayalam lullabies.',
      'songs': [
        {'title': 'Nidrayil Padi', 'artist': 'K.J. Yesudas'},
        {'title': 'Svapna Kaavyam', 'artist': 'Haricharan'},
        {'title': 'Chandrika Ratri', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Sukha Nidra', 'artist': 'Sujatha Mohan'},
        {'title': 'Nidrabhanga', 'artist': 'Vijay Yesudas'},
        {'title': 'Raat Ki Baatein', 'artist': 'K.J. Yesudas'},
        {'title': 'Nishachar Ganam', 'artist': 'Haricharan'},
        {'title': 'Aanandam Nidra', 'artist': 'Vineeth Sreenivasan'},
        {'title': 'Chandamama Raatri', 'artist': 'Sujatha Mohan'},
        {'title': 'Svapna Drishti', 'artist': 'Vijay Yesudas'},
      ],
    },
    // ── Korean: Healing, Stressed, Focus, Sleep ──
    {
      'title': 'Korean Healing',
      'mood': 'Healing',
      'language': 'Korean',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Uplifting Korean songs for recovery.',
      'songs': [
        {'title': 'Through the Night', 'artist': 'IU'},
        {'title': 'Tear', 'artist': 'BTS'},
        {'title': 'Spring Day', 'artist': 'BTS'},
        {'title': 'Best Day of My Life', 'artist': 'AMERICAN AUTHORS'},
        {'title': 'Epiphany', 'artist': 'Jin'},
        {'title': 'Dimple', 'artist': 'BTS'},
        {'title': 'Life Goes On', 'artist': 'BTS'},
        {'title': 'Butter', 'artist': 'BTS'},
        {'title': 'Permission to Dance', 'artist': 'BTS'},
        {'title': 'Yet To Come', 'artist': 'BTS'},
      ],
    },
    {
      'title': 'Korean Stressed',
      'mood': 'Stressed',
      'language': 'Korean',
      'icon': Icons.bolt_rounded,
      'color': AppColors.warmCoral,
      'description': 'Soothing Korean tracks for tension relief.',
      'songs': [
        {'title': 'Falling', 'artist': 'IU'},
        {'title': 'Moonlight', 'artist': 'AKMU'},
        {'title': 'You Were Beautiful', 'artist': 'DAY6'},
        {'title': 'Beautiful', 'artist': 'Crush'},
        {'title': 'She', 'artist': 'Dodie'},
        {'title': 'Goodbye', 'artist': 'Bol4'},
        {'title': 'Nostalgia', 'artist': 'IU'},
        {'title': 'Wish You Were Here', 'artist': 'Boynextdoor'},
        {'title': 'Lonely', 'artist': 'Justin Bieber ft. Benny Blanco'},
        {'title': 'Euphoria', 'artist': 'BTS'},
      ],
    },
    {
      'title': 'Korean Focus',
      'mood': 'Focus',
      'language': 'Korean',
      'icon': Icons.school_rounded,
      'color': AppColors.softIndigo,
      'description': 'Korean lo-fi and instrumental for work.',
      'songs': [
        {'title': 'Paper Hearts', 'artist': 'BTS'},
        {'title': 'Reflection', 'artist': 'Jungkook'},
        {'title': 'Lost', 'artist': 'Frank Ocean'},
        {'title': 'Night City', 'artist': 'Korean Indie'},
        {'title': 'Study Mode', 'artist': 'Lo-fi Korea'},
        {'title': 'Morning Commute', 'artist': 'K-indie'},
        {'title': 'Quiet Moments', 'artist': 'Korean Chill'},
        {'title': 'Campus Walk', 'artist': 'Study Beats'},
        {'title': 'Focus Time', 'artist': 'Korean Lo-fi'},
        {'title': 'Work Vibes', 'artist': 'Chill Korean'},
      ],
    },
    {
      'title': 'Korean Sleep',
      'mood': 'Sleep',
      'language': 'Korean',
      'icon': Icons.nightlight_outlined,
      'color': AppColors.softIndigo,
      'description': 'Gentle Korean lullabies for bedtime.',
      'songs': [
        {'title': 'Gogo', 'artist': 'BTS'},
        {'title': 'Fly to My Room', 'artist': 'BTS'},
        {'title': 'Pied Piper', 'artist': 'BTS'},
        {'title': 'Angel', 'artist': 'IU'},
        {'title': 'Wind', 'artist': 'IU'},
        {'title': 'Starry Night', 'artist': 'TAEYEON'},
        {'title': 'Sleepy', 'artist': 'Bol4'},
        {'title': 'Good Night', 'artist': 'Korean Artists'},
        {'title': 'Dream On', 'artist': 'Korean Indie'},
        {'title': 'Goodnight Seoul', 'artist': 'Korean Chill'},
      ],
    },
    // ── Japanese: Healing, Stressed, Focus, Sleep ──
    {
      'title': 'Japanese Healing',
      'mood': 'Healing',
      'language': 'Japanese',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Uplifting Japanese songs for recovery.',
      'songs': [
        {'title': 'Sparkle', 'artist': 'RADWIMPS'},
        {'title': 'Nandemonaiya', 'artist': 'RADWIMPS'},
        {'title': 'Hikaru Nara', 'artist': 'Goose House'},
        {'title': 'Taiko no Tatsujin', 'artist': 'Naoki Morita'},
        {'title': 'Tenshi no Yubikiri', 'artist': 'Hisaishi Joe'},
        {'title': 'Hopeful Chant', 'artist': 'Isao Tomita'},
        {'title': 'Cherry Blossoms', 'artist': 'Traditional Japanese'},
        {'title': 'Rising Sun', 'artist': 'Japanese Composers'},
        {'title': 'New Beginning', 'artist': 'Tetsuya Akikawa'},
        {'title': 'Tomorrow Will Be Better', 'artist': 'Japanese Artists'},
      ],
    },
    {
      'title': 'Japanese Stressed',
      'mood': 'Stressed',
      'language': 'Japanese',
      'icon': Icons.bolt_rounded,
      'color': AppColors.warmCoral,
      'description': 'Soothing Japanese for anxiety relief.',
      'songs': [
        {'title': 'Zenzenzense', 'artist': 'RADWIMPS'},
        {'title': 'Kataware Doki', 'artist': 'RADWIMPS'},
        {'title': 'Mizuiro', 'artist': 'RADWIMPS'},
        {'title': 'Tears', 'artist': 'Yuuki Ozaki'},
        {'title': 'Bamboo Forest', 'artist': 'Nature Sounds'},
        {'title': 'Peaceful Garden', 'artist': 'Traditional Japanese'},
        {'title': 'Zen Meditation', 'artist': 'Japanese Masters'},
        {'title': 'Gentle Rain', 'artist': 'Japanese Composers'},
        {'title': 'Harmony', 'artist': 'Japanese Wellness'},
        {'title': 'Tranquil', 'artist': 'Isao Tomita'},
      ],
    },
    {
      'title': 'Japanese Focus',
      'mood': 'Focus',
      'language': 'Japanese',
      'icon': Icons.school_rounded,
      'color': AppColors.softIndigo,
      'description': 'Japanese lo-fi and instrumental for work.',
      'songs': [
        {'title': 'Concentration', 'artist': 'Japanese Lo-fi'},
        {'title': 'Study Session', 'artist': 'Tokyo Chill'},
        {'title': 'Deep Focus', 'artist': 'Japanese Beats'},
        {'title': 'Work Flow', 'artist': 'Chill Vibes Japan'},
        {'title': 'Mind Clear', 'artist': 'Japanese Instrumental'},
        {'title': 'Zen Work', 'artist': 'Japanese Masters'},
        {'title': 'Office Vibes', 'artist': 'Lo-fi Japan'},
        {'title': 'Productive Hour', 'artist': 'Japanese Composers'},
        {'title': 'Focused Energy', 'artist': 'Study Beats'},
        {'title': 'Workflow', 'artist': 'Tokyo Lo-fi'},
      ],
    },
    {
      'title': 'Japanese Sleep',
      'mood': 'Sleep',
      'language': 'Japanese',
      'icon': Icons.nightlight_outlined,
      'color': AppColors.softIndigo,
      'description': 'Gentle Japanese lullabies.',
      'songs': [
        {'title': 'Kaze ni Naru', 'artist': 'Joe Hisaishi'},
        {'title': 'Suteki Da Ne', 'artist': 'Nobuo Uematsu'},
        {'title': 'Ashitaka Hishoku', 'artist': 'Joe Hisaishi'},
        {'title': 'Howl\'s Moving Castle Theme', 'artist': 'Joe Hisaishi'},
        {'title': 'The Name of Life', 'artist': 'Joe Hisaishi'},
        {'title': 'Goodnight Lullaby', 'artist': 'Traditional Japanese'},
        {'title': 'Sweet Dreams', 'artist': 'Japanese Wellness'},
        {'title': 'Restful Night', 'artist': 'Isao Tomita'},
        {'title': 'Peaceful Sleep', 'artist': 'Japanese Composers'},
        {'title': 'Dream Land', 'artist': 'Tetsuya Akikawa'},
      ],
    },
    // ── Instrumental: Happy, Healing, Stressed, Sleep ──
    {
      'title': 'Instrumental Happy',
      'mood': 'Happy',
      'language': 'Instrumental',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': AppColors.warmCoral,
      'description': 'Uplifting instrumental for good vibes.',
      'songs': [
        {'title': 'Wake Up', 'artist': 'Shawn Mendes Instrumental'},
        {'title': 'Sunshine', 'artist': 'Lo-fi Beats'},
        {'title': 'Happy Day', 'artist': 'Royalty Free Music'},
        {'title': 'Good Morning', 'artist': 'Chill Instruments'},
        {'title': 'Joyful', 'artist': 'Peaceful Piano'},
        {'title': 'Uplifting', 'artist': 'Cinematic Sounds'},
        {'title': 'Bright Future', 'artist': 'Modern Instruments'},
        {'title': 'Dancing', 'artist': 'World Music'},
        {'title': 'Celebration', 'artist': 'Festival Beats'},
        {'title': 'Smile', 'artist': 'Happy Music'},
      ],
    },
    {
      'title': 'Instrumental Healing',
      'mood': 'Healing',
      'language': 'Instrumental',
      'icon': Icons.healing_outlined,
      'color': AppColors.orangeE2814d,
      'description': 'Restorative instrumental for recovery.',
      'songs': [
        {'title': 'Healing Light', 'artist': 'Ambient Masters'},
        {'title': 'Recovery', 'artist': 'Therapeutic Sounds'},
        {'title': 'Inner Peace', 'artist': 'Zen Garden'},
        {'title': 'Renewal', 'artist': 'Wellness Vibes'},
        {'title': 'Transformation', 'artist': 'Healing Frequencies'},
        {'title': 'Mending', 'artist': 'Soulful Instruments'},
        {'title': 'Growth', 'artist': 'Inspirational Beats'},
        {'title': 'Rising', 'artist': 'Uplifting Sounds'},
        {'title': 'Wholeness', 'artist': 'Holistic Music'},
        {'title': 'Restoration', 'artist': 'Therapeutic Harmony'},
      ],
    },
    {
      'title': 'Instrumental Stressed',
      'mood': 'Stressed',
      'language': 'Instrumental',
      'icon': Icons.bolt_rounded,
      'color': AppColors.warmCoral,
      'description': 'Calming instrumental to ease anxiety.',
      'songs': [
        {'title': 'Release', 'artist': 'Ambient Therapy'},
        {'title': 'Breathe', 'artist': 'Mindful Sounds'},
        {'title': 'Let Go', 'artist': 'Stress Relief'},
        {'title': 'Serenity', 'artist': 'Peaceful Strings'},
        {'title': 'Unwind', 'artist': 'Relaxation Music'},
        {'title': 'Calm Waters', 'artist': 'Nature Sounds'},
        {'title': 'Soothe', 'artist': 'Therapeutic Waves'},
        {'title': 'Balance', 'artist': 'Equilibrium Sounds'},
        {'title': 'Quietude', 'artist': 'Silent Music'},
        {'title': 'Harmony', 'artist': 'Peaceful Ensemble'},
      ],
    },
    {
      'title': 'Instrumental Sleep',
      'mood': 'Sleep',
      'language': 'Instrumental',
      'icon': Icons.nightlight_outlined,
      'color': AppColors.softIndigo,
      'description': 'Restful instrumental for deep sleep.',
      'songs': [
        {'title': 'Dreamland', 'artist': 'Sleep Music'},
        {'title': 'Night Whispers', 'artist': 'Ambient Dreams'},
        {'title': 'Slumber', 'artist': 'Lullaby Sounds'},
        {'title': 'Twilight', 'artist': 'Night Soundscape'},
        {'title': 'Restful', 'artist': 'Sleep Therapy'},
        {'title': 'Nocturne', 'artist': 'Classical Sleep'},
        {'title': 'Dreamscape', 'artist': 'Night Music'},
        {'title': 'Drifting', 'artist': 'Sleep Frequencies'},
        {'title': 'Starlight Lullaby', 'artist': 'Bedtime Sounds'},
        {'title': 'Midnight Serenity', 'artist': 'Night Harmony'},
      ],
    },
  ];

  /// Get all unique languages available in playlists
  Set<String> get _availableLanguages =>
      _playlists.map((pl) => pl['language'] as String).toSet();

  /// Get unique moods for a specific language
  List<String> _getMoodsForLanguage(String language) {
    final moods = <String>{};
    for (final pl in _playlists) {
      if (pl['language'] == language) {
        moods.add(pl['mood'] as String);
      }
    }
    // Order moods: Happy, Calm, Healing, Focus, Stressed, Sleep
    const moodOrder = ['Happy', 'Calm', 'Healing', 'Focus', 'Stressed', 'Sleep'];
    return moods
        .where((m) => moodOrder.contains(m))
        .toList()
        .cast<String>();
  }

  /// Get playlists for a specific language and mood
  List<Map<String, dynamic>> _getPlaylistsForLanguageAndMood(
    String language,
    String mood,
  ) {
    return _playlists
        .where((pl) => pl['language'] == language && pl['mood'] == mood)
        .toList();
  }

  /// Count playlists for a language
  int _getPlaylistCountForLanguage(String language) {
    return _playlists.where((pl) => pl['language'] == language).length;
  }

  @override
  void initState() {
    super.initState();
    _recommendation = AppNavigationService().musicRecommendation.value;
    AppNavigationService().musicRecommendation.addListener(_onRecommendation);
    // Set initial language from user preferences or default to first available
    _initializeLanguage();
  }

  void _initializeLanguage() {
    if (_selectedLanguages.isNotEmpty) {
      _selectedLanguage = _selectedLanguages.first;
    } else if (_availableLanguages.isNotEmpty) {
      _selectedLanguage = _availableLanguages.first;
    }
  }

  @override
  void dispose() {
    AppNavigationService().musicRecommendation.removeListener(
      _onRecommendation,
    );
    super.dispose();
  }

  void _onRecommendation() {
    if (!mounted) return;
    setState(() {
      _recommendation = AppNavigationService().musicRecommendation.value;
    });
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
                  _selectedLanguage == null
                      ? 'Select your language to get started'
                      : 'Playlists curated for your mood in ${_selectedLanguage!}.',
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
                  'Select Language',
                  style: AppTypography.sectionHeading(color: Colors.white),
                ),
                const SizedBox(height: 12),
                _buildLanguageSelector(),
                if (_selectedLanguage != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'For Your Mood',
                    style: AppTypography.sectionHeading(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _buildMoodSection(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build language selector with chips showing playlist counts
  Widget _buildLanguageSelector() {
    final available = _availableLanguages.toList()..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...available.map((lang) {
            final isSelected = _selectedLanguage == lang;
            final count = _getPlaylistCountForLanguage(lang);
            return GestureDetector(
              onTap: () => setState(() => _selectedLanguage = lang),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.warmCoral.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.warmCoral.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang,
                      style: AppTypography.uiLabel(
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count playlists',
                      style: AppTypography.caption(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 300));
          }),
        ],
      ),
    );
  }

  /// Build mood section with all moods and their playlists for selected language
  Widget _buildMoodSection() {
    if (_selectedLanguage == null) return const SizedBox.shrink();

    final moods = _getMoodsForLanguage(_selectedLanguage!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...moods.map((mood) {
          final playlists = _getPlaylistsForLanguageAndMood(_selectedLanguage!, mood);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mood,
                style: AppTypography.uiLabel(color: Colors.white),
              ),
              const SizedBox(height: 8),
              ...playlists.map((pl) => _buildPlaylistCard(pl)),
              const SizedBox(height: 20),
            ],
          );
        }),
      ],
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
              child: Icon(playlist['icon'] as IconData, color: color, size: 24),
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
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
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
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
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
                    final title = Uri.encodeComponent(
                      playlist['title'] as String,
                    );
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
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusButton,
                      ),
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
