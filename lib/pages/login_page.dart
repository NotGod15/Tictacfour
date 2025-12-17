import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// login page with Google sign-in and guest option
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // show loading spinner during Google sign-in
  bool _isLoadingGoogleSignIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 180,
                      child: Image.asset('assets/textures/logo.png'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Welcome to Tic Tac Four', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Sign in with Google or continue as guest.'),
                  ],
                ),
              ),

              if (_isLoadingGoogleSignIn) const CircularProgressIndicator(),

              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                onPressed: _isLoadingGoogleSignIn ? null : _onGoogleSignInTap,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _onGuestTap,
                child: const Text('Skip for now (Play as Guest)'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // handle Google sign-in button tap
  Future<void> _onGoogleSignInTap() async {
    setState(() {
      _isLoadingGoogleSignIn = true;
    });
    final ok = await AuthService.instance.signInWithGoogle();
    setState(() {
      _isLoadingGoogleSignIn = false;
    });
    if (ok) {
      AuthService.instance.isGuest = false;
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in failed')));
    }
  }

  // show guest warning dialog
  void _onGuestTap() {
    // warn user that score not saved in guest mode
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Guest Mode'),
        content: const Text(
          'Using guest mode will not store your score on the leaderboard',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Go back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AuthService.instance.signInGuest();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
