import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../features/profile/providers/profile_providers.dart';

class ChatBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically watch the sender's profile for the latest name and photo
    final profileAsync = ref.watch(userProfileProvider(message.senderId));

    return profileAsync.when(
      data: (profile) {
        final displayName = profile?.username ?? message.senderName;
        final photoUrl = profile?.photoUrl;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                _buildAvatar(photoUrl, displayName),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Sender Name
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Material Bubble
                    _buildMessageMaterial(context),

                    // Time Label
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Text(
                        DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(message.ts)),
                        style: const TextStyle(fontSize: 10, color: Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(), // Or a tiny placeholder
      error: (_, __) => _buildStaticBubble(context), // Fallback to current behavior
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
      child: photoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  Widget _buildMessageMaterial(BuildContext context) {
    return Material(
      elevation: 0.5,
      color: isMe ? const Color(0xFF2E7D32) : Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isMe ? 16 : 0),
        bottomRight: Radius.circular(isMe ? 0 : 16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply Preview
            if (message.replyToId != null)
              _buildReplyPreview(),

            // Photo
            if (message.photoUrl != null)
              _buildPhoto(),

            // Text
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replySenderName ?? 'Someone',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            message.replyPreview ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          message.photoUrl!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildStaticBubble(BuildContext context) {
    // Fallback if profile fails
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.senderName,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          _buildMessageMaterial(context),
        ],
      ),
    );
  }
}
