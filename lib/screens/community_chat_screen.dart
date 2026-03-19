import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';

/// Minimal community chat UI shell with sample messages.
class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    CommunityService().addListener(_onCommunityUpdate);
    _loadMessages();
  }

  void _onCommunityUpdate() {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final user = AuthService().currentUser;
    final currentUserId = user?.$id ?? '';

    final result = await DatabaseService().getComments('GLOBAL_CHAT');
    final loaded = result.rows.map((doc) {
      final d = doc.data;
      final userId = d['userId'] as String? ?? '';
      return _ChatMessage(
        (d['username'] as String?) ?? 'Someone',
        (d['avatar'] as String?) ?? 'S',
        (d['text'] as String?) ?? '',
        userId == currentUserId,
      );
    }).toList();

    // Sort oldest first (top-down) or adjust depending on UI list view
    loaded.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(loaded);
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = AuthService().currentUser;
    if (user == null) return;

    final username = user.name.isNotEmpty ? user.name : 'you';
    final avatar = username.isNotEmpty ? username[0].toUpperCase() : 'Y';

    _messageController.clear();

    await DatabaseService().addComment(
      postId: 'GLOBAL_CHAT',
      userId: user.$id,
      username: username,
      avatar: avatar,
      text: text,
    );
    _loadMessages();
  }

  @override
  void dispose() {
    CommunityService().removeListener(_onCommunityUpdate);
    _messageController.dispose();
    super.dispose();
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
              _buildTopBar(),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    return _buildBubble(_messages[index], index);
                  },
                ),
              ),
              _buildInputBar(),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Community Chat', style: AppTypography.uiLabelC(context)),
                Text('4 people here', style: AppTypography.captionC(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage message, int index) {
    final isMe = message.isMe;
    return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.username,
                      style: AppTypography.caption(
                        color: AppColors.softIndigo,
                      ).copyWith(fontSize: 11),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.softIndigo.withValues(alpha: 0.15)
                        : AppColors.card(context),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: Border.all(
                      color: isMe
                          ? AppColors.softIndigo.withValues(alpha: 0.2)
                          : AppColors.dividerColor(context),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: AppTypography.bodyC(context),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: index * 60),
          duration: const Duration(milliseconds: 400),
          curve: AppTheme.gentleCurve,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          delay: Duration(milliseconds: index * 60),
          duration: const Duration(milliseconds: 400),
          curve: AppTheme.gentleCurve,
        );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(
            color: AppColors.dividerColor(context),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.tertiary(context),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeOut(
                  delay: Duration(milliseconds: i * 200),
                  duration: const Duration(milliseconds: 500),
                );
          }),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(
          top: BorderSide(color: AppColors.dividerColor(context), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                border: Border.all(
                  color: AppColors.dividerColor(context),
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: AppTypography.bodyC(context),
                decoration: InputDecoration(
                  hintText: 'Say something kind...',
                  hintStyle: AppTypography.body(
                    color: AppColors.tertiary(context),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.softIndigo.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String username;
  final String avatar;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  _ChatMessage(
    this.username,
    this.avatar,
    this.text,
    this.isMe, {
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
