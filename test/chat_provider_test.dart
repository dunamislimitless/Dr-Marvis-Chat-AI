import 'package:flutter_test/flutter_test.dart';
import 'package:emotional_chat/feature/ai chat/view-model/chat_provider.dart';

void main() {
  group('ChatProvider trackMood', () {
    test('increments happy mood count (case-insensitive)', () {
      final provider = ChatProvider();

      provider.trackMood('I feel HAPPY today');

      expect(provider.moodCounts['Happy'], 1);
      expect(provider.moodCounts['Sad'], 0);
      expect(provider.moodCounts['Anxious'], 0);
      provider.dispose();
    });

    test('increments sad and anxious mood counts', () {
      final provider = ChatProvider();

      provider.trackMood('I am sad right now');
      provider.trackMood('I feel anxious about tomorrow');

      expect(provider.moodCounts['Happy'], 0);
      expect(provider.moodCounts['Sad'], 1);
      expect(provider.moodCounts['Anxious'], 1);
      provider.dispose();
    });

    test('does not change mood counts for unmatched text', () {
      final provider = ChatProvider();

      provider.trackMood('I am okay');

      expect(provider.moodCounts['Happy'], 0);
      expect(provider.moodCounts['Sad'], 0);
      expect(provider.moodCounts['Anxious'], 0);
      provider.dispose();
    });

    test('returns correct counts for selected range', () {
      final provider = ChatProvider();
      final now = DateTime(2026, 4, 7);

      provider.trackMood('I feel happy', now: now.subtract(const Duration(days: 2)));
      provider.trackMood('I am sad', now: now.subtract(const Duration(days: 10)));

      final weekly = provider.moodCountsForLastDays(7, now: now);
      final monthly = provider.moodCountsForLastDays(30, now: now);

      expect(weekly['Happy'], 1);
      expect(weekly['Sad'], 0);
      expect(monthly['Happy'], 1);
      expect(monthly['Sad'], 1);
      provider.dispose();
    });
  });

  group('ChatProvider sendMessage', () {
    test('returns early when input is empty', () async {
      final provider = ChatProvider();

      await provider.sendMessage();

      expect(provider.messages, isEmpty);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    });
  });
}
