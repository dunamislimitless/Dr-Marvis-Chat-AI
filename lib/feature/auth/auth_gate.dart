import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_screen.dart';
import 'auth_service.dart';
import 'package:emotional_chat/feature/ai%20chat/view-model/chat_provider.dart';
import 'package:emotional_chat/feature/ai%20chat/views/chat_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastSyncedUid;
  String? _signInError;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Future<void> _signInWithGoogle() async {
    if (!_firebaseReady) return;
    final auth = context.read<AuthService>();
    try {
      await auth.signInWithGoogle();
      if (mounted) setState(() => _signInError = null);
    } catch (e) {
      if (mounted) setState(() => _signInError = e.toString());
      rethrow;
    }
  }

  void _syncChatUser(String? uid) {
    if (uid == _lastSyncedUid) return;
    _lastSyncedUid = uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().setUserId(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_firebaseReady) {
      return AuthScreen(
        firebaseReady: false,
        lastError: _signInError,
        onGoogleSignIn: _signInWithGoogle,
      );
    }

    final authService = context.read<AuthService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      initialData: authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        _syncChatUser(user?.uid);

        if (user == null) {
          return AuthScreen(
            firebaseReady: true,
            lastError: _signInError,
            onGoogleSignIn: _signInWithGoogle,
          );
        }

        return const ChatScreen();
      },
    );
  }
}
