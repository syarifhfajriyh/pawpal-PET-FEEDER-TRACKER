import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screen.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await _firestore.collection('users').get();

      List<Map<String, dynamic>> users = [];

      for (var doc in snapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;

        if (userData['deleted'] == true) continue;
        if (userData['role'] == 'admin') continue;

        users.add({
          'uid': userId,
          'email': userData['email'] ?? '',
          'displayName': userData['displayName'] ?? '',
          'role': userData['role'] ?? 'user',
          'emailVerified': userData['emailVerified'] ?? false,
          'createdAt': userData['createdAt']?.toDate().toString() ?? '',
          'profileImageUrl': userData['profileImageUrl'] ?? '',
        });
      }

      setState(() {
        _users = users;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: $e',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1a1a3d).withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.2))),
          title: Text('Confirm Delete', style: GoogleFonts.poppins(color: Colors.white70)),
          content: Text(
              'Are you sure you want to delete user $email? This action cannot be undone.',
              style: GoogleFonts.poppins(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: GoogleFonts.poppins(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('users').doc(userId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _users.removeWhere((user) => user['uid'] == userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User marked as deleted successfully',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: $e',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_filter == 'verified') {
      return _users.where((user) => user['emailVerified'] == true).toList();
    } else if (_filter == 'unverified') {
      return _users.where((user) => user['emailVerified'] == false).toList();
    }
    return _users;
  }

  @override
  Widget build(BuildContext context) {
    return AdminAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('User Management', style: GoogleFonts.poppins(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadUsers,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilterChip(
                      label: Text('All', style: GoogleFonts.poppins()),
                      selected: _filter == 'all',
                      onSelected: (selected) {
                        setState(() {
                          _filter = selected ? 'all' : _filter;
                        });
                      },
                      selectedColor: Colors.cyan.withOpacity(0.3),
                      checkmarkColor: Colors.white,
                    ),
                    FilterChip(
                      label: Text('Verified', style: GoogleFonts.poppins()),
                      selected: _filter == 'verified',
                      onSelected: (selected) {
                        setState(() {
                          _filter = selected ? 'verified' : _filter;
                        });
                      },
                      selectedColor: Colors.cyan.withOpacity(0.3),
                      checkmarkColor: Colors.white,
                    ),
                    FilterChip(
                      label: Text('Unverified', style: GoogleFonts.poppins()),
                      selected: _filter == 'unverified',
                      onSelected: (selected) {
                        setState(() {
                          _filter = selected ? 'unverified' : _filter;
                        });
                      },
                      selectedColor: Colors.cyan.withOpacity(0.3),
                      checkmarkColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? Center(
                    child: Text(
                      'No users found',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  )
                      : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassmorphicContainer(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                ProfileImageWidget(
                                  userId: user['uid'],
                                  imageUrl: user['profileImageUrl'],
                                  size: 50,
                                  canEdit: false,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['displayName'] ?? 'No name',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        user['email'],
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            user['emailVerified']
                                                ? Icons.verified
                                                : Icons.warning,
                                            color: user['emailVerified']
                                                ? Colors.greenAccent
                                                : Colors.orangeAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            user['emailVerified']
                                                ? 'Verified'
                                                : 'Unverified',
                                            style: GoogleFonts.poppins(
                                              color: user['emailVerified']
                                                  ? Colors.greenAccent
                                                  : Colors.orangeAccent,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.cyan.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.cyan,
                                              ),
                                            ),
                                            child: Text(
                                              user['role'].toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                color: Colors.cyanAccent,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteUser(user['uid'], user['email']),
                                  tooltip: 'Delete User',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminAnimatedBackground extends StatefulWidget {
  final Widget child;
  const AdminAnimatedBackground({super.key, required this.child});

  @override
  State<AdminAnimatedBackground> createState() => _AdminAnimatedBackgroundState();
}

class _AdminAnimatedBackgroundState extends State<AdminAnimatedBackground> with TickerProviderStateMixin {
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
              colors: [Color(0xFF2b0d0d), Color(0xFF3d1a1a)],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.red.withOpacity(0.05)),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}