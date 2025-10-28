import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screen.dart';
import 'admin_users_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _imageService = ImageService();
  final _authService = AuthService();

  final _displayNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _isEditingName = false;
  bool _isChangingPassword = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  Map<String, dynamic>? _userData;
  String? _profileImageUrl;
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userData = await _authService.getUserData(user.uid);
        final userRole = await _authService.getUserRole(user.uid);
        setState(() {
          _userData = userData;
          _profileImageUrl = userData?['profileImageUrl'] ?? '';
          _userRole = userRole;
          _displayNameController.text = user.displayName ?? userData?['displayName'] ?? '';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user data: $e', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.poppins()),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign Out', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _auth.signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthPage()),
              (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDisplayName() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await user.updateDisplayName(_displayNameController.text.trim());

      await _authService.updateUserProfile(user.uid, {
        'displayName': _displayNameController.text.trim(),
      });

      setState(() {
        _isEditingName = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Display name updated successfully!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update display name: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      final email = user?.email ?? '';

      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );

      await user?.reauthenticateWithCredential(credential);


      await user?.updatePassword(_newPasswordController.text);

      setState(() {
        _isChangingPassword = false;
      });

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to change password';
      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        errorMessage = 'New password is too weak';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage: ${e.message}', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change password: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final imageFile = await _imageService.pickImage();
      if (imageFile == null) return;

      final imageUrl = await _imageService.uploadProfileImage(imageFile, user.uid);

      await _authService.updateUserProfile(user.uid, {
        'profileImageUrl': imageUrl,
      });

      setState(() {
        _profileImageUrl = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _imageService.deleteProfileImage(user.uid);

      await _authService.updateUserProfile(user.uid, {
        'profileImageUrl': '',
      });

      setState(() {
        _profileImageUrl = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture removed successfully!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove image: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Text('Profile', style: GoogleFonts.poppins(color: Colors.white)),
              if (_userRole == 'admin')
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ADMIN',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      ProfileImageWidget(
                        userId: user?.uid ?? '',
                        imageUrl: _profileImageUrl,
                        size: 120,
                        canEdit: true,
                        onTap: _uploadProfileImage,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.cyanAccent,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.black),
                            onPressed: _uploadProfileImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_userRole == 'admin')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        'Administrator Account',
                        style: GoogleFonts.poppins(
                          color: Colors.red[100],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    TextButton(
                      onPressed: _removeProfileImage,
                      child: Text(
                        'Remove Picture',
                        style: GoogleFonts.poppins(color: Colors.redAccent),
                      ),
                    ),

                  const SizedBox(height: 16),

                  Text(
                    user?.email ?? 'No email',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withValues(alpha:0.7)),
                  ),
                  const SizedBox(height: 32),

                  GlassmorphicContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Display Name',
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isEditingName ? Icons.cancel : Icons.edit,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isEditingName = !_isEditingName;
                                    if (!_isEditingName) {
                                      _displayNameController.text = user?.displayName ?? _userData?['displayName'] ?? '';
                                    }
                                  });
                                },
                              ),
                            ],
                          ),

                          if (_isEditingName) ...[
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  CustomTextField(
                                    controller: _displayNameController,
                                    label: 'Display Name',
                                    icon: Icons.person,
                                    keyboardType: TextInputType.text,
                                    validator: (val) => val!.isEmpty ? 'Enter a display name' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _updateDisplayName,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyanAccent,
                                        foregroundColor: Colors.black87,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      ),
                                      child: Text('Save Name', style: GoogleFonts.poppins()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              user?.displayName ?? _userData?['displayName'] ?? 'No display name set',
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  GlassmorphicContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Change Password',
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              IconButton(
                                icon: Icon(
                                  _isChangingPassword ? Icons.cancel : Icons.lock,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isChangingPassword = !_isChangingPassword;
                                    if (!_isChangingPassword) {
                                      _currentPasswordController.clear();
                                      _newPasswordController.clear();
                                      _confirmPasswordController.clear();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),

                          if (_isChangingPassword) ...[
                            const SizedBox(height: 16),
                            Form(
                              key: _passwordFormKey,
                              child: Column(
                                children: [
                                  PasswordField(
                                    controller: _currentPasswordController,
                                    label: 'Current Password',
                                    isVisible: _currentPasswordVisible,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _currentPasswordVisible = !_currentPasswordVisible;
                                      });
                                    },
                                    validator: (val) => val!.isEmpty ? 'Enter your current password' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  PasswordField(
                                    controller: _newPasswordController,
                                    label: 'New Password',
                                    isVisible: _newPasswordVisible,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _newPasswordVisible = !_newPasswordVisible;
                                      });
                                    },
                                    validator: (val) => val!.isEmpty || val.length < 6 ? 'Password must be at least 6 characters' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  PasswordField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm New Password',
                                    isVisible: _confirmPasswordVisible,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _confirmPasswordVisible = !_confirmPasswordVisible;
                                      });
                                    },
                                    validator: (val) => val!.isEmpty || val.length < 6 ? 'Password must be at least 6 characters' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _changePassword,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyanAccent,
                                        foregroundColor: Colors.black87,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      ),
                                      child: Text('Change Password', style: GoogleFonts.poppins()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'Click the lock icon to change your password',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  GlassmorphicContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Information',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Email', user?.email ?? 'N/A'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Account Type', _userRole.toUpperCase()),
                          const SizedBox(height: 12),
                          _buildInfoRow('Email Verified', user?.emailVerified ?? false ? 'Yes' : 'No'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Account Created', user?.metadata.creationTime?.toString().split(' ')[0] ?? 'N/A'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Last Sign In', user?.metadata.lastSignInTime?.toString().split(' ')[0] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),

                  if (_userRole == 'admin') ...[
                    const SizedBox(height: 24),
                    GlassmorphicContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Tools',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const AdminUsersPage()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: Text('User Management', style: GoogleFonts.poppins()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text('Sign Out', style: GoogleFonts.poppins(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withValues(alpha:0.7)),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }
}