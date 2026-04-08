import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emotional_chat/feature/ai%20chat/views/chat_screen.dart';
import 'package:emotional_chat/main.dart';

/// Uses [EmotionalSupportApp.testHome] to render [ChatScreen] without [AuthGate]
/// or live Firebase — same provider tree as production (`AuthService`, [ChatProvider]).
void main() {
  testWidgets('chat screen shows title and input', (WidgetTester tester) async {
    await tester.pumpWidget(
      const EmotionalSupportApp(testHome: ChatScreen()),
    );

    expect(find.text('Chat with Dr. Marvis ChatAI'), findsOneWidget);
    expect(find.text('View Mood Trends'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('How are you feeling?'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
