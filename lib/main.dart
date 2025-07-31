import 'package:emotional_chat/feature/ai%20chat/views/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'feature/ai chat/views/chat_screen.dart';
import 'feature/ai chat/view-model/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); //This is to load .env file
  runApp(const EmotionalSupportApp());
}

class EmotionalSupportApp extends StatelessWidget {
  const EmotionalSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>(
      create: (_) => ChatProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Marvis Chati',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        home: const Onboarding(),
      ),
    );
  }
}
