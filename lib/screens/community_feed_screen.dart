import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../services/user_preferences_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/doodle_refresh.dart';
import 'create_post_screen.dart';
import 'comments_sheet.dart';
import 'community_chat_screen.dart';

/// Community Feed — Instagram-style calm social feed.
class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final CommunityService _service = CommunityService();
  final Map<String, bool> _showHeart = {};
  String _selectedFilter = 'All';
  static const List<String> _filters = [
    'All',
    'Achievements',
    'Heartbreak',
    'Struggles',
    'Victories',
  ];

  List<Post> get _filteredPosts {
    if (_selectedFilter == 'All') return _service.posts;
    return _service.posts.where((p) => p.postType == _selectedFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _service.communityPreference = UserPreferencesService().communityPreference;
    _service.addListener(_onServiceUpdate);
    _service.subscribeToRealtime();
    _loadFeed();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFeed() async {
    await _service.loadPosts();
    if (mounted) setState(() {});
  }

  Future<void> _onDoubleTap(Post post) async {
    if (!post.isLiked) {
      setState(() {
        _showHeart[post.id] = true;
      });
      await _service.toggleLike(post.id);
      if (!mounted) return;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showHeart[post.id] = false);
      });
    }
  }

  Future<void> _openComments(Post post) async {
    final comments = await _service.loadComments(post.id);
    if (comments.isNotEmpty) {
      post.comments
        ..clear()
        ..addAll(comments);
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentsSheet(post: post, onCommentAdded: () => setState(() {})),
    );
  }

  void _openCreatePost() async {
    if (!_service.canPost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Community posting is disabled. You can enable it in settings.',
            style: AppTypography.body(color: Colors.white),
          ),
          backgroundColor: AppColors.softIndigo,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, a1, a2) => const CreatePostScreen(),
        transitionsBuilder: (context, animation, a2, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppTheme.gentleCurve,
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: AppTheme.gentleCurve,
                    ),
                  ),
              child: child,
            ),
          );
        },
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.bgGradient(context),
      secondaryColors: AppColors.bgGradientAlt(context),
      child: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ───
            _buildTopBar(),

            // ─── Filter Chips ───
            _buildFilterChips(),

            // ─── Moderation Banner ───
            _buildModerationBanner(),

            // ─── Feed ───
            Expanded(
              child: DoodleRefresh(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredPosts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(_filteredPosts[index], index);
                  },
                ),
              ),
            ),
          ],
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
          Text('Community', style: AppTypography.sectionHeadingC(context)),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 400),
                      pageBuilder: (context, a1, a2) =>
                          const CommunityChatScreen(),
                      transitionsBuilder: (context, animation, a2, child) {
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
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.softIndigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.softIndigo,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openCreatePost,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.softIndigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.softIndigo,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isSelected = _selectedFilter == _filters[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[i]),
            child: AnimatedContainer(
              duration: AppTheme.fadeInDuration,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.softIndigo.withValues(alpha: 0.15)
                    : AppColors.card(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                border: Border.all(
                  color: isSelected
                      ? AppColors.softIndigo.withValues(alpha: 0.4)
                      : AppColors.dividerColor(context),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _filters[i],
                  style:
                      AppTypography.caption(
                        color: isSelected
                            ? AppColors.softIndigo
                            : AppColors.secondary(context),
                      ).copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.w300,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModerationBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sageGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppColors.sageGreen.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite_outline_rounded,
            color: AppColors.sageGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This space is for kindness and support.',
              style: AppTypography.caption(color: AppColors.sageGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post, int index) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppColors.cardBorder(context), width: 0.8),
          boxShadow: AppColors.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Post Header (avatar, username, timestamp) ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  _buildAvatar(post.avatar, 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: AppTypography.uiLabelC(
                            context,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _service.formatTimeAgo(post.timestamp),
                          style: AppTypography.captionC(context),
                        ),
                      ],
                    ),
                  ),
                  if (post.moodTag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softIndigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusButton,
                        ),
                      ),
                      child: Text(
                        post.moodTag!,
                        style: AppTypography.caption(
                          color: AppColors.softIndigo,
                        ).copyWith(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),

            // ─── Post Image (if exists) ───
            if (post.imagePath != null)
              GestureDetector(
                onDoubleTap: () => _onDoubleTap(post),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: _buildPostImage(post.imagePath!),
                    ),
                    // Heart animation on double tap
                    if (_showHeart[post.id] == true)
                      const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.warmCoral,
                            size: 64,
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.2, 1.2),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                          )
                          .fadeOut(
                            delay: const Duration(milliseconds: 400),
                            duration: const Duration(milliseconds: 300),
                          ),
                  ],
                ),
              ),

            // ─── Caption ───
            GestureDetector(
              onDoubleTap: () => _onDoubleTap(post),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      post.imagePath != null ? 12 : 0,
                      16,
                      4,
                    ),
                    child: Text(
                      post.caption,
                      style: AppTypography.journalBodyC(context),
                    ),
                  ),
                  // Heart animation on double tap (for text-only posts)
                  if (post.imagePath == null && _showHeart[post.id] == true)
                    const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.warmCoral,
                          size: 56,
                        )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.2, 1.2),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                        )
                        .fadeOut(
                          delay: const Duration(milliseconds: 400),
                          duration: const Duration(milliseconds: 300),
                        ),
                ],
              ),
            ),

            // ─── Action Row (like, comment, share) ───
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  // Like
                  _buildActionButton(
                    icon: post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    color: post.isLiked
                        ? AppColors.warmCoral
                        : AppColors.tertiary(context),
                    label: post.likesCount > 0 ? '${post.likesCount}' : '',
                    onTap: () {
                      _service.toggleLike(post.id).then((_) {
                        if (mounted) setState(() {});
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 4),
                  // Comment
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: AppColors.tertiary(context),
                    label: post.comments.isNotEmpty
                        ? '${post.comments.length}'
                        : '',
                    onTap: () => _openComments(post),
                  ),
                  const SizedBox(width: 4),
                  // Share
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    color: AppColors.tertiary(context),
                    label: '',
                    onTap: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: '${post.caption}\n\n— shared from Unravel',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: double.infinity,
            height: 240,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 240,
      color: AppColors.dividerColor(context).withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.tertiary(context),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: AppTypography.caption(color: color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.softIndigo.withValues(alpha: 0.2),
            AppColors.paleLilac.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(color: AppColors.frostedBorder(context), width: 1.5),
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: AppTypography.uiLabel(
            color: AppColors.softIndigo,
          ).copyWith(fontSize: size * 0.38, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
