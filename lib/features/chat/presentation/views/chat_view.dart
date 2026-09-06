import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../providers/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_composer.dart';
import '../../../../core/services/database_repository.dart';

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

  Future<void> _showPrivateChatPrompt(
    BuildContext context,
    ChatMessage message,
  ) async {
    final openChat = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PrivateChatPrompt(message: message),
    );

    if (openChat == true && context.mounted) {
      context.push('/direct/${message.senderId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.groupId));
    final currentUid = ref.watch(authRepositoryProvider).currentUser?.uid;

    // Listen for image upload errors
    ref.listen(chatControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send: $err'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    // Update lastReadTs when messages are loaded
    ref.listen(chatMessagesProvider(widget.groupId), (previous, next) {
      next.whenData((messages) {
        if (messages.isNotEmpty && currentUid != null) {
          ref
              .read(databaseRepositoryProvider)
              .updateLastRead(widget.groupId, currentUid, messages.last.ts);
        }
      });
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return ColoredBox(
          color: const Color(0xFFF4F6F3),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAF8),
                  border: isDesktop
                      ? const Border.symmetric(
                          vertical: BorderSide(color: Color(0xFFE1E7E1)),
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: messagesAsync.when(
                        data: (messages) {
                          if (messages.isEmpty) {
                            return const _EmptyChat();
                          }

                          final reversedMessages = messages.reversed.toList();

                          return ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              isDesktop ? 28 : 4,
                              24,
                              isDesktop ? 28 : 4,
                              18,
                            ),
                            itemCount: reversedMessages.length,
                            itemBuilder: (context, index) {
                              final msg = reversedMessages[index];
                              return ChatBubble(
                                message: msg,
                                isMe: msg.senderId == currentUid,
                                onSenderTap: msg.senderId == currentUid
                                    ? null
                                    : () =>
                                          _showPrivateChatPrompt(context, msg),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(
                          child: Text(
                            'Error: $err',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 28 : 12,
                        10,
                        isDesktop ? 28 : 12,
                        isDesktop ? 22 : 130,
                      ),
                      child: ChatComposer(groupId: widget.groupId),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrivateChatPrompt extends StatelessWidget {
  final ChatMessage message;

  const _PrivateChatPrompt({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFE4EEE5),
              backgroundImage: message.senderPhotoUrl != null
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              child: message.senderPhotoUrl == null
                  ? Text(
                      message.senderName.isEmpty
                          ? '?'
                          : message.senderName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF225C32),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 13),
            Text(
              message.senderName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start a private conversation outside the group chat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Message privately'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE4EEE5),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF225C32),
              size: 27,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 5),
          const Text(
            'Start the conversation with your group.',
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
