import 'package:flutter/material.dart';
import 'forgotPassword.dart';
import 'signUp.dart';

class Login extends StatefulWidget {
  /// UI-only: parent controls "loading" and error text.
  final bool connecting;
  final String errorMessage;

  /// Called when user taps Connect.
  final void Function(String username, String password)? onSubmit;

  /// Decide where to go (admin/user) based on username content.
  /// If username contains "@admin" => isAdmin = true.
  final void Function(bool isAdmin)? onRouteDecision;

  /// Optional: If you still want to handle these outside, you can pass callbacks;
  /// but we open sheets inline already.
  final VoidCallback? onSignUp;
  final void Function(String username)? onForgotPassword;

  const Login({
    super.key,
    this.connecting = false,
    this.errorMessage = "",
    this.onSubmit,
    this.onRouteDecision,
    this.onSignUp,
    this.onForgotPassword,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _username = "";
  String _password = "";

  void _handleConnect() {
    FocusScope.of(context).unfocus();

    // 1) notify parent about credentials
    widget.onSubmit?.call(_username, _password);

    // 2) tell parent which view to show next
    final isAdmin = _username.contains('@admin');
    widget.onRouteDecision?.call(isAdmin);
  }

  void _openForgotPasswordSheet() {
    // allow parent to intercept if they want
    widget.onForgotPassword?.call(_username);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: 480,
          color: const Color(0xFF737373),
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              color: Colors.white,
            ),
            child: ForgotPassword(
              connecting: false,
              errorMessage: "",
              infoMessage: "",
              onSendReset: (username) {
                Navigator.pop(ctx);
              },
              onChangePassword: (username, newPwd) {
                Navigator.pop(ctx);
              },
              onBackToLogin: () => Navigator.pop(ctx),
            ),
          ),
        );
      },
    );
  }

  void _openSignUpSheet() {
    // allow parent to intercept if they want
    widget.onSignUp?.call();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: 520,
          color: const Color(0xFF737373),
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              color: Colors.white,
            ),
            child: SignUp(
              connecting: false,
              errorMessage: "",
              onSubmit: (username, email, password) {
                Navigator.pop(ctx);
              },
              onBackToLogin: () => Navigator.pop(ctx),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bodyMed = textTheme.bodyMedium;
    final bodyLg = textTheme.bodyLarge;

    // Top message bar
    final messageBar = Container(
      width: MediaQuery.of(context).size.width,
      height: 30.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        color: widget.errorMessage.isEmpty
            ? (bodyMed?.color ?? Colors.black54).withOpacity(0.1)
            : Colors.red,
      ),
      child: const Center(
        child: Text(
          "", // error text is handled by parent; kept empty for your UI look
          style: TextStyle(
            color: Color(0xFFffffff),
            fontWeight: FontWeight.w700,
            fontSize: 14.0,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    final fields = Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Form(
        child: Column(
          children: [
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "",
                labelText: "Device ID / Username",
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: (bodyMed?.color ?? Colors.black54).withOpacity(0.5),
                  fontSize: 15.0,
                ),
              ),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: bodyLg?.color,
                fontSize: 16.0,
              ),
              onChanged: (v) => _username = v.trim(),
            ),
            TextFormField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: "",
                labelText: "Password",
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: (bodyMed?.color ?? Colors.black54).withOpacity(0.5),
                  fontSize: 15.0,
                ),
              ),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: bodyLg?.color,
                fontSize: 16.0,
              ),
              onChanged: (v) => _password = v,
            ),

            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openForgotPasswordSheet,
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // Connect button
            SizedBox(
              width: 140,
              child: widget.connecting
                  ? const Center(child: RefreshProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF0e2a47),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0.5,
                      ),
                      onPressed: _handleConnect,
                      child: const Text(
                        'Connect',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.0,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            // Don't have an account? Sign up
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(
                    color: bodyMed?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _openSignUpSheet,
                  child: const Text(
                    "Sign up",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Center(
      child: Column(
        children: [
          messageBar,
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
            child: Image.asset("assets/logo.png", height: 100),
          ),
          fields,
        ],
      ),
    );
  }
}
