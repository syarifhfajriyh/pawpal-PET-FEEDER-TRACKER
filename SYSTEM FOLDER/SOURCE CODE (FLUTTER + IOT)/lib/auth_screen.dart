import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart' show HomePage;


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(uid).get();
      return userDoc['role'] ?? 'user';
    } catch (e) {
      print('Error getting user role: $e');
      return 'user';
    }
  }


  Future<String?> getUserDisplayName(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(uid).get();
      return userDoc['displayName'] as String?;
    } catch (e) {
      print('Error getting user display name: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(uid).get();
      return userDoc.data();
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'displayName': displayName,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'profileImageUrl': '',
          'emailVerified': user.emailVerified,
        });

        await _firestore.collection('users').doc(user.uid).collection('device_status').doc('status_doc').set({
          'foodLevel': 'High',
          'catDetected': false,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('users').doc(user.uid).collection('feeding_history').doc('initial_doc').set({'initial': true});
        await _firestore.collection('users').doc(user.uid).collection('detection_history').doc('initial_doc').set({'initial': true});
        await _firestore.collection('users').doc(user.uid).collection('scheduled_feedings').doc('initial_doc').set({'initial': true});
        await _firestore.collection('users').doc(user.uid).collection('food_level_history').doc('initial_doc').set({'initial': true});
      }

      await userCredential.user?.sendEmailVerification();

      await _auth.signOut();

      return userCredential;

    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<UserCredential> signUpOld(String email, String password, String? name) async {
    return await signUp(
      email: email,
      password: password,
      displayName: name ?? '',
    );
  }

  Future<UserCredential> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

    if (userCredential.user != null) {
      await _updateUserVerificationStatus(userCredential.user!);
    }

    return userCredential;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> _updateUserVerificationStatus(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'emailVerified': user.emailVerified,
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await _firestore.collection('users').get();

      List<Map<String, dynamic>> users = [];
      for (var doc in snapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;

        if (userData['role'] == 'admin' || userData['deleted'] == true) {
          continue;
        }

        users.add({
          'uid': userId,
          'email': userData['email'] ?? '',
          'displayName': userData['displayName'] ?? '',
        });
      }
      return users;
    } catch (e) {
      print('Error loading users: $e');
      return [];
    }
  }
}

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
      app: Firebase.app(),
      bucket: 'petfeeder1-713c0.appspot.com'
  );
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    var status = await Permission.photos.request();
    if (status.isDenied) {
      return null;
    }

    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        return File(image.path);
      }
    }

    return null;
  }

  Future<String> uploadProfileImage(File image, String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');

      await ref.putFile(image);

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}


class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0d0d2b), Color(0xFF1a1a3d)],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.black.withValues(alpha:0.1)),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  const GlassmorphicContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha:0.05),
                Colors.white.withValues(alpha:0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.1),
              width: 1.0,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: child,
          ),
        ),
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String>? validator;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.isVisible,
    required this.onToggleVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
          onPressed: onToggleVisibility,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha:0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.pinkAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
        ),
        errorStyle: GoogleFonts.poppins(color: Colors.pinkAccent),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha:0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.pinkAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
        ),
        errorStyle: GoogleFonts.poppins(color: Colors.pinkAccent),
      ),
      validator: validator,
    );
  }
}

class ProfileImageWidget extends StatefulWidget {
  final String userId;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;
  final bool canEdit;

  const ProfileImageWidget({
    super.key,
    required this.userId,
    this.imageUrl,
    this.size = 100,
    this.onTap,
    this.canEdit = false,
  });

  @override
  State<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha:0.3), width: 2),
            ),
            child: ClipOval(
              child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: widget.imageUrl!,
                placeholder: (context, url) => Container(
                  color: Colors.white.withValues(alpha:0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => _buildPlaceholder(),
                fit: BoxFit.cover,
              )
                  : _buildPlaceholder(),
            ),
          ),
          if (widget.canEdit)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha:0.1),
      child: const Center(
        child: Icon(Icons.person, color: Colors.white70, size: 40),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  bool _isLogin = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleForm() {
    _animationController.reverse().then((_) {
      setState(() => _isLogin = !_isLogin);
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassmorphicContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(animation);
                    return FadeTransition(opacity: animation, child: SlideTransition(position: offsetAnimation, child: child));
                  },
                  child: _isLogin
                      ? AuthForm(key: const ValueKey('login'), isLogin: true, onToggle: _toggleForm)
                      : AuthForm(key: const ValueKey('signup'), isLogin: false, onToggle: _toggleForm),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final VoidCallback onToggle;
  const AuthForm({super.key, required this.isLogin, required this.onToggle});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    if (!widget.isLogin && _passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.isLogin) {
        final userCredential = await _authService.signIn(
            _emailController.text.trim(),
            _passwordController.text.trim());

        final userRole = await _authService.getUserRole(userCredential.user!.uid);

        if (userRole != 'admin' && !userCredential.user!.emailVerified) {
          _showEmailNotVerifiedDialog(userCredential.user!);
          await _authService.signOut();
          return;
        }


        if (mounted) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage())
          );
        }
      } else {

        final userCredential = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );


        _showVerificationSentDialog(userCredential.user!);


        widget.onToggle();
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? 'An unknown error occurred.');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1a1a3d).withValues(alpha:0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha:0.2))),
          title: Text('Authentication Failed', style: GoogleFonts.poppins(color: Colors.white70)),
          content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK', style: GoogleFonts.poppins(color: Colors.cyanAccent)),
            )
          ],
        ),
      ),
    );
  }

  void _showEmailNotVerifiedDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1a1a3d).withValues(alpha:0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha:0.2))),
          title: Text('Email Not Verified', style: GoogleFonts.poppins(color: Colors.white70)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please verify your email address before logging in.', style: GoogleFonts.poppins(color: Colors.white)),
              const SizedBox(height: 16),
              Text('Verification email sent to: ${user.email}', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha:0.7))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK', style: GoogleFonts.poppins(color: Colors.cyanAccent)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _resendVerificationEmail(user);
              },
              child: Text('Resend Email', style: GoogleFonts.poppins(color: Colors.cyanAccent)),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationSentDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1a1a3d).withValues(alpha:0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha:0.2))),
          title: Text('Verification Email Sent', style: GoogleFonts.poppins(color: Colors.white70)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please check your email to verify your account.', style: GoogleFonts.poppins(color: Colors.white)),
              const SizedBox(height: 16),
              Text('Sent to: ${user.email}', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha:0.7))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onToggle();
              },
              child: Text('OK', style: GoogleFonts.poppins(color: Colors.cyanAccent)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _resendVerificationEmail(user);
              },
              child: Text('Resend', style: GoogleFonts.poppins(color: Colors.cyanAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resendVerificationEmail(User user) async {
    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent!', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send verification email: $e', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1a1a3d).withValues(alpha:0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha:0.2))),
          title: Text('Reset Password', style: GoogleFonts.poppins(color: Colors.white70)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter your email address to receive a password reset link.', style: GoogleFonts.poppins(color: Colors.white)),
              const SizedBox(height: 16),
              CustomTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val!.isEmpty || !val.contains('@') ? 'Enter a valid email' : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _authService.sendPasswordResetEmail(email);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset link sent to $email', style: GoogleFonts.poppins(color: Colors.white)),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                } catch (e) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send reset email: $e', style: GoogleFonts.poppins(color: Colors.white)),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text('Send Reset Link', style: GoogleFonts.poppins(color: Colors.cyanAccent)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.isLogin ? 'Welcome Back' : 'Create Account',
          style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          widget.isLogin ? 'Login with your credentials' : 'Sign up to get started',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withValues(alpha:0.7)),
        ),
        const SizedBox(height: 48),
        Form(
          key: _formKey,
          child: Column(
            children: [
              if (!widget.isLogin) ...[
                CustomTextField(
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.text,
                  validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 24),
              ],
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val!.isEmpty || !val.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 24),
              PasswordField(
                controller: _passwordController,
                label: 'Password',
                isVisible: _passwordVisible,
                onToggleVisibility: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
                validator: (val) => val!.isEmpty || val.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 24),
              if (!widget.isLogin)
                PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  isVisible: _confirmPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    });
                  },
                  validator: (val) => val!.isEmpty || val.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
              if (!widget.isLogin) const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                    textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                      : Text(widget.isLogin ? 'Login' : 'Sign Up', style: GoogleFonts.poppins()),
                ),
              ),
              if (widget.isLogin) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(color: Colors.cyanAccent),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              widget.isLogin ? 'Don\'t have an account?' : 'Already have an account?',
              style: GoogleFonts.poppins(color: Colors.white.withValues(alpha:0.7)),
            ),
            TextButton(
              onPressed: widget.onToggle,
              child: Text(
                widget.isLogin ? 'Sign Up' : 'Login',
                style: GoogleFonts.poppins(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}