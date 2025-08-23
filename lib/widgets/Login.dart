import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'forgotPassword.dart';
import 'signUp.dart';
import '../screens/VerifyEmail.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _auth = FirebaseAuth.instance;
  String _email = "";
  String _password = "";
  bool _loading = false;
  String _error = "";

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = "";
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );
      final user = userCredential.user;

      if (user != null && !user.emailVerified) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VerifyEmail()),
          );
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "Login failed");
    } catch (e) {
      setState(() => _error = "Login failed: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return ForgotPassword(
          connecting: false,
          errorMessage: "",
          infoMessage: "",
          onSendReset: (email) => Navigator.pop(ctx),
          onChangePassword: (email, newPwd) => Navigator.pop(ctx),
          onBackToLogin: () => Navigator.pop(ctx),
        );
      },
    );
  }

  void _openSignUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SignUp(
          connecting: false,
          errorMessage: "",
          onSubmit: (username, email, password) async {
            try {
              final cred = await _auth.createUserWithEmailAndPassword(
                email: email.trim(),
                password: password,
              );

              await cred.user?.sendEmailVerification();

              if (mounted) Navigator.pop(ctx); // close SignUp sheet
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VerifyEmail()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email sent. Check your inbox.'),
                  ),
                );
              }
            } on FirebaseAuthException catch (e) {
              setState(() => _error = e.message ?? "Sign up failed");
            } catch (e) {
              setState(() => _error = "Sign up failed: $e");
            }
          },
          onBackToLogin: () => Navigator.pop(ctx),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red,
              child: Text(_error, style: const TextStyle(color: Colors.white)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Image.asset("assets/logo.png", height: 100),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email"),
                  onChanged: (v) => _email = v.trim(),
                ),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  onChanged: (v) => _password = v,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openForgotPasswordSheet,
                    child: const Text("Forgot password?"),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          child: const Text("Login"),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: _openSignUpSheet,
                      child: const Text("Sign up"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
