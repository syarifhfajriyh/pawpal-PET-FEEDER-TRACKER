import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  final bool connecting;
  final String errorMessage;
  final void Function(String username, String email, String password)? onSubmit;
  final VoidCallback? onBackToLogin;

  const SignUp({
    super.key,
    this.connecting = false,
    this.errorMessage = "",
    this.onSubmit,
    this.onBackToLogin,
  });

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String _username = "", _email = "", _password = "";

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final barColor = widget.errorMessage.isEmpty
        ? (t.bodyMedium?.color ?? Colors.black54).withOpacity(0.1)
        : Colors.red;

    return Column(
      children: [
        Container(
          height: 30,
          width: double.infinity,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15), topRight: Radius.circular(15),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.errorMessage,
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Image.asset("assets/logo.png", height: 72),
        const SizedBox(height: 8),
        Text("Create Account",
            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Username"),
                onChanged: (v) => _username = v.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => _email = v.trim(),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                onChanged: (v) => _password = v,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                child: widget.connecting
                    ? const Center(child: RefreshProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF0e2a47),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () =>
                            widget.onSubmit?.call(_username, _email, _password),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
              TextButton(
                onPressed: widget.onBackToLogin,
                child: const Text(
                  "Back to login",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
