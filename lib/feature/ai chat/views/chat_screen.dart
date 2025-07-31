import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view-model/chat_provider.dart';
import 'mood_chart_screen.dart'; // If using chart feature

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
      ),
      backgroundColor: const Color.fromARGB(
        147,
        255,
        255,
        255,
      ).withOpacity(0.9),

      body: Column(
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
              child: const Text('View Mood Trends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Background color
                foregroundColor: Colors.white, // Text/icon color
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return Stack(
                  children: [
                    ListView.builder(
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
                    // if (chatProvider.isLoading)
                    //   const Center(
                    //     child: CircularProgressIndicator(
                    //       valueColor: AlwaysStoppedAnimation<Color>(
                    //         Colors.blue,
                    //       ),
                    //       strokeWidth: 2.0,
                    //     ),
                    //   ),
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
                        textInputAction:
                            TextInputAction.send, // shows "Send" on keyboard
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            chatProvider.sendMessage();
                            print("Sent: $value");
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
    );
  }
}
