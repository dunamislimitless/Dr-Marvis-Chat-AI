import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final Map<String, int> _moodCounts = {'Happy': 0, 'Sad': 0, 'Anxious': 0};
  bool _isLoading = false;

  List<Message> get messages => _messages;
  TextEditingController get controller => _controller;
  Map<String, int> get moodCounts => _moodCounts;
  bool get isLoading => _isLoading;

  void trackMood(String input) {
    if (input.toLowerCase().contains('happy')) {
      _moodCounts['Happy'] = (_moodCounts['Happy'] ?? 0) + 1;
    } else if (input.toLowerCase().contains('sad')) {
      _moodCounts['Sad'] = (_moodCounts['Sad'] ?? 0) + 1;
    } else if (input.toLowerCase().contains('anxious')) {
      _moodCounts['Anxious'] = (_moodCounts['Anxious'] ?? 0) + 1;
    }
    notifyListeners();
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    trackMood(text);
    _messages.add(Message(text: text, isUser: true));
    _isLoading = true;
    notifyListeners();
    _controller.clear();

    final response = await _getGeminiResponse(text);
    _messages.add(Message(text: response, isUser: false));
    _isLoading = false;
    notifyListeners();
  }

  Future<String> _getGeminiResponse(String userInput) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'default_key';
    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

    try {
      final response = await http.post(
        Uri.parse('$endpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
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
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ??
            'I’m here for you. Could you share more about how you feel?';
      } else {
        return 'Sorry, I’m having trouble connecting. Please try again.';
      }
    } catch (e) {
      return 'Error: Could not reach the server. Please check your connection.';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
