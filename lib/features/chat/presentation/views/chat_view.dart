import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../providers/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_composer.dart';

class ChatView extends ConsumerStatefulWidget {
  final String groupId;

  const ChatView({super.key, required this.groupId});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.groupId));
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.uid;

    return Column(
      children: [
        // Messages List
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(child: Text('No messages yet', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)));
              }

              // Reverse list and use 'reverse: true' for stick-to-bottom behavior
              final reversedMessages = messages.reversed.toList();

              return ListView.builder(
                reverse: true,
                controller: _scrollController,
                itemCount: reversedMessages.length,
                itemBuilder: (context, index) {
                  final msg = reversedMessages[index];
                  return ChatBubble(
                    message: msg,
                    isMe: msg.senderId == currentUid,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          ),
        ),

        // Composer
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100), // Added bottom padding to sit above bar
          child: ChatComposer(groupId: widget.groupId),
        ),
      ],
    );
  }
}
