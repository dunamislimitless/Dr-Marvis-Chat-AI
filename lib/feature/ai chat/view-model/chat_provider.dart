import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime? createdAt;

  Message({required this.text, required this.isUser, this.createdAt});
}

class MoodEntry {
  final String mood;
  final DateTime timestamp;

  MoodEntry({required this.mood, required this.timestamp});
}

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final Map<String, int> _moodCounts = {'Happy': 0, 'Sad': 0, 'Anxious': 0};
  final List<MoodEntry> _moodHistory = [];
  bool _isLoading = false;
  bool _historyLoading = false;
  String? _userId;

  List<Message> get messages => _messages;
  TextEditingController get controller => _controller;
  Map<String, int> get moodCounts => _moodCounts;
  bool get isLoading => _isLoading;
  bool get historyLoading => _historyLoading;
  List<MoodEntry> get moodHistory => List.unmodifiable(_moodHistory);
  String? get userId => _userId;

  void trackMood(String input, {DateTime? now, bool notify = true}) {
    final currentTime = now ?? DateTime.now();

    if (input.toLowerCase().contains('happy')) {
      _moodCounts['Happy'] = (_moodCounts['Happy'] ?? 0) + 1;
      _moodHistory.add(MoodEntry(mood: 'Happy', timestamp: currentTime));
    } else if (input.toLowerCase().contains('sad')) {
      _moodCounts['Sad'] = (_moodCounts['Sad'] ?? 0) + 1;
      _moodHistory.add(MoodEntry(mood: 'Sad', timestamp: currentTime));
    } else if (input.toLowerCase().contains('anxious')) {
      _moodCounts['Anxious'] = (_moodCounts['Anxious'] ?? 0) + 1;
      _moodHistory.add(MoodEntry(mood: 'Anxious', timestamp: currentTime));
    }
    if (notify) notifyListeners();
  }

  Future<void> setUserId(String? uid) async {
    if (_userId == uid) return;
    _userId = uid;

    if (uid == null) {
      _clearLocalChat();
      notifyListeners();
      return;
    }

    _historyLoading = true;
    notifyListeners();
    try {
      await _loadHistory(uid);
    } catch (e) {
      debugPrint('Chat history load failed: $e');
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  void _clearLocalChat() {
    _messages.clear();
    _moodCounts.updateAll((key, value) => 0);
    _moodHistory.clear();
  }

  void _rebuildMoodFromHistory() {
    _moodCounts.updateAll((key, value) => 0);
    _moodHistory.clear();
    for (final m in _messages) {
      if (m.isUser) trackMood(m.text, now: m.createdAt, notify: false);
    }
  }

  Future<void> _loadHistory(String uid) async {
    final snap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('messages')
            .orderBy('createdAt', descending: false)
            .limit(300)
            .get();

    _messages.clear();
    for (final doc in snap.docs) {
      final data = doc.data();
      final text = data['text'] as String? ?? '';
      final isUser = data['isUser'] as bool? ?? false;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      _messages.add(Message(text: text, isUser: isUser, createdAt: createdAt));
    }
    _rebuildMoodFromHistory();
  }

  Future<void> _persistMessage(String uid, Message message) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('messages')
        .add({
          'text': message.text,
          'isUser': message.isUser,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> clearCurrentUserHistory() async {
    final uid = _userId;
    if (uid == null) return;

    final messagesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('messages');

    while (true) {
      final snap = await messagesRef.limit(300).get();
      if (snap.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    _clearLocalChat();
    notifyListeners();
  }

  Map<String, int> moodCountsForLastDays(int days, {DateTime? now}) {
    final end = now ?? DateTime.now();
    final start = end.subtract(Duration(days: days));
    final counts = {'Happy': 0, 'Sad': 0, 'Anxious': 0};

    for (final entry in _moodHistory) {
      if (entry.timestamp.isAfter(start) || entry.timestamp.isAtSameMomentAs(start)) {
        counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
      }
    }

    return counts;
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    trackMood(text);
    _messages.add(Message(text: text, isUser: true));
    _isLoading = true;
    notifyListeners();
    _controller.clear();

    final uid = _userId;

    if (uid != null) {
      try {
        await _persistMessage(uid, Message(text: text, isUser: true));
      } catch (e) {
        debugPrint('Failed to save user message: $e');
      }
    }

    final response = await _getGeminiResponse(text);
    _messages.add(Message(text: response, isUser: false));

    if (uid != null) {
      try {
        await _persistMessage(uid, Message(text: response, isUser: false));
      } catch (e) {
        debugPrint('Failed to save assistant message: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String> _getGeminiResponse(String userInput) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

    if (apiKey == null || apiKey.trim().isEmpty) {
      return 'I got your message, but Gemini API key is missing. Add GEMINI_API_KEY to your .env and restart the app.';
    }

    try {
      final modelEndpoints = await _buildModelEndpoints(apiKey, baseUrl);
      String? lastError;

      for (final endpoint in modelEndpoints) {
        debugPrint('[Gemini] Requesting endpoint: $endpoint');
        http.Response response;
        try {
          response = await _postWithRetry(endpoint, apiKey, userInput);
        } on TimeoutException {
          lastError = 'Request timed out for $endpoint.';
          debugPrint('[Gemini] Timeout for endpoint: $endpoint');
          continue;
        }

        debugPrint('[Gemini] Status: ${response.statusCode}');
        debugPrint('[Gemini] Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text is String && text.trim().isNotEmpty) {
            return text;
          }
          return 'I’m here for you. Could you share more about how you feel?';
        }

        lastError = _extractGeminiError(response.body);
      }

      debugPrint('[Gemini] Final API error: $lastError');
      return 'Gemini request failed. ${lastError ?? 'Please check your API key, billing/quota, and model access.'}';
    } catch (e) {
      debugPrint('[Gemini] Unexpected error: $e');
      return 'Error: Could not reach Gemini. Please check your internet and API key setup.';
    }
  }

  Future<http.Response> _postWithRetry(
    String endpoint,
    String apiKey,
    String userInput,
  ) async {
    const timeout = Duration(seconds: 30);
    const retryDelay = Duration(seconds: 2);

    final uri = Uri.parse('$endpoint?key=$apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'You are an emotional support assistant. Respond empathetically to: "$userInput"',
            },
          ],
        },
      ],
    });

    try {
      return await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(timeout);
    } on TimeoutException {
      debugPrint('[Gemini] First attempt timed out, retrying in 2s...');
      await Future<void>.delayed(retryDelay);
      return http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(timeout);
    }
  }

  Future<List<String>> _buildModelEndpoints(String apiKey, String baseUrl) async {
    final fallbackEndpoints = [
      '$baseUrl/models/gemini-2.0-flash:generateContent',
      '$baseUrl/models/gemini-1.5-flash:generateContent',
      '$baseUrl/models/gemini-1.5-pro:generateContent',
    ];

    try {
      final listModelsResponse = await http
          .get(Uri.parse('$baseUrl/models?key=$apiKey'))
          .timeout(const Duration(seconds: 15));

      if (listModelsResponse.statusCode != 200) {
        debugPrint(
          '[Gemini] ListModels failed: ${listModelsResponse.statusCode} ${listModelsResponse.body}',
        );
        return fallbackEndpoints;
      }

      final decoded = jsonDecode(listModelsResponse.body);
      final models = decoded['models'];
      if (models is! List) return fallbackEndpoints;

      final discovered = <String>[];
      for (final model in models) {
        final name = model['name'];
        final supportedMethods = model['supportedGenerationMethods'];
        final supportsGenerateContent =
            supportedMethods is List && supportedMethods.contains('generateContent');
        if (name is String && supportsGenerateContent) {
          discovered.add('$baseUrl/$name:generateContent');
        }
      }

      discovered.sort((a, b) {
        final aIsFlash = a.toLowerCase().contains('flash');
        final bIsFlash = b.toLowerCase().contains('flash');
        if (aIsFlash == bIsFlash) return 0;
        return aIsFlash ? -1 : 1;
      });

      return discovered.isEmpty ? fallbackEndpoints : discovered;
    } catch (e) {
      debugPrint('[Gemini] ListModels exception: $e');
      return fallbackEndpoints;
    }
  }

  String _extractGeminiError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      final message = decoded['error']?['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      return 'Unknown API error.';
    } catch (_) {
      return 'Could not parse API error response.';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
