import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/files_providers.dart';
import '../../providers/board_providers.dart';
import '../../../../core/models/shared_file.dart';

class FilesView extends ConsumerWidget {
  final String groupId;

  const FilesView({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(sharedFilesProvider(groupId));

    // Listen for upload errors
    ref.listen(filesControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $err'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Container(
      color: const Color(0xFFF5F5F5),
      child: filesAsync.when(
        data: (files) {
          if (files.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sharedFilesProvider(groupId));
              ref.invalidate(groupMetaProvider(groupId));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Stack(
              children: [
                ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    return _buildFileCard(context, files[index]);
                  },
                ),
              Positioned(
                bottom: 140,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => ref.read(filesControllerProvider.notifier).pickAndUploadFile(groupId),
                  backgroundColor: const Color(0xFF2E7D32),
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: const Text('UPLOAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          debugPrint('FilesView error: $err');
          debugPrint('Stacktrace: $stack');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error loading files: $err', textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(sharedFilesProvider(groupId)),
                  child: const Text('RETRY'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No files shared yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(filesControllerProvider.notifier).pickAndUploadFile(groupId),
            icon: const Icon(Icons.upload),
            label: const Text('Upload first file'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, SharedFile file) {
    final dateStr = DateFormat('MMM d, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(file.ts));
    final sizeStr = _formatBytes(file.size);
    final icon = _getFileIcon(file.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          // Future: Open file URL
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sizeStr • By ${file.senderName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png': return Icons.image;
      case 'doc':
      case 'docx': return Icons.description;
      case 'xls':
      case 'xlsx': return Icons.table_chart;
      case 'mp4':
      case 'mov': return Icons.video_file;
      default: return Icons.insert_drive_file;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }
}
