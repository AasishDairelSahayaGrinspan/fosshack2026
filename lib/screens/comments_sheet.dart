import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';

/// Comments bottom sheet — slide-up modal with comment list and input.
class CommentsSheet extends StatefulWidget {
  final Post post;
  final VoidCallback onCommentAdded;

  const CommentsSheet({
    super.key,
    required this.post,
    required this.onCommentAdded,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CommunityService _service = CommunityService();

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _service.addComment(widget.post.id, text);
    if (!mounted) return;
    setState(() => _controller.clear());
    widget.onCommentAdded();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Handle ───
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ─── Header ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text('Comments', style: AppTypography.sectionHeadingC(context)),
                const SizedBox(width: 8),
                Text(
                  '${widget.post.comments.length}',
                  style: AppTypography.captionC(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.dividerColor(context)),

          // ─── Comments List ───
          Flexible(
            child: widget.post.comments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.post.comments.length,
                    itemBuilder: (context, index) {
                      return _buildComment(widget.post.comments[index], index);
                    },
                  ),
          ),

          // ─── Input Field ───
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8 + bottomInset),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              border: Border(
                top: BorderSide(color: AppColors.dividerColor(context), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.softIndigo.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Text(
                      'Y',
                      style: AppTypography.caption(color: AppColors.softIndigo)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: AppTypography.bodyC(context),
                    decoration: InputDecoration(
                      hintText: 'Write something kind...',
                      hintStyle: AppTypography.body(
                        color: AppColors.tertiary(context).withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.softIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: AppColors.softIndigo,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.tertiary(context).withValues(alpha: 0.4),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            'Be the first to share kindness.',
            style: AppTypography.subtitleC(context),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Comment comment, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.softIndigo.withValues(alpha: 0.15),
                  AppColors.paleLilac.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Center(
              child: Text(
                comment.avatar.toUpperCase(),
                style: AppTypography.caption(color: AppColors.softIndigo)
                    .copyWith(fontWeight: FontWeight.w500, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: AppTypography.captionC(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _service.formatTimeAgo(comment.timestamp),
                      style: AppTypography.captionC(context).copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.text,
                  style: AppTypography.bodyC(context),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * 60),
          duration: const Duration(milliseconds: 300),
          curve: AppTheme.gentleCurve,
        );
  }
}
