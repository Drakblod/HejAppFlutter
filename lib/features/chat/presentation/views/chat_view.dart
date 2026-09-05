import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
