import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'feature/auth/auth_gate.dart';
import 'feature/auth/auth_service.dart';
import 'package:emotional_chat/feature/ai%20chat/view-model/chat_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialize failed — run flutterfire configure: $e');
  }

  runApp(const EmotionalSupportApp());
}

class EmotionalSupportApp extends StatelessWidget {
  const EmotionalSupportApp({super.key, this.testHome});

  /// When non-null, used instead of [AuthGate] (e.g. widget tests without Firebase).
  final Widget? testHome;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Marvis Chati',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        home: testHome ?? const AuthGate(),
      ),
    );
  }
}
