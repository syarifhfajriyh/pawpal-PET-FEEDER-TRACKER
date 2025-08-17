import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Mock profile data (UI-only)
  File? _avatarFile;
  String _displayName = '';
  String _username = '';
  String _email = '';
  String _bio = '';
  String _petName = '';
  String _petType = 'Cat';
  bool _notifEnabled = true;

  final _petTypes = const ['Cat', 'Dog', 'Rabbit', 'Other'];

  // Image picker
  final _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _avatarFile = File(x.path));
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x != null) setState(() => _avatarFile = File(x.path));
  }

  void _removePhoto() {
    setState(() => _avatarFile = null);
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
                // message bar (to match your sheet styling)
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
                  child: const Text(
                    '',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
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

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // UI-only: pretend to save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved (UI-only)')),
    );

    Navigator.pop(context); // go back
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

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
              // Avatar + upload button
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF0E2A47).withOpacity(0.1),
                      backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                      child: _avatarFile == null ? const Icon(Icons.person, size: 40, color: Color(0xFF0E2A47)) : null,
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
              Center(
                child: Text(
                  'Upload image',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),

              // Display Name
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                textInputAction: TextInputAction.next,
                initialValue: _displayName,
                onSaved: (v) => _displayName = v?.trim() ?? '',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 12),

              // Username
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
                textInputAction: TextInputAction.next,
                initialValue: _username,
                onSaved: (v) => _username = v?.trim() ?? '',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a username' : null,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                initialValue: _email,
                onSaved: (v) => _email = v?.trim() ?? '',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter an email';
                  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
                  return ok ? null : 'Please enter a valid email';
                },
              ),
              const SizedBox(height: 12),

              // Bio
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Bio',
                ),
                maxLines: 3,
                initialValue: _bio,
                onSaved: (v) => _bio = v?.trim() ?? '',
              ),
              const SizedBox(height: 12),

              // Pet Name + Type
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Pet name',
                      ),
                      textInputAction: TextInputAction.next,
                      initialValue: _petName,
                      onSaved: (v) => _petName = v?.trim() ?? '',
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
                      onChanged: (v) => setState(() => _petType = v ?? _petType),
                      decoration: const InputDecoration(labelText: 'Pet type'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notifications switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications'),
                subtitle: const Text('Feeding reminders & device alerts'),
                value: _notifEnabled,
                onChanged: (v) => setState(() => _notifEnabled = v),
              ),
              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: _saveProfile,
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
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
