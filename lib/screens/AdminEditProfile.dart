import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../services/AuthService.dart';
import '../services/FirestoreService.dart';

class AdminEditProfilePage extends StatefulWidget {
  const AdminEditProfilePage({super.key});

  @override
  State<AdminEditProfilePage> createState() => _AdminEditProfilePageState();
}

class _AdminEditProfilePageState extends State<AdminEditProfilePage> {
  final _auth = AuthService();
  final _fs = FirestoreService();

  final _formKey = GlobalKey<FormState>();

  final _nameCtl = TextEditingController();
  final _usernameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _bioCtl = TextEditingController();

  File? _avatarFile;
  String _avatarUrl = '';
  bool _notifEnabled = true;

  final _picker = ImagePicker();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = _auth.currentUser;
    _emailCtl.text = u?.email ?? '';
    _nameCtl.text = u?.displayName ?? (u?.email?.split('@').first ?? '');
    _avatarUrl = u?.photoURL ?? '';
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _usernameCtl.dispose();
    _emailCtl.dispose();
    _bioCtl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final u = _auth.currentUser;
    if (u == null) return;
    try {
      final doc = await _fs.users.doc(u.uid).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _usernameCtl.text = (data['username'] ?? '').toString();
        _emailCtl.text = (data['email'] ?? _emailCtl.text).toString();
        _bioCtl.text = (data['bio'] ?? '').toString();
        _notifEnabled = (data['notifEnabled'] ?? _notifEnabled) as bool;
        _avatarUrl = (data['avatarUrl'] ?? _avatarUrl).toString();
      });
    } catch (e) {
      debugPrint('Failed to load admin profile: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted) return;
    if (x != null) {
      setState(() {
        _avatarFile = File(x.path);
        _avatarUrl = '';
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted) return;
    if (x != null) {
      setState(() {
        _avatarFile = File(x.path);
        _avatarUrl = '';
      });
    }
  }

  void _removePhoto() {
    setState(() {
      _avatarFile = null;
      _avatarUrl = '';
    });
  }

  void _openPhotoActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0x00000000),
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 240,
        color: const Color(0xFF737373),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  height: 30,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final u = _auth.currentUser!;
    setState(() => _saving = true);
    try {
      String? photoUrl = _avatarUrl;

      if (_avatarFile != null) {
        // Upload to a per-user folder path and set content-type metadata.
        final String ext = _avatarFile!.path.split('.').last.toLowerCase();
        final String mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
        final path = 'avatars/${u.uid}/profile.${ext.isEmpty ? 'jpg' : ext}';
        final ref = FirebaseStorage.instance.ref(path);
        try {
          await ref.putFile(
            _avatarFile!,
            SettableMetadata(contentType: mime),
          );
        } on FirebaseException catch (e) {
          debugPrint('Storage upload failed [${e.code}] path=$path');
          rethrow;
        }
        photoUrl = await ref.getDownloadURL();
      }

      // Update Firebase Auth profile
      await _auth.updateDisplayName(_nameCtl.text.trim());
      if (photoUrl.isNotEmpty) {
        await _auth.updatePhotoUrl(photoUrl);
      }

      // Mirror to Firestore
      await _fs.updateMyProfile(
        uid: u.uid,
        displayName: _nameCtl.text.trim(),
        username: _usernameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        bio: _bioCtl.text.trim(),
        notifEnabled: _notifEnabled,
        avatarUrl: photoUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? avatarProvider() {
      if (_avatarFile != null) return FileImage(_avatarFile!);
      if (_avatarUrl.isNotEmpty) return NetworkImage(_avatarUrl);
      return null;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF0E2A47).withOpacity(0.1),
                      backgroundImage: avatarProvider(),
                      child: _avatarFile == null && _avatarUrl.isEmpty
                          ? const Icon(Icons.person, size: 40, color: Color(0xFF0E2A47))
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: const Color(0xFFFFC34D),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _openPhotoActions,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.camera_alt, size: 20, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Upload image', style: TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),

              // Username
              TextFormField(
                controller: _usernameCtl,
                decoration: const InputDecoration(labelText: 'Username'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // Email (read-only here)
              TextFormField(
                controller: _emailCtl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),

              // Bio
              TextFormField(
                controller: _bioCtl,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Notifications
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications'),
                subtitle: const Text('Feeding reminders & device alerts'),
                value: _notifEnabled,
                onChanged: (v) => setState(() => _notifEnabled = v),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: const Color(0xFF0E2A47),
                        elevation: 0.5,
                      ),
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Save', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
