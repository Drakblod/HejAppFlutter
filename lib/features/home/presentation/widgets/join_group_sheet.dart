import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_repository.dart';
import '../../../auth/data/auth_repository.dart';

class JoinGroupSheet extends ConsumerStatefulWidget {
  const JoinGroupSheet({super.key});

  @override
  ConsumerState<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends ConsumerState<JoinGroupSheet> {
  final _idController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    final groupId = _idController.text.trim();
    if (groupId.isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw 'User not logged in';

      final exists = await ref.read(databaseRepositoryProvider).groupExists(groupId);
      if (!exists) {
        throw 'Group not found. Please check the ID.';
      }

      await ref.read(databaseRepositoryProvider).joinGroup(groupId, user.uid);

      if (mounted) {
        Navigator.pop(context);
        // We use go instead of push to clear previous stack if needed, 
        // but push is fine for detail navigation.
        context.push('/group/$groupId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to the group!'),
            backgroundColor: Color(0xFF1565C0),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Join a Group',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter a unique Group ID to connect with others.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _idController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Group ID',
              hintText: 'Paste the ID here',
              prefixIcon: const Icon(Icons.key_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
              ),
            ),
            onSubmitted: (_) => _joinGroup(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _joinGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'JOIN GROUP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
          ),
        ],
      ),
    );
  }
}
