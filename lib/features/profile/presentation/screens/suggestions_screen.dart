import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../group/providers/suggestions_providers.dart';
import '../../providers/profile_providers.dart';
import '../../../../core/models/suggestion.dart';
import '../../../auth/data/auth_repository.dart';

class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(suggestionsProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final isAdmin = profileAsync.value?.isAdmin ?? false;

    ref.listen(suggestionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Operation failed: $err'), backgroundColor: Colors.red),
          );
        },
      );
    });

    const baseColor = Color(0xFF1565C0); // Professional blue for global app features

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Suggestion Box',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: suggestionsAsync.when(
        data: (suggestions) {
          return Stack(
            children: [
              if (suggestions.isEmpty)
                _buildEmptyState(context, ref, baseColor)
              else
                RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(suggestionsProvider);
                    ref.invalidate(currentUserProfileProvider);
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      final isAuthor = suggestion.authorId == currentUser?.uid;
                      final canDelete = isAdmin || isAuthor;

                      return _buildSuggestionCard(
                        context,
                        ref,
                        suggestion,
                        isAdmin,
                        canDelete,
                        baseColor,
                      );
                    },
                  ),
                ),
              Positioned(
                bottom: 30,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddSuggestionSheet(context, ref, baseColor),
                  backgroundColor: baseColor,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'NEW IDEA',
                    style: GoogleFonts.outfit(
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
        error: (err, stack) => Center(child: Text('Error loading suggestions: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Color baseColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No suggestions yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your brilliant ideas or bugs with the developer!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddSuggestionSheet(context, ref, baseColor),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Suggestion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildSuggestionCard(
    BuildContext context,
    WidgetRef ref,
    Suggestion suggestion,
    bool isAdmin,
    bool canDelete,
    Color baseColor,
  ) {
    final dateStr = DateFormat('MMM d, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(suggestion.createdAt));
    
    // Status Badge Details
    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    
    switch (suggestion.status) {
      case 'in_progress':
        badgeBg = Colors.blue.shade50;
        badgeText = Colors.blue.shade700;
        badgeLabel = 'In the Works';
        break;
      case 'done':
        badgeBg = Colors.green.shade50;
        badgeText = Colors.green.shade700;
        badgeLabel = 'Completed';
        break;
      case 'new':
      default:
        badgeBg = Colors.amber.shade50;
        badgeText = Colors.amber.shade800;
        badgeLabel = 'Pending';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title, Status Badge, Delete Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref, suggestion),
                    child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              suggestion.description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 12),
            // Author & Date
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: baseColor.withValues(alpha: 0.1),
                  child: Text(
                    suggestion.authorName.isNotEmpty ? suggestion.authorName[0].toUpperCase() : 'M',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: baseColor),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${suggestion.authorName} • $dateStr',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
            
            // Admin Actions Panel (If user is developer admin)
            if (isAdmin) ...[
              const Divider(height: 24),
              Text(
                'DEVELOPER CONTROL: UPDATE STATUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusButton(
                    ref,
                    suggestion,
                    label: 'Pending',
                    targetStatus: 'new',
                    isActive: suggestion.status == 'new',
                    activeColor: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    ref,
                    suggestion,
                    label: 'In the Works',
                    targetStatus: 'in_progress',
                    isActive: suggestion.status == 'in_progress',
                    activeColor: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    ref,
                    suggestion,
                    label: 'Completed',
                    targetStatus: 'done',
                    isActive: suggestion.status == 'done',
                    activeColor: Colors.green.shade700,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    WidgetRef ref,
    Suggestion suggestion, {
    required String label,
    required String targetStatus,
    required bool isActive,
    required Color activeColor,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: isActive
            ? null
            : () {
                ref.read(suggestionsControllerProvider.notifier).updateStatus(
                      suggestionId: suggestion.id,
                      newStatus: targetStatus,
                    );
              },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
          backgroundColor: isActive ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showAddSuggestionSheet(BuildContext context, WidgetRef ref, Color baseColor) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
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
                  'Suggest an Idea / Report Bug',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  maxLength: 50,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: baseColor, width: 2),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: baseColor, width: 2),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Submitting suggestion...')),
                      );
                      await ref.read(suggestionsControllerProvider.notifier).addSuggestion(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: baseColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'SUBMIT',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      titleController.dispose();
      descController.dispose();
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Suggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Suggestion?'),
        content: const Text('Are you sure you want to permanently delete this suggestion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(suggestionsControllerProvider.notifier).deleteSuggestion(
                    suggestionId: suggestion.id,
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
