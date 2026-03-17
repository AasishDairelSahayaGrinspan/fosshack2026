import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../services/community_service.dart';

/// Create Post Screen — add caption, optional mood tag, and post.
/// Camera/gallery integration placeholder (image_picker to be added later).
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocus = FocusNode();
  final CommunityService _service = CommunityService();
  int _selectedMoodTag = -1;
  bool _isPosting = false;
  String? _imagePath;
  bool _hasShownCameraInfo = false;
  bool _hasShownGalleryInfo = false;

  static const List<Map<String, dynamic>> _moodTags = [
    {'label': 'Grateful', 'color': AppColors.sageGreen},
    {'label': 'Healing', 'color': AppColors.softIndigo},
    {'label': 'Struggling', 'color': AppColors.warmCoral},
    {'label': 'Progress', 'color': AppColors.orangeE2814d},
  ];

  Future<bool> _showAccessInfo({
    required String source,
    required String message,
  }) async {
    final shouldShow = source == 'camera'
        ? !_hasShownCameraInfo
        : !_hasShownGalleryInfo;
    if (!shouldShow) return true;

    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text('Permission needed', style: AppTypography.uiLabelC(context)),
        content: Text(message, style: AppTypography.bodyC(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Not now',
              style: AppTypography.caption(color: AppColors.tertiary(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Continue',
              style: AppTypography.caption(color: AppColors.softIndigo),
            ),
          ),
        ],
      ),
    );

    if (source == 'camera') {
      _hasShownCameraInfo = allow == true;
    } else {
      _hasShownGalleryInfo = allow == true;
    }
    return allow == true;
  }

  Future<void> _selectImage(String source) async {
    final allowed = await _showAccessInfo(
      source: source,
      message: source == 'camera'
          ? 'Unravel needs access to your camera so you can share moments with the community.'
          : 'Unravel needs access to your gallery so you can share moments with the community.',
    );
    if (!allowed) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _imagePath = image.path);
    }
  }

  Future<void> _submitPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) return;

    setState(() => _isPosting = true);

    // Simulate posting delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      await _service.addPost(
        caption: caption,
        imagePath: _imagePath,
        moodTag: _selectedMoodTag >= 0
            ? _moodTags[_selectedMoodTag]['label'] as String
            : null,
      );
    } catch (e, st) {
      developer.log('Failed to create post', name: 'CreatePostScreen', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not post right now. Please try again.',
              style: AppTypography.body(color: Colors.white),
            ),
            backgroundColor: AppColors.warmCoral,
          ),
        );
      }
      setState(() => _isPosting = false);
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // ─── Top Bar ───
              _buildTopBar(),

              // ─── Content ───
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Text(
                        'Share a moment',
                        style: AppTypography.heroHeadingC(context),
                      )
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 500),
                            curve: AppTheme.gentleCurve,
                          ),

                      const SizedBox(height: 4),
                      Text(
                        'Your words matter here.',
                        style: AppTypography.subtitleC(context),
                      )
                          .animate()
                          .fadeIn(
                            duration: const Duration(milliseconds: 500),
                            curve: AppTheme.gentleCurve,
                          ),

                      const SizedBox(height: 24),

                      // ─── Image Picker Area ───
                      _buildImagePicker()
                          .animate(delay: const Duration(milliseconds: 150))
                          .fadeIn(
                            duration: const Duration(milliseconds: 400),
                            curve: AppTheme.gentleCurve,
                          ),

                      const SizedBox(height: 20),

                      // ─── Caption Field ───
                      _buildCaptionField()
                          .animate(delay: const Duration(milliseconds: 250))
                          .fadeIn(
                            duration: const Duration(milliseconds: 400),
                            curve: AppTheme.gentleCurve,
                          ),

                      const SizedBox(height: 20),

                      // ─── Mood Tags ───
                      _buildMoodTags()
                          .animate(delay: const Duration(milliseconds: 350))
                          .fadeIn(
                            duration: const Duration(milliseconds: 400),
                            curve: AppTheme.gentleCurve,
                          ),

                      const SizedBox(height: 32),

                      // ─── Post Button ───
                      _buildPostButton()
                          .animate(delay: const Duration(milliseconds: 400))
                          .fadeIn(
                            duration: const Duration(milliseconds: 400),
                            curve: AppTheme.gentleCurve,
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
                Icons.close_rounded,
                color: AppColors.secondary(context),
                size: 20,
              ),
            ),
          ),
          Text('New Post', style: AppTypography.uiLabelC(context)),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_imagePath != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: AppColors.softIndigo.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: Image.file(
                File(_imagePath!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _imagePath = null),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.secondary(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectImage('gallery'),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(
                  color: AppColors.dividerColor(context),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.softIndigo.withValues(alpha: 0.6),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gallery',
                    style: AppTypography.caption(color: AppColors.secondary(context)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectImage('camera'),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(
                  color: AppColors.dividerColor(context),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.warmCoral.withValues(alpha: 0.6),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Camera',
                    style: AppTypography.caption(color: AppColors.secondary(context)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
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
        controller: _captionController,
        focusNode: _captionFocus,
        maxLines: null,
        minLines: 4,
        style: AppTypography.journalBodyC(context),
        decoration: InputDecoration(
          hintText: 'What\'s on your mind today?',
          hintStyle: AppTypography.journalBody(
            color: AppColors.tertiary(context).withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildMoodTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add a mood tag',
          style: AppTypography.uiLabel(color: AppColors.secondary(context)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_moodTags.length, (i) {
            final isSelected = _selectedMoodTag == i;
            final color = _moodTags[i]['color'] as Color;
            return GestureDetector(
              onTap: () => setState(
                () => _selectedMoodTag = isSelected ? -1 : i,
              ),
              child: AnimatedContainer(
                duration: AppTheme.fadeInDuration,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : AppColors.card(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.5)
                        : AppColors.dividerColor(context),
                    width: 1,
                  ),
                ),
                child: Text(
                  _moodTags[i]['label'] as String,
                  style: AppTypography.caption(
                    color: isSelected ? color : AppColors.secondary(context),
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPostButton() {
    final hasContent = _captionController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: hasContent && !_isPosting ? _submitPost : null,
      child: AnimatedContainer(
        duration: AppTheme.fadeInDuration,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: hasContent
              ? AppColors.softIndigo.withValues(alpha: 0.85)
              : AppColors.dividerColor(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          boxShadow: hasContent
              ? [
                  BoxShadow(
                    color: AppColors.softIndigo.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isPosting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                )
              : Text(
                  'Post',
                  style: AppTypography.buttonText(
                    color: hasContent
                        ? Colors.white
                        : AppColors.tertiary(context),
                  ),
                ),
        ),
      ),
    );
  }
}
