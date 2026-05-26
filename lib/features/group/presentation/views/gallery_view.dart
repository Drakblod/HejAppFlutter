import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/gallery_providers.dart';
import '../../providers/board_providers.dart';
import '../../../../core/models/gallery_item.dart';
import '../../../../features/auth/data/auth_repository.dart';

class GalleryView extends ConsumerWidget {
  final String groupId;

  const GalleryView({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryItemsAsync = ref.watch(galleryItemsProvider(groupId));
    final groupAsync = ref.watch(groupMetaProvider(groupId));
    final currentUser = ref.watch(authRepositoryProvider).currentUser;

    ref.listen(galleryControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $err'), backgroundColor: Colors.red),
          );
        },
      );
    });

    return Container(
      color: const Color(0xFFF5F5F5),
      child: groupAsync.when(
        data: (group) {
          if (group == null) return const Center(child: Text('Group not found'));
          final baseColorVal = int.tryParse(group.baseColor) ?? 0xFF2E7D32;
          final baseColor = Color(baseColorVal);

          return galleryItemsAsync.when(
            data: (items) {
              final isOwner = group.ownerId == currentUser?.uid;

              return Stack(
                children: [
                  if (items.isEmpty)
                    _buildEmptyState(context, ref, baseColor, group.fontFamily)
                  else
                    RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(galleryItemsProvider(groupId));
                        ref.invalidate(groupMetaProvider(groupId));
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        child: MasonryGridView.count(
                          physics: const AlwaysScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isUploader = item.uploaderId == currentUser?.uid;
                            final canDelete = isOwner || isUploader;

                            return _buildGalleryCard(
                              context,
                              ref,
                              item,
                              canDelete,
                              baseColor,
                              group.fontFamily,
                            );
                          },
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 140,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: () => _showUploadSheet(context, ref, baseColor, group.fontFamily),
                      backgroundColor: baseColor,
                      icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                      label: Text(
                        'ADD PHOTO',
                        style: GoogleFonts.getFont(
                          group.fontFamily ?? 'Outfit',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading gallery: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Error loading group context')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Color baseColor, String? fontFamily) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No photos yet',
              style: GoogleFonts.getFont(
                fontFamily ?? 'Outfit',
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture and share memorable moments!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showUploadSheet(context, ref, baseColor, fontFamily),
              icon: const Icon(Icons.add_a_photo, color: Colors.white),
              label: const Text('Upload Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: baseColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCard(
    BuildContext context,
    WidgetRef ref,
    GalleryItem item,
    bool canDelete,
    Color baseColor,
    String? fontFamily,
  ) {
    return GestureDetector(
      onTap: () => _openFullScreenView(context, item, canDelete, ref),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey.shade100,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                if (item.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                    child: Text(
                      item.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(10, item.caption.isNotEmpty ? 0 : 8, 10, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: baseColor.withValues(alpha: 0.1),
                        child: Text(
                          item.uploaderName.isNotEmpty ? item.uploaderName[0].toUpperCase() : 'M',
                          style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: baseColor),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.uploaderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canDelete)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _confirmDelete(context, ref, item),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenView(BuildContext context, GalleryItem item, bool canDelete, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 26),
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, item);
                },
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.caption.isNotEmpty ? item.caption : 'No caption',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Shared by ${item.uploaderName}',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(item.createdAt)),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUploadSheet(BuildContext context, WidgetRef ref, Color baseColor, String? fontFamily) {
    Uint8List? selectedImageBytes;
    String? selectedFileName;
    final captionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isUploading = ref.watch(galleryControllerProvider).isLoading;

          Future<void> pickPhoto() async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
            if (pickedFile != null) {
              final bytes = await pickedFile.readAsBytes();
              setModalState(() {
                selectedImageBytes = bytes;
                selectedFileName = pickedFile.name;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Post a Photo',
                      style: GoogleFonts.getFont(
                        fontFamily ?? 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Image Picker Area
                    GestureDetector(
                      onTap: isUploading ? null : pickPhoto,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: selectedImageBytes != null
                            ? Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.memory(selectedImageBytes!, fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedImageBytes = null;
                                          selectedFileName = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade500),
                                  const SizedBox(height: 8),
                                  Text('Tap to select photo', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: captionController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        labelText: 'Caption / Description',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: baseColor, width: 2),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a caption' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isUploading || selectedImageBytes == null
                          ? null
                          : () async {
                              if (formKey.currentState!.validate() && selectedImageBytes != null) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Uploading photo...')),
                                );
                                await ref.read(galleryControllerProvider.notifier).uploadPhoto(
                                      groupId: groupId,
                                      bytes: selectedImageBytes!,
                                      fileName: selectedFileName ?? 'image.jpg',
                                      caption: captionController.text.trim(),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: baseColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'UPLOAD',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).then((_) {
      captionController.dispose();
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, GalleryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to permanently remove this photo from the gallery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(galleryControllerProvider.notifier).deletePhoto(
                    groupId: groupId,
                    itemId: item.id,
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
