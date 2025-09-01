import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/FirestoreService.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _auth = FirebaseAuth.instance;
  final _fs = FirestoreService();

  final _nameCtl = TextEditingController();
  final _usernameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _bioCtl = TextEditingController();
  final _petNameCtl = TextEditingController();

  File? _avatarFile;
  String _avatarUrl = '';
  String _petType = 'Cat';
  bool _notifEnabled = true;

  final _petTypes = const ['Cat', 'Dog', 'Rabbit', 'Other'];

  // Image picker
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final u = _auth.currentUser;
    _emailCtl.text = u?.email ?? '';
    _nameCtl.text = u?.displayName ?? '';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final u = _auth.currentUser;
    if (u == null) return;
    try {
      final doc = await _fs.users.doc(u.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _nameCtl.text = data['displayName'] ?? _nameCtl.text;
          _usernameCtl.text = data['username'] ?? '';
          _emailCtl.text = data['email'] ?? _emailCtl.text;
          _bioCtl.text = data['bio'] ?? '';
          _petNameCtl.text = data['petName'] ?? '';
          _petType = data['petType'] ?? _petType;
          _notifEnabled = data['notifEnabled'] ?? _notifEnabled;
          _avatarUrl = data['avatarUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _usernameCtl.dispose();
    _emailCtl.dispose();
    _bioCtl.dispose();
    _petNameCtl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted) return;
    if (x != null) {
      setState(() {
        _avatarFile = File(x.path);
        _avatarUrl = '';
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final x =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
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
                    color: (Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.black54)
                        .withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove photo',
                      style: TextStyle(fontWeight: FontWeight.w700)),
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final u = _auth.currentUser;
    if (u == null) return;

    String? photoUrl = _avatarUrl;

    try {
      if (_avatarFile != null) {
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

      await u.updateDisplayName(_nameCtl.text.trim());
      if (photoUrl.isNotEmpty) {
        await u.updatePhotoURL(photoUrl);
      }

      await _fs.updateMyProfile(
        uid: u.uid,
        displayName: _nameCtl.text.trim(),
        username: _usernameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        bio: _bioCtl.text.trim(),
        notifEnabled: _notifEnabled,
        avatarUrl: photoUrl.isNotEmpty ? photoUrl : null,
      );
      // Persist additional profile fields maintained on the user-facing page.
      await _fs.users.doc(u.uid).update({
        'petName': _petNameCtl.text.trim(),
        'petType': _petType,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    ImageProvider<Object>? avatarProvider() {
      if (_avatarFile != null) return FileImage(_avatarFile!);
      if (_avatarUrl.isNotEmpty) return NetworkImage(_avatarUrl);
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile'),
      ),
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
                          ? const Icon(Icons.person,
                              size: 40, color: Color(0xFF0E2A47))
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
                            child: Icon(Icons.camera_alt,
                                size: 20, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Upload image',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),

              // Display Name
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 12),

              // Username
              TextFormField(
                controller: _usernameCtl,
                decoration: const InputDecoration(labelText: 'Username'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a username'
                    : null,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter an email';
                  }
                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
                  return ok ? null : 'Please enter a valid email';
                },
              ),
              const SizedBox(height: 12),

              // Bio
              TextFormField(
                controller: _bioCtl,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Pet Name + Type
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _petNameCtl,
                      decoration: const InputDecoration(labelText: 'Pet name'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _petType,
                      items: _petTypes
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _petType = v ?? _petType),
                      decoration: const InputDecoration(labelText: 'Pet type'),
                    ),
                  ),
                ],
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

              // --- Account actions ---
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change password',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/change-password');
                },
              ),
              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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
                      onPressed: _saveProfile,
                      child: const Text('Save',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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

class _avatarProvider {}
