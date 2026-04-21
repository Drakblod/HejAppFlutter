import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ai_providers.dart';
import '../../../../core/services/database_repository.dart';

class AIBackgroundStudio extends ConsumerStatefulWidget {
  final String groupId;

  const AIBackgroundStudio({super.key, required this.groupId});

  @override
  ConsumerState<AIBackgroundStudio> createState() => _AIBackgroundStudioState();
}

class _AIBackgroundStudioState extends ConsumerState<AIBackgroundStudio> {
  final _promptController = TextEditingController();
  String _selectedStyle = 'Cinematic';
  String? _previewUrl;
  bool _isGenerating = false;
  bool _isApplying = false;

  final List<String> _styles = [
    'Cinematic',
    'Minimalist',
    'Cyberpunk',
    'Watercolor',
    'Pixel Art',
    'Abstract',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generatePreview() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _previewUrl = null;
    });

    try {
      // 1. Try to refine with Gemini (fast 3s timeout)
      String? refined;
      try {
        refined = await ref.read(geminiControllerProvider.notifier).generateBackgroundPrompt(
          prompt,
          style: _selectedStyle,
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        // Silent failure - will fallback to raw prompt below
      }

      // 2. Use refined if available, otherwise raw prompt
      final finalPrompt = (refined != null && refined.isNotEmpty) ? refined : prompt;
      final hdPrompt = "Professional 4K HD Mobile Wallpaper: $finalPrompt";
      final encoded = Uri.encodeComponent(hdPrompt);
      
      // Using 720x1280 for better server resilience (HD look, lower load)
      // Added a random seed to prevent 429 rate limiting
      final randomSeed = DateTime.now().millisecondsSinceEpoch % 1000000;
      final url = "https://image.pollinations.ai/prompt/$encoded?width=720&height=1280&model=turbo&nologo=true&seed=$randomSeed";
      
      setState(() {
        _previewUrl = url;
      });
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _applyBackground() async {
    if (_previewUrl == null) return;

    setState(() => _isApplying = true);
    try {
      await ref.read(databaseRepositoryProvider).updateGroupMeta(widget.groupId, {
        'backgroundImage': _previewUrl,
        'theme': 'custom',
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ Group background updated!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI Background Studio',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Prompt Input
            const Text('What is your vision?', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., "A futuristic forest with bioluminescent plants"',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            // Style Selection
            const Text('Choose a Style:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _styles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final s = _styles[index];
                  final isSelected = _selectedStyle == s;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStyle = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.amber : Colors.white12),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Preview Area
            if (_previewUrl != null || _isGenerating)
              Column(
                children: [
                  const Text('PREVIEW', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _isGenerating
                        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                        : Image.network(
                            _previewUrl!,
                            key: ValueKey(_previewUrl), // Force fresh reload on every new URL
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: Colors.amber));
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.cloud_off, color: Colors.white24, size: 48),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Server is busy. Please try regenerating in a moment.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Main Action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isGenerating || _isApplying ? null : _generatePreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _previewUrl == null ? 'GENERATE PREVIEW' : 'REGENERATE',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (_previewUrl != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isApplying ? null : _applyBackground,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isApplying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('UPDATE GROUP BACKGROUND', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
