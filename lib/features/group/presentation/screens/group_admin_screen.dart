
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../providers/board_providers.dart';
import '../../../../core/services/database_repository.dart';
import '../../../../core/services/storage_repository.dart';
import '../../../../core/res/app_themes.dart';
import '../widgets/ai_background_studio.dart';

class GroupAdminScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupAdminScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends ConsumerState<GroupAdminScreen> {
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _boardLabelController;
  late TextEditingController _chatLabelController;
  late TextEditingController _filesLabelController;
  late TextEditingController _ocrLabelController;
  late TextEditingController _galleryLabelController;
  String? _selectedFont;
  String? _selectedBaseColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _boardLabelController = TextEditingController();
    _chatLabelController = TextEditingController();
    _filesLabelController = TextEditingController();
    _ocrLabelController = TextEditingController();
    _galleryLabelController = TextEditingController();
    
    // Initialize with current meta
    Future.microtask(() async {
      final meta = await ref.read(databaseRepositoryProvider).getGroupMeta(widget.groupId);
      if (meta != null) {
        setState(() {
          _nameController.text = meta.name;
          _descriptionController.text = meta.description ?? '';
          _boardLabelController.text = meta.boardLabel ?? 'BOARD';
          _chatLabelController.text = meta.chatLabel ?? 'CHAT';
          _filesLabelController.text = meta.filesLabel ?? 'FILES';
          _ocrLabelController.text = meta.ocrLabel ?? 'OCR';
          _galleryLabelController.text = meta.galleryLabel ?? 'GALLERY';
          _selectedFont = meta.fontFamily;
          _selectedBaseColor = meta.baseColor;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _boardLabelController.dispose();
    _chatLabelController.dispose();
    _filesLabelController.dispose();
    _ocrLabelController.dispose();
    _galleryLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isIcon) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(storageRepositoryProvider);
      final db = ref.read(databaseRepositoryProvider);
      
      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;
      
      String? url;
      if (isIcon) {
        url = await repo.uploadGroupBackground(groupId: widget.groupId, bytes: bytes, fileName: fileName);
        await db.updateGroupMeta(widget.groupId, {'icon': url});
      } else {
        url = await repo.uploadGroupBackground(groupId: widget.groupId, bytes: bytes, fileName: fileName);
        await db.updateGroupMeta(widget.groupId, {'backgroundImage': url});
      }
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Header background updated!')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTheme(String themeId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(databaseRepositoryProvider).updateGroupMeta(widget.groupId, {
        'theme': themeId,
        'backgroundImage': null, // Clear custom BG when picking a theme
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Theme updated to $themeId')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(databaseRepositoryProvider).updateGroupMeta(widget.groupId, {
        'name': newName,
        'description': _descriptionController.text.trim(),
        'boardLabel': _boardLabelController.text.trim(),
        'chatLabel': _chatLabelController.text.trim(),
        'filesLabel': _filesLabelController.text.trim(),
        'ocrLabel': _ocrLabelController.text.trim(),
        'galleryLabel': _galleryLabelController.text.trim(),
        'fontFamily': _selectedFont,
        'baseColor': _selectedBaseColor ?? '0xFF2F7D32',
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group settings saved!')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _onRemoveMember(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to remove $name from the group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(databaseRepositoryProvider).removeMember(widget.groupId, userId);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _onDeleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?', style: TextStyle(color: Colors.red)),
        content: const Text('This action is permanent. All messages and posts will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(databaseRepositoryProvider).deleteGroup(widget.groupId);
        if (mounted) context.go('/home');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupMetaProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        title: const Text(
          'Group Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        shape: const Border(
          bottom: BorderSide(
            color: Colors.white24,
            width: 1,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2C2C),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: Stack(
          children: [
          groupAsync.when(
            data: (group) {
              if (group == null) return const Center(child: Text('Group not found'));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invite Section
                    _buildSectionTitle('INVITE OTHERS'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Group ID / Invite Code', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  widget.groupId, 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: Colors.blue, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.groupId));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied!')));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // General Info
                    _buildSectionTitle('GENERAL INFO'),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        labelStyle: TextStyle(color: Colors.white60),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Group Description / About',
                        labelStyle: TextStyle(color: Colors.white60),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Header Background Section
                    _buildSectionTitle('HEADER BACKGROUND'),
                    const Text('Choose a gradient preset:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppThemes.presets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final theme = AppThemes.presets[index];
                          final isSelected = group.theme == theme['id'] && group.backgroundImage == null;
                          return GestureDetector(
                            onTap: () => _updateTheme(theme['id']),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: theme['colors']),
                                border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                              ),
                              child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Upload Header Background', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Choose a custom background image from your gallery', style: TextStyle(color: Colors.white60)),
                      trailing: const Icon(Icons.file_upload_outlined, color: Colors.blue),
                      onTap: () => _pickImage(false),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✨ AI Background Studio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AIBackgroundStudio(groupId: widget.groupId),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.white10),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'GENERATE AI BACKGROUND',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    

                    
                    // Module Visibility
                    _buildSectionTitle('MANAGE MODULES'),
                    _buildModuleToggle('Bulletin Board', 'board', group.enabledModules['board'] ?? true),
                    _buildModuleToggle('Real-time Chat', 'chat', group.enabledModules['chat'] ?? true),
                    _buildModuleToggle('Shared Files', 'files', group.enabledModules['files'] ?? true),
                    _buildModuleToggle('Gathering Planner', 'calendar', group.enabledModules['calendar'] ?? true),
                    _buildModuleToggle('OCR-delare', 'ocr', group.enabledModules['ocr'] ?? false),
                    _buildModuleToggle('Gallery', 'gallery', group.enabledModules['gallery'] ?? false),
                    const SizedBox(height: 32),

                    // Custom Identity Section
                    _buildSectionTitle('CUSTOM IDENTITY'),
                    _buildIdentityField('Board Tab Name', _boardLabelController),
                    const SizedBox(height: 16),
                    _buildIdentityField('Chat Tab Name', _chatLabelController),
                    const SizedBox(height: 16),
                    _buildIdentityField('Files Tab Name', _filesLabelController),
                    const SizedBox(height: 16),
                    _buildIdentityField('OCR Tab Name', _ocrLabelController),
                    const SizedBox(height: 16),
                    _buildIdentityField('Gallery Tab Name', _galleryLabelController),
                    const SizedBox(height: 24),
                    const Text('Typography Style:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFontButton('Modern', null),
                        const SizedBox(width: 8),
                        _buildFontButton('Playful', 'Kenia'),
                        const SizedBox(width: 8),
                        _buildFontButton('Classic', 'Lora'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Base Color:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildColorSwatch('0xFF2F7D32'), // Hej Green
                        const SizedBox(width: 8),
                        _buildColorSwatch('0xFF0288D1'), // Ocean Blue
                        const SizedBox(width: 8),
                        _buildColorSwatch('0xFFE64A19'), // Sunset Orange
                        const SizedBox(width: 8),
                        _buildColorSwatch('0xFF512DA8'), // Royal Purple
                        const SizedBox(width: 8),
                        _buildColorSwatch('0xFF455A64'), // Slate Grey
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('SAVE CHANGES'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Members Section
                    _buildSectionTitle('MEMBERS'),
                    membersAsync.when(
                      data: (members) => Column(
                        children: members.map((m) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: m.profile?.photoUrl != null ? NetworkImage(m.profile!.photoUrl!) : null,
                            child: m.profile?.photoUrl == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(m.profile?.username ?? 'User', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(m.member.role, style: const TextStyle(color: Colors.white60)),
                          trailing: m.member.role != 'owner' 
                            ? IconButton(
                                icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                                onPressed: () => _onRemoveMember(m.member.uid, m.profile?.username ?? 'User'),
                              )
                            : const Text('Owner', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        )).toList(),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error loading members: $e', style: const TextStyle(color: Colors.red)),
                    ),

                    const SizedBox(height: 48),
                    
                    // Danger Zone
                    _buildSectionTitle('DANGER ZONE', color: Colors.redAccent),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _onDeleteGroup,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('DELETE GROUP'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color color = Colors.white60}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildIdentityField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFontButton(String name, String? fontId) {
    final isSelected = _selectedFont == fontId;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFont = fontId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.blue : Colors.white24),
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String hexColor) {
    final isSelected = (_selectedBaseColor ?? '0xFF2F7D32') == hexColor;
    final color = Color(int.parse(hexColor));

    return GestureDetector(
      onTap: () => setState(() => _selectedBaseColor = hexColor),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
              : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }

  Widget _buildModuleToggle(String label, String moduleId, bool value) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      value: value,
      activeTrackColor: Colors.blue.withValues(alpha: 0.5),
      activeThumbColor: Colors.blue, // This is actually for the thumb
      onChanged: (bool newValue) async {
        setState(() => _isLoading = true);
        try {
          final currentModules = Map<String, bool>.from(
            (await ref.read(databaseRepositoryProvider).getGroupMeta(widget.groupId))?.enabledModules ?? {}
          );
          currentModules[moduleId] = newValue;
          await ref.read(databaseRepositoryProvider).updateGroupMeta(widget.groupId, {
            'enabledModules': currentModules,
          });
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
