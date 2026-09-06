import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_repository.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../profile/providers/profile_providers.dart';
import '../../providers/chat_providers.dart';
import '../widgets/chat_bubble.dart';

class DirectChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;

  const DirectChatScreen({super.key, required this.otherUserId});

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    final user = ref.read(authRepositoryProvider).currentUser;
    if (text.isEmpty || user == null || _isSending) return;

    final profile = ref.read(currentUserProfileProvider).value;
    _textController.clear();
    setState(() => _isSending = true);

    try {
      await ref
          .read(databaseRepositoryProvider)
          .sendDirectMessage(
            senderId: user.uid,
            recipientId: widget.otherUserId,
            senderName: profile?.fullName.isNotEmpty == true
                ? profile!.fullName
                : profile?.username.isNotEmpty == true
                ? profile!.username
                : user.displayName ?? 'User',
            senderPhotoUrl: profile?.photoUrl ?? user.photoURL,
            text: text,
          );
    } catch (error) {
      if (mounted) {
        _textController.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send message: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    if (currentUser.uid == widget.otherUserId) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: _goBack)),
        body: const Center(
          child: Text('You cannot start a private chat with yourself.'),
        ),
      );
    }

    final participant = DirectChatParticipants(
      currentUid: currentUser.uid,
      otherUid: widget.otherUserId,
    );
    final messagesAsync = ref.watch(directChatMessagesProvider(participant));
    final otherProfileAsync = ref.watch(
      userProfileProvider(widget.otherUserId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 4,
        title: otherProfileAsync.when(
          data: (profile) => Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE4EEE5),
                backgroundImage: profile?.photoUrl != null
                    ? NetworkImage(profile!.photoUrl!)
                    : null,
                child: profile?.photoUrl == null
                    ? Text(
                        _initialFor(profile?.fullName, profile?.username),
                        style: const TextStyle(
                          color: Color(0xFF225C32),
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(profile?.fullName, profile?.username),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Private conversation',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Text('Private conversation'),
          error: (_, _) => const Text('Private conversation'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
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
                            return _DirectChatEmptyState(
                              name: otherProfileAsync.value?.fullName,
                            );
                          }

                          final reversedMessages = messages.reversed.toList();
                          return ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 28 : 8,
                              vertical: 20,
                            ),
                            itemCount: reversedMessages.length,
                            itemBuilder: (context, index) {
                              final message = reversedMessages[index];
                              return ChatBubble(
                                message: message,
                                isMe: message.senderId == currentUser.uid,
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Center(
                          child: Text('Could not load conversation: $error'),
                        ),
                      ),
                    ),
                    _DirectMessageComposer(
                      controller: _textController,
                      isSending: _isSending,
                      onSend: _sendMessage,
                      horizontalPadding: isDesktop ? 28 : 12,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _displayName(String? fullName, String? username) {
    if (fullName != null && fullName.trim().isNotEmpty) return fullName;
    if (username != null && username.trim().isNotEmpty) return username;
    return 'Member';
  }

  String _initialFor(String? fullName, String? username) {
    return _displayName(fullName, username)[0].toUpperCase();
  }
}

class _DirectChatEmptyState extends StatelessWidget {
  final String? name;

  const _DirectChatEmptyState({this.name});

  @override
  Widget build(BuildContext context) {
    final displayName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : 'this member';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFE4EEE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF225C32),
                size: 28,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              'Start a conversation with $displayName',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Messages here are separate from the group chat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectMessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final double horizontalPadding;

  const _DirectMessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        10,
        horizontalPadding,
        22,
      ),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE4DC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF758077),
                size: 19,
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Write a private message...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 13,
                  ),
                ),
              ),
            ),
            IconButton.filled(
              tooltip: 'Send message',
              onPressed: isSending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF225C32),
                foregroundColor: Colors.white,
              ),
              icon: isSending
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_upward_rounded, size: 21),
            ),
          ],
        ),
      ),
    );
  }
}
