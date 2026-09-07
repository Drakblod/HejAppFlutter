import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/group.dart';
import '../../../../core/res/app_themes.dart';
import '../../../../core/services/database_repository.dart';
import '../../../../core/services/storage_repository.dart';
import '../../providers/board_providers.dart';
import '../widgets/ai_background_studio.dart';

const _ink = Color(0xFF172B20);
const _muted = Color(0xFF65756A);
const _green = Color(0xFF225C32);
const _border = Color(0xFFDDE6DF);
const _sections = [
  (label: 'General', icon: Icons.tune_rounded),
  (label: 'Appearance', icon: Icons.palette_outlined),
  (label: 'Modules', icon: Icons.dashboard_customize_outlined),
  (label: 'Members', icon: Icons.people_outline_rounded),
];
const _modules = [
  (
    id: 'board',
    title: 'Bulletin board',
    description: 'Posts and updates for your group.',
    icon: Icons.dashboard_outlined,
  ),
  (
    id: 'chat',
    title: 'Chat',
    description: 'Keep the conversation going.',
    icon: Icons.chat_bubble_outline_rounded,
  ),
  (
    id: 'files',
    title: 'Shared files',
    description: 'Documents and resources in one place.',
    icon: Icons.folder_outlined,
  ),
  (
    id: 'calendar',
    title: 'Gathering planner',
    description: 'Find a time to meet.',
    icon: Icons.event_outlined,
  ),
  (
    id: 'ocr',
    title: 'OCR sharing',
    description: 'Scan and share text from images.',
    icon: Icons.document_scanner_outlined,
  ),
  (
    id: 'gallery',
    title: 'Gallery',
    description: 'Collect photos and shared memories.',
    icon: Icons.photo_library_outlined,
  ),
  (
    id: 'polls',
    title: 'Decisions & polls',
    description: 'Let the group vote and make decisions together.',
    icon: Icons.how_to_vote_outlined,
  ),
];
const _colors = [
  (value: '0xFF2F7D32', label: 'Forest'),
  (value: '0xFF0288D1', label: 'Ocean'),
  (value: '0xFFE64A19', label: 'Sunset'),
  (value: '0xFF512DA8', label: 'Plum'),
  (value: '0xFF455A64', label: 'Slate'),
];

class GroupAdminScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupAdminScreen({super.key, required this.groupId});
  @override
  ConsumerState<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends ConsumerState<GroupAdminScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _labels = {
    'board': TextEditingController(),
    'chat': TextEditingController(),
    'files': TextEditingController(),
    'ocr': TextEditingController(),
    'gallery': TextEditingController(),
  };
  bool _initialized = false;
  bool _isLoading = false;
  bool _dirty = false;
  int _section = 0;
  String? _nameError;
  String? _selectedFont;
  String _selectedBaseColor = '0xFF2F7D32';

  void _initializeForm(Group group) {
    if (_initialized) return;
    _nameController.text = group.name;
    _descriptionController.text = group.description ?? '';
    _labels['board']!.text = group.boardLabel ?? 'BOARD';
    _labels['chat']!.text = group.chatLabel ?? 'CHAT';
    _labels['files']!.text = group.filesLabel ?? 'FILES';
    _labels['ocr']!.text = group.ocrLabel ?? 'OCR';
    _labels['gallery']!.text = group.galleryLabel ?? 'GALLERY';
    _selectedFont = group.fontFamily;
    _selectedBaseColor = group.baseColor;
    _initialized = true;
  }

  @override
  void didUpdateWidget(covariant GroupAdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _initialized = false;
      _dirty = false;
      _nameError = null;
      _section = 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final controller in _labels.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changed(String _) => setState(() {
    _dirty = true;
    _nameError = null;
  });
  void _notify(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<bool> _perform(
    Future<void> Function() action, {
    String? success,
  }) async {
    if (_isLoading) return false;
    setState(() => _isLoading = true);
    try {
      await action();
      if (success != null) _notify(success);
      return true;
    } catch (_) {
      _notify('Could not save this change. Please try again.');
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _section = 0;
        _nameError = 'Enter a group name.';
      });
      return;
    }
    final saved = await _perform(() async {
      await ref
          .read(databaseRepositoryProvider)
          .updateGroupMeta(widget.groupId, {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            for (final entry in _labels.entries)
              '${entry.key}Label': entry.value.text.trim(),
            'fontFamily': _selectedFont,
            'baseColor': _selectedBaseColor,
          });
    }, success: 'Group settings saved.');
    if (mounted && saved) setState(() => _dirty = false);
  }

  Future<void> _pickImage() async {
    await _perform(() async {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (file == null || !mounted) return;
      final storage = ref.read(storageRepositoryProvider);
      final db = ref.read(databaseRepositoryProvider);
      final url = await storage.uploadGroupBackground(
        groupId: widget.groupId,
        bytes: await file.readAsBytes(),
        fileName: file.name,
      );
      await db.updateGroupMeta(widget.groupId, {'backgroundImage': url});
      _notify('Header background updated.');
    });
  }

  Future<void> _updateTheme(String themeId) async {
    await _perform(
      () => ref.read(databaseRepositoryProvider).updateGroupMeta(
        widget.groupId,
        {'theme': themeId, 'backgroundImage': null},
      ),
      success: 'Header background updated.',
    );
  }

  Future<void> _toggleModule(String id, bool enabled) async {
    // Update only this flag to preserve changes to other modules.
    await _perform(
      () => ref.read(databaseRepositoryProvider).updateGroupMeta(
        widget.groupId,
        {'enabledModules/$id': enabled},
      ),
    );
  }

  Future<void> _copyInvite() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.groupId));
      _notify('Invite code copied.');
    } catch (_) {
      _notify('Could not copy the code. You can select and copy it below.');
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _onRemoveMember(String id, String name) async {
    if (!await _confirm(
          title: 'Remove member?',
          message: 'Remove $name from this group?',
          action: 'Remove member',
        ) ||
        !mounted) {
      return;
    }
    await _perform(
      () =>
          ref.read(databaseRepositoryProvider).removeMember(widget.groupId, id),
      success: 'Member removed.',
    );
  }

  Future<void> _onDeleteGroup() async {
    if (!await _confirm(
          title: 'Delete group?',
          message:
              'This permanently deletes the group and its messages and posts. This cannot be undone.',
          action: 'Delete group',
        ) ||
        !mounted) {
      return;
    }
    final deleted = await _perform(
      () => ref.read(databaseRepositoryProvider).deleteGroup(widget.groupId),
    );
    if (deleted && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupMetaProvider(widget.groupId));
    final theme = Theme.of(context);
    // Explicit colors avoid white-on-white fields inherited from app themes.
    final settingsTheme = theme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _green,
        brightness: Brightness.light,
      ),
      textTheme: theme.textTheme.apply(bodyColor: _ink, displayColor: _ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAF8),
        labelStyle: const TextStyle(color: _muted),
        hintStyle: const TextStyle(color: _muted),
        floatingLabelStyle: const TextStyle(color: _green),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _green, width: 2),
        ),
      ),
    );
    return Theme(
      data: settingsTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F6F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F6F3),
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          toolbarHeight: 72,
          title: const Text(
            'Group settings',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
          ),
          leading: IconButton(
            tooltip: 'Back to group',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _isLoading ? null : () => context.pop(),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isLoading
                            ? 'Saving…'
                            : _dirty
                            ? 'Unsaved changes'
                            : 'Your group, your way.',
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed:
                          !_isLoading && groupAsync.value != null && _dirty
                          ? _saveChanges
                          : null,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 19),
                      label: const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            groupAsync.when(
              data: (group) {
                if (group == null) {
                  return const Center(
                    child: Text('This group could not be found.'),
                  );
                }
                _initializeForm(group);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    return SingleChildScrollView(
                      key: const PageStorageKey('group-settings-scroll'),
                      padding: EdgeInsets.fromLTRB(
                        wide ? 32 : 16,
                        12,
                        wide ? 32 : 16,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1080),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heading(group),
                              const SizedBox(height: 28),
                              if (wide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 208,
                                      child: _navigation(vertical: true),
                                    ),
                                    const SizedBox(width: 28),
                                    Expanded(child: _content(group)),
                                  ],
                                )
                              else ...[
                                _navigation(vertical: false),
                                const SizedBox(height: 20),
                                _content(group),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load group settings.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(groupMetaProvider(widget.groupId)),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading) ...[
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(color: Color(0x44FFFFFF)),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heading(Group group) => Row(
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.settings_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Make this space feel like yours.',
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _navigation({required bool vertical}) {
    final items = [
      for (var i = 0; i < _sections.length; i++)
        Semantics(
          selected: _section == i,
          child: TextButton.icon(
            onPressed: _isLoading ? null : () => setState(() => _section = i),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              backgroundColor: _section == i
                  ? const Color(0xFFDFEDE1)
                  : Colors.transparent,
              foregroundColor: _section == i ? _green : _muted,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(_sections[i].icon, size: 20),
            label: Text(
              _sections[i].label,
              style: TextStyle(
                fontWeight: _section == i ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
    ];
    return vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...items.expand((item) => [item, const SizedBox(height: 6)]),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Text(
                  'A space that feels like home.',
                  style: TextStyle(color: _muted, height: 1.6, fontSize: 12),
                ),
              ),
            ],
          )
        : Wrap(spacing: 4, runSpacing: 4, children: items);
  }

  Widget _content(Group group) => switch (_section) {
    1 => _appearance(group),
    2 => _moduleSettings(group),
    3 => _members(),
    _ => _general(),
  };

  Widget _general() => Column(
    children: [
      _SettingsCard(
        icon: Icons.edit_outlined,
        title: 'The basics',
        subtitle: 'Give your group a name and a short introduction.',
        child: Column(
          children: [
            TextField(
              enabled: !_isLoading,
              key: const ValueKey('group-name'),
              controller: _nameController,
              style: const TextStyle(color: _ink),
              onChanged: _changed,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Group name',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              enabled: !_isLoading,
              controller: _descriptionController,
              style: const TextStyle(color: _ink),
              onChanged: _changed,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'About this group',
                hintText: 'What brings you together?',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _SettingsCard(
        icon: Icons.add_link_rounded,
        title: 'Invite people',
        subtitle:
            'Share this code. New members can use “Join a space” to find your group.',
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF4ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INVITE CODE',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.groupId,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Copy invite code',
                onPressed: _copyInvite,
                icon: const Icon(Icons.copy_rounded, color: _green, size: 21),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _appearance(Group group) => Column(
    children: [
      _SettingsCard(
        icon: Icons.landscape_outlined,
        title: 'Header background',
        subtitle:
            'Set the mood for your group. Background changes are applied immediately.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerPreview(group),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final preset in AppThemes.presets) _preset(preset, group),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.upload_rounded, size: 19),
                  label: const Text('Upload image'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AIBackgroundStudio(groupId: widget.groupId),
                  ),
                  icon: const Icon(Icons.auto_awesome_outlined, size: 19),
                  label: const Text('AI background studio'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _SettingsCard(
        icon: Icons.palette_outlined,
        title: 'Group style',
        subtitle: 'Choose a color and type style, then save your changes.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accent color',
              style: TextStyle(fontWeight: FontWeight.w600, color: _ink),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in _colors)
                  ChoiceChip(
                    label: Text(color.label),
                    avatar: CircleAvatar(
                      radius: 9,
                      backgroundColor: Color(int.parse(color.value)),
                    ),
                    selected:
                        int.tryParse(_selectedBaseColor) ==
                        int.parse(color.value),
                    onSelected: _isLoading
                        ? null
                        : (_) => setState(() {
                            _selectedBaseColor = color.value;
                            _dirty = true;
                          }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Typography',
              style: TextStyle(fontWeight: FontWeight.w600, color: _ink),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final font in [
                  (name: 'Modern', id: null),
                  (name: 'Playful', id: 'Kenia'),
                  (name: 'Classic', id: 'Lora'),
                ])
                  ChoiceChip(
                    label: Text(font.name),
                    selected: _selectedFont == font.id,
                    onSelected: _isLoading
                        ? null
                        : (_) => setState(() {
                            _selectedFont = font.id;
                            _dirty = true;
                          }),
                  ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _headerPreview(Group group) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    AppThemes.getGradient(group.theme) ??
                    [
                      Color(int.tryParse(_selectedBaseColor) ?? 0xFF2F7D32),
                      Color(int.tryParse(_selectedBaseColor) ?? 0xFF2F7D32),
                    ],
              ),
            ),
          ),
          if (group.backgroundImage != null)
            Image.network(
              group.backgroundImage!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.white54),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x88000000)],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Text(
              _nameController.text.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _preset(Map<String, dynamic> preset, Group group) {
    final selected =
        group.theme == preset['id'] && group.backgroundImage == null;
    return Semantics(
      selected: selected,
      child: Tooltip(
        message: preset['name'] as String,
        child: InkWell(
          onTap: _isLoading ? null : () => _updateTheme(preset['id'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 126,
            height: 72,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: (preset['colors'] as List).cast<Color>(),
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _ink : Colors.transparent,
                width: 3,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const Spacer(),
                Text(
                  preset['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _moduleSettings(Group group) => _SettingsCard(
    icon: Icons.dashboard_customize_outlined,
    title: 'Your group’s modules',
    subtitle:
        'Switch modules on or off instantly. Custom tab names are applied with Save changes.',
    child: Column(
      children: [
        for (var i = 0; i < _modules.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: _border),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(_modules[i].icon, color: _green),
            title: Text(
              _modules[i].title,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _modules[i].description,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            value: group.enabledModules[_modules[i].id] ?? (i < 4),
            onChanged: _isLoading
                ? null
                : (enabled) => _toggleModule(_modules[i].id, enabled),
          ),
          if (_labels.containsKey(_modules[i].id)) ...[
            const SizedBox(height: 10),
            TextField(
              enabled: !_isLoading,
              controller: _labels[_modules[i].id],
              style: const TextStyle(color: _ink),
              onChanged: _changed,
              decoration: InputDecoration(
                labelText: '${_modules[i].title} tab name',
              ),
            ),
          ],
        ],
      ],
    ),
  );

  Widget _members() => Column(
    children: [
      _SettingsCard(
        icon: Icons.people_outline_rounded,
        title: 'Group members',
        subtitle: 'See who is here and manage access to your group.',
        child: ref
            .watch(groupMembersProvider(widget.groupId))
            .when(
              data: (members) => members.isEmpty
                  ? const Text(
                      'No members to show yet.',
                      style: TextStyle(color: _muted),
                    )
                  : Column(
                      children: [
                        for (final member in members)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE2EDE3),
                              foregroundColor: _green,
                              child: member.profile?.photoUrl == null
                                  ? const Icon(Icons.person_outline_rounded)
                                  : ClipOval(
                                      child: Image.network(
                                        member.profile!.photoUrl!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.person_outline_rounded,
                                        ),
                                      ),
                                    ),
                            ),
                            title: Text(
                              member.profile?.username ?? 'Member',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                            subtitle: Text(
                              member.member.role,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: member.member.role == 'owner'
                                ? const Chip(
                                    label: Text('Owner'),
                                    side: BorderSide.none,
                                  )
                                : IconButton(
                                    tooltip:
                                        'Remove ${member.profile?.username ?? 'member'}',
                                    icon: const Icon(
                                      Icons.person_remove_outlined,
                                      color: Color(0xFFB3261E),
                                    ),
                                    onPressed: () => _onRemoveMember(
                                      member.member.uid,
                                      member.profile?.username ?? 'this member',
                                    ),
                                  ),
                          ),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Could not load members.',
                    style: TextStyle(color: _muted),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(groupMembersProvider(widget.groupId)),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
      ),
      const SizedBox(height: 24),
      _SettingsCard(
        icon: Icons.delete_outline_rounded,
        title: 'Delete this group',
        subtitle:
            'Permanently remove the group and its content. This cannot be undone.',
        danger: true,
        child: OutlinedButton.icon(
          onPressed: _onDeleteGroup,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB3261E),
            side: const BorderSide(color: Color(0xFFE6BDB9)),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 19),
          label: const Text('Delete group'),
        ),
      ),
    ],
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool danger;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 20 : 28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: danger ? const Color(0xFFEAD2CF) : _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06172B20),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: danger ? const Color(0xFFB3261E) : _green,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: danger ? const Color(0xFFB3261E) : _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        child,
      ],
    ),
  );
}
