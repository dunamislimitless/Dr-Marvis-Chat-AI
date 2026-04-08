import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:emotional_chat/feature/auth/auth_service.dart';
import '../view-model/chat_provider.dart';
import 'mood_chart_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white24),
        title: const Text(
          'Chat with Dr. Marvis ChatAI',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 5, 56, 103),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'clear_history') {
                final shouldClear = await showDialog<bool>(
                  context: context,
                  builder:
                      (dialogContext) => AlertDialog(
                        title: const Text('Clear chat history?'),
                        content: const Text(
                          'This will permanently delete your saved chat history for this account.',
                        ),
                        actions: [
                          TextButton(
                            onPressed:
                                () => Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed:
                                () => Navigator.of(dialogContext).pop(true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                );

                if (shouldClear == true && context.mounted) {
                  await context.read<ChatProvider>().clearCurrentUserHistory();
                }
              }
              if (value == 'sign_out') {
                await context.read<AuthService>().signOut();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'clear_history',
                    child: Text('Clear my history'),
                  ),
                  const PopupMenuItem(
                    value: 'sign_out',
                    child: Text('Sign out'),
                  ),
                ],
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(
        147,
        255,
        255,
        255,
      ).withOpacity(0.9),

      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Optional: Button to view mood chart
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MoodChartScreen(),
                      ),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Mood Trends'),
              ),
            ),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  return Column(
                    children: [
                      if (chatProvider.historyLoading)
                        const LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Colors.white24,
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: chatProvider.messages.length,
                          itemBuilder: (context, index) {
                            final message = chatProvider.messages[index];
                            return Align(
                              alignment:
                                  message.isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color:
                                      message.isUser
                                          ? Colors.blue[100]
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    color:
                                        message.isUser
                                            ? Colors.blue[900]
                                            : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatProvider.controller,
                          decoration: InputDecoration(
                            hintText: 'How are you feeling?',

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              chatProvider.sendMessage();
                              debugPrint('Sent: $value');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      chatProvider.isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                              strokeWidth: 2.0,
                            ),
                          )
                          : IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed:
                                chatProvider.isLoading
                                    ? null
                                    : () => chatProvider.sendMessage(),
                          ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
