// lib/widgets/forgotPassword.dart
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  /// UI-only: parent controls loading and messages.
  final bool connecting;
  final String errorMessage; // shows red bar if non-empty
  final String infoMessage; // shows green bar if non-empty and no error

  /// Callbacks for the two flows:
  /// 1) Send reset link
  final void Function(String username)? onSendReset;

  /// 2) Change password directly
  final void Function(String username, String newPassword)? onChangePassword;

  /// Optional: back to login link
  final VoidCallback? onBackToLogin;

  const ForgotPassword({
    super.key,
    this.connecting = false,
    this.errorMessage = "",
    this.infoMessage = "",
    this.onSendReset,
    this.onChangePassword,
    this.onBackToLogin,
  });

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  String _username = "";
  String _newPassword = "";
  String _confirmPassword = "";

  /// 0 = send link, 1 = change password
  int _mode = 0;

  void _handleSendLink() {
    FocusScope.of(context).unfocus();
    widget.onSendReset?.call(_username.trim());
  }

  void _handleChangePassword() {
    FocusScope.of(context).unfocus();
    // UI-only: basic match check to avoid accidental submits
    if (_newPassword == _confirmPassword && _newPassword.isNotEmpty) {
      widget.onChangePassword?.call(_username.trim(), _newPassword);
    }
    // Else: parent can also surface an error via errorMessage prop
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bodyMed = t.bodyMedium;
    final bodyLg = t.bodyLarge;

    // Top message bar (grey by default; red for error; green for info)
    final Color base = (bodyMed?.color ?? Colors.black54);
    Color barColor = base.withOpacity(0.1);
    if (widget.errorMessage.isNotEmpty) {
      barColor = Colors.red;
    } else if (widget.infoMessage.isNotEmpty) {
      barColor = Colors.green;
    }

    final messageBar = Container(
      width: MediaQuery.of(context).size.width,
      height: 30.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        color: barColor,
      ),
      child: Center(
        child: Text(
          widget.errorMessage.isNotEmpty
              ? widget.errorMessage
              : (widget.infoMessage.isNotEmpty ? widget.infoMessage : ""),
          style: const TextStyle(
            color: Color(0xFFffffff),
            fontWeight: FontWeight.w700,
            fontSize: 14.0,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Column(
        children: [
          Image.asset("assets/logo.png", height: 72),
          const SizedBox(height: 8),
          Text(
            "Forgot Password",
            style: TextStyle(
              color: bodyLg?.color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );

    final modeSwitcher = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Send reset link')),
          ButtonSegment(value: 1, label: Text('Set new password')),
        ],
        selected: {_mode},
        onSelectionChanged: (set) {
          setState(() => _mode = set.first);
        },
      ),
    );

    final usernameField = TextFormField(
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: "",
        labelText: "Username / Email",
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
      onChanged: (v) => _username = v,
    );

    final newPasswordField = TextFormField(
      obscureText: true,
      decoration: InputDecoration(
        hintText: "",
        labelText: "New Password",
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
      onChanged: (v) => _newPassword = v,
    );

    final confirmPasswordField = TextFormField(
      obscureText: true,
      decoration: InputDecoration(
        hintText: "",
        labelText: "Confirm Password",
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
      onChanged: (v) => _confirmPassword = v,
    );

    final sendLinkBtn = SizedBox(
      width: 200,
      child: widget.connecting
          ? const Center(child: RefreshProgressIndicator())
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF0e2a47),
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0.5,
              ),
              onPressed: _handleSendLink,
              child: const Text(
                'Send Reset Link',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                  letterSpacing: 0.4,
                ),
              ),
            ),
    );

    final changePwdBtn = SizedBox(
      width: 200,
      child: widget.connecting
          ? const Center(child: RefreshProgressIndicator())
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF0e2a47),
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0.5,
              ),
              onPressed: (_newPassword.isNotEmpty &&
                      _confirmPassword.isNotEmpty &&
                      _newPassword == _confirmPassword)
                  ? _handleChangePassword
                  : null,
              child: const Text(
                'Change Password',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                  letterSpacing: 0.4,
                ),
              ),
            ),
    );

    final bottomLinks = Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: TextButton(
        onPressed: widget.onBackToLogin,
        child: const Text(
          "Back to login",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );

    return Center(
      child: Column(
        children: [
          messageBar,
          header,
          modeSwitcher,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Form(
              child: Column(
                children: [
                  usernameField,
                  if (_mode == 1) ...[
                    newPasswordField,
                    confirmPasswordField,
                  ],
                  const SizedBox(height: 16),
                  if (_mode == 0) sendLinkBtn else changePwdBtn,
                  bottomLinks,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
