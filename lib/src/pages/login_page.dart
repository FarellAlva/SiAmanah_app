// ignore_for_file: use_build_context_synchronously, unrelated_type_equality_checks, deprecated_member_use, unnecessary_string_escapes

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zakatapp/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoading = false;
  bool _isButtonDisabled = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null) {
        Navigator.of(context).pushReplacementNamed('/account');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authSubscription.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukan Email yang valid')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isButtonDisabled = true;
      _countdown = 26;
    });

    // Timer untuk countdown selama 25 detik
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // Periksa apakah widget masih aktif
        setState(() {
          _countdown--;
        });
        if (_countdown == 0) {
          timer.cancel();
          if (mounted) {
            // Periksa apakah widget masih aktif
            setState(() {
              _isButtonDisabled = false;
            });
          }
        }
      }
    });

    try {
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cek email untuk tautan login')),
        );
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        if (error.statusCode == 403 && error.message.contains('expired')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Tautan login sudah kadaluwarsa, silakan login lagi.'),
            ),
          );
        } else if (error.statusCode == 403 &&
            error.message.contains('access_denied')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tautan login tidak valid. Mohon coba lagi.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login error, please try again'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openGmail() async {
    const gmailAppUrl = 'googlegmail://';
    const gmailWebUrl = 'https://mail.google.com/';
    const url = 'mailto:';

    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else if (await canLaunch(gmailAppUrl)) {
        await launch(gmailAppUrl);
      } else if (await canLaunch(gmailWebUrl)) {
        await launch(gmailWebUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak bisa membuka Gmail'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 23, fontWeight: FontWeight.w600),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset('lib/src/img/siamanah-logo.png',
                  height: 100, width: 275), // Replace with your logo image path
            ),
            const SizedBox(height: 8),
            Text(
              'Distribusi Zakat dengan amanah.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green,
                  width: 2,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cara Login:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 23,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                      '1. Masukan email yang diberi akses oleh BAZNAS, lalu klik "Login".',
                      style: TextStyle(
                          fontWeight: FontWeight.w400, fontSize: 14.8)),
                  SizedBox(height: 10),
                  Text('2. Pastikan email sudah terkait di Gmail.',
                      style: TextStyle(
                          fontWeight: FontWeight.w400, fontSize: 14.8)),
                  SizedBox(height: 10),
                  Text('3. Cek Gmail dan klik tautan login yang diberikan.',
                      style: TextStyle(
                          fontWeight: FontWeight.w400, fontSize: 14.8)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                label: Text('Email'),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              onPressed:
                  _isButtonDisabled || _isLoading ? null : _signInWithEmail,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : _isButtonDisabled
                      ? Text(
                          'Tunggu $_countdown detik. Tautan Login telah dikirim')
                      : const Text('Login',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _openGmail,
              icon:
                  const Icon(Icons.mark_email_read_outlined, color: Colors.red),
              label: const Text(
                'Buka Gmail',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
