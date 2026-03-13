import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/gradient_background.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/appwrite_service.dart';
import '../services/appwrite_constants.dart';

/// Community Chat — real-time group chat backed by Appwrite.
class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = true;
  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final result = await DatabaseService().getChatMessages(limit: 50);
      if (!mounted) return;
      final currentUserId = AuthService().currentUser?.$id;

      setState(() {
        _messages.clear();
        // Reverse because query returns newest first
        for (final doc in result.documents.reversed) {
          final d = doc.data;
          _messages.add(_ChatMessage(
            id: doc.$id,
            username: d['username'] ?? '',
            avatar: d['avatar'] ?? '',
            text: d['text'] ?? '',
            isMe: d['userId'] == currentUserId,
          ));
        }
        _isLoading = false;
      });

      // If no backend messages, load sample data
      if (_messages.isEmpty) {
        _loadSampleMessages();
      }

      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      _loadSampleMessages();
      setState(() => _isLoading = false);
    }
  }

  void _loadSampleMessages() {
    _messages.addAll([
      _ChatMessage(id: '1', username: 'gentle_soul', avatar: 'G', text: 'Hey everyone, how are you doing today?', isMe: false),
      _ChatMessage(id: '2', username: 'quiet_river', avatar: 'Q', text: 'Taking it one breath at a time.', isMe: false),
      _ChatMessage(id: '3', username: 'morning_dew', avatar: 'M', text: 'Sending love to anyone who needs it right now.', isMe: false),
      _ChatMessage(id: '4', username: 'warm_light', avatar: 'W', text: 'Just finished a 10-minute meditation. Feeling lighter.', isMe: false),
    ]);
  }

  void _subscribeToRealtime() {
    try {
      final channel =
          'databases.${AppwriteConstants.databaseId}.collections.${AppwriteConstants.chatMessagesCollection}.documents';
      final subscription = AppwriteService().realtime.subscribe([channel]);
      _realtimeSub = subscription.stream.listen((event) {
        if (!mounted) return;
        if (event.events.any((e) => e.contains('.create'))) {
          final d = event.payload;
          final currentUserId = AuthService().currentUser?.$id;
          // Don't duplicate if we just sent it
          if (d['userId'] == currentUserId) return;

          setState(() {
            _messages.add(_ChatMessage(
              id: d['\$id'] ?? '',
              username: d['username'] ?? '',
              avatar: d['avatar'] ?? '',
              text: d['text'] ?? '',
              isMe: false,
            ));
          });
          _scrollToBottom();
        }
      });
    } catch (_) {
      // Realtime not available — chat still works without live updates
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = AuthService().currentUser;
    final username = user?.name.isNotEmpty == true ? user!.name : 'you';
    final avatar = username.isNotEmpty ? username[0].toUpperCase() : 'Y';

    // Add locally immediately
    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add(_ChatMessage(
        id: localId,
        username: username,
        avatar: avatar,
        text: text,
        isMe: true,
      ));
      _messageController.clear();
    });
    _scrollToBottom();

    // Persist to backend
    if (user != null) {
      try {
        await DatabaseService().sendChatMessage(
          userId: user.$id,
          username: username,
          avatar: avatar,
          text: text,
        );
      } catch (_) {
        // Message still shown locally
      }
    }
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 1.5))
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
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
                Text(
                  '${_messages.map((m) => m.username).toSet().length} people here',
                  style: AppTypography.captionC(context),
                ),
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
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  message.username,
                  style: AppTypography.caption(color: AppColors.softIndigo)
                      .copyWith(fontSize: 11),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          delay: Duration(milliseconds: index < 10 ? index * 60 : 0),
          duration: const Duration(milliseconds: 400),
          curve: AppTheme.gentleCurve,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          delay: Duration(milliseconds: index < 10 ? index * 60 : 0),
          duration: const Duration(milliseconds: 400),
          curve: AppTheme.gentleCurve,
        );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(
          top: BorderSide(
            color: AppColors.dividerColor(context),
            width: 0.8,
          ),
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
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
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
  final String id;
  final String username;
  final String avatar;
  final String text;
  final bool isMe;

  _ChatMessage({
    required this.id,
    required this.username,
    required this.avatar,
    required this.text,
    required this.isMe,
  });
}
