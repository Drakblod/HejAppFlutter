import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../features/profile/providers/profile_providers.dart';

class ChatBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onSenderTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onSenderTap,
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
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                Tooltip(
                  message: 'Message $displayName privately',
                  child: InkWell(
                    onTap: onSenderTap,
                    customBorder: const CircleBorder(),
                    child: _buildAvatar(photoUrl, displayName),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Sender Name
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: InkWell(
                          onTap: onSenderTap,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 1,
                            ),
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Material Bubble
                    _buildMessageMaterial(context),

                    // Time Label
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Text(
                        DateFormat('HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(message.ts),
                        ),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black38,
                        ),
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
      error: (_, __) =>
          _buildStaticBubble(context), // Fallback to current behavior
    );
  }

  Widget _buildAvatar(String? photoUrl, String name) {
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
      backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
      onBackgroundImageError: hasPhoto ? (_, _) {} : null,
      child: !hasPhoto
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
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
          maxWidth: MediaQuery.sizeOf(context).width >= 800
              ? 620
              : MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply Preview
            if (message.replyToId != null) _buildReplyPreview(),

            // Photo
            if (message.photoUrl != null && message.photoUrl!.trim().isNotEmpty)
              _buildPhoto(context),

            // Text
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 15.5,
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

  Widget _buildPhoto(BuildContext context) {
    final photoUrl = message.photoUrl!.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _openFullScreenPhoto(context, photoUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 340,
              maxWidth: 420,
            ),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    final total = loadingProgress.expectedTotalBytes;
                    final loaded = loadingProgress.cumulativeBytesLoaded;
                    return Container(
                      height: 180,
                      width: double.infinity,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.04),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: total != null && total > 0 ? loaded / total : null,
                          strokeWidth: 2,
                          color: isMe ? Colors.white70 : const Color(0xFF225C32),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: isMe ? Colors.white70 : Colors.black54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'View image',
                          style: TextStyle(
                            fontSize: 13,
                            color: isMe ? Colors.white : const Color(0xFF225C32),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreenPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          actions: [
            IconButton(
              tooltip: 'Open in new tab',
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
              onPressed: () async {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image_outlined, color: Colors.white60, size: 64),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open image in browser'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticBubble(BuildContext context) {
    // Fallback if profile fails
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
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
