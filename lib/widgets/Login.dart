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
      final cred = await _auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );
      final user = cred.user;

      if (user == null) {
        setState(() => _error = "Login failed");
        return;
      }

      // Rely on server-side verification and role from Firestore.
      // Optionally keep client-side UX to prompt email verification.
      if (!user.emailVerified) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VerifyEmail()),
        );
        // User returns and taps Login again after verifying
        return;
      }

      if (!mounted) return;
      // Reset to root; _Root will render User home via auth listener
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
        String errorMessage = "";
        String infoMessage = "";
        bool connecting = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> handleSendLink(String email) async {
              setSheetState(() {
                connecting = true;
                errorMessage = "";
                infoMessage = "";
              });
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email.trim());
                setSheetState(() {
                  infoMessage = "Password reset link sent";
                });
              } on FirebaseAuthException catch (e) {
                setSheetState(() {
                  errorMessage =
                      e.message ?? "Failed to send password reset email";
                });
              } catch (e) {
                setSheetState(() {
                  errorMessage = "Failed to send password reset email: $e";
                });
              } finally {
                setSheetState(() => connecting = false);
              }
            }

            Future<void> handleChangePassword(
                String email, String newPwd) async {
              setSheetState(() {
                connecting = true;
                errorMessage = "";
                infoMessage = "";
              });
              try {
                final auth = FirebaseAuth.instance;
                final credential = EmailAuthProvider.credential(
                    email: email.trim(), password: _password);
                User? user = auth.currentUser;
                if (user == null) {
                  final signInCred =
                      await auth.signInWithCredential(credential);
                  user = signInCred.user;
                } else {
                  await user.reauthenticateWithCredential(credential);
                }
                await user?.updatePassword(newPwd);
                setSheetState(() {
                  infoMessage = "Password updated";
                });
              } on FirebaseAuthException catch (e) {
                setSheetState(() {
                  errorMessage = e.message ?? "Failed to change password";
                });
              } catch (e) {
                setSheetState(
                    () => errorMessage = "Failed to change password: $e");
              } finally {
                setSheetState(() => connecting = false);
              }
            }

            return ForgotPassword(
              connecting: connecting,
              errorMessage: errorMessage,
              infoMessage: infoMessage,
              onSendReset: handleSendLink,
              onChangePassword: handleChangePassword,
              onBackToLogin: () => Navigator.pop(ctx),
            );
          },
        );
      },
    );
  }

  void _openSignUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String errorMessage = "";
        bool connecting = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> handleSubmit(String username, String email, String password) async {
              // Simple client validation for quicker feedback
              if (email.trim().isEmpty) {
                setSheetState(() => errorMessage = 'Please enter an email.');
                return;
              }
              if (password.length < 6) {
                setSheetState(() => errorMessage = 'Password must be at least 6 characters.');
                return;
              }
              setSheetState(() {
                errorMessage = "";
                connecting = true;
              });
              try {
                final cred = await _auth.createUserWithEmailAndPassword(
                  email: email.trim(),
                  password: password,
                );
                await cred.user?.sendEmailVerification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification email sent to ${email.trim()}')),
                  );
                }

                if (!mounted) return;
                Navigator.pop(ctx); // close SignUp sheet
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerifyEmail()),
                );
              } on FirebaseAuthException catch (e) {
                final msg = e.message ?? 'Sign up failed';
                setSheetState(() => errorMessage = '${e.code}: $msg');
              } catch (e) {
                setSheetState(() => errorMessage = 'Sign up failed: $e');
              } finally {
                setSheetState(() => connecting = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SignUp(
                connecting: connecting,
                errorMessage: errorMessage,
                onSubmit: handleSubmit,
                onBackToLogin: () => Navigator.pop(ctx),
              ),
            );
          },
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
