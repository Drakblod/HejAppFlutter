import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/env_config.dart';
import '../models/chat_message.dart';

part 'gemini_repository.g.dart';

class GeminiRepository {
  final GenerativeModel _model;
  final GenerativeModel _flashModel;

  GeminiRepository()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: EnvConfig.geminiApiKey,
        ),
        _flashModel = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: EnvConfig.geminiApiKey,
        );

  /// Analyzes chat messages to find potential events or key takeaways.
  /// Returns a list of maps that can be converted to PostIts.
  Future<List<Map<String, dynamic>>> extractPostIts(List<ChatMessage> messages) async {
    if (messages.isEmpty) return [];

    final conversation = messages.map((m) => '${m.senderName}: ${m.text}').join('\n');

    final prompt = '''
Analyze the following chat conversation and identify:
1. Shared events (like meetings, coffee, parties, deadlines) with dates/times if mentioned.
2. Important conclusions or "key takeaways" from the group.

Return the results ONLY as a JSON array of objects.
Each object MUST have:
- "text": A short, catchy title or description (max 40 chars).
- "color": One of these classic post-it colors: "yellow", "cyan", "lime", "pink", "orange".

Conversation:
$conversation

JSON Output:
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    
    final text = response.text;
    if (text == null) return [];

    try {
      // Clean up potential markdown formatting
      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> decoded = jsonDecode(cleanJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Generates a high-quality image prompt for a group background based on a user description.
  Future<String> generateBackgroundPrompt(String userDescription) async {
    final prompt = '''
The user wants a background image for a digital bulletin board / group chat app.
Their description is: "$userDescription"

Translate this into a high-quality, professional image generation prompt.
- The style should be: Minimalist, abstract, or high-quality photography.
- Avoid text in the image.
- Focus on textures, gradients, or scenic views.
- Ensure it works well as a background (not too busy).

Return ONLY the refined prompt text.
''';

    final content = [Content.text(prompt)];
    final response = await _flashModel.generateContent(content);
    return response.text?.trim() ?? userDescription;
  }
}

@riverpod
GeminiRepository geminiRepository(Ref ref) {
  return GeminiRepository();
}
