import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers/community_provider.dart';
import '../widgets/friend_mood_card.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(communityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite',
            onPressed: () => context.push('/community/invite'),
          ),
        ],
      ),
      body: friends.when(
        data: (friendList) {
          if (friendList.isEmpty) {
            return const Center(
              child: Text(
                'No friends yet.\nTap + to invite someone!',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: friendList.length,
            itemBuilder: (context, index) {
              return FriendMoodCard(friend: friendList[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
