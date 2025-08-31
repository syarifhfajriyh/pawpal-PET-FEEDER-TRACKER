import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// If these files live in the same "screens" folder, these imports are correct.
// If your paths differ, just adjust them (e.g. 'screens/AdminEditProfile.dart').
import 'AdminEditProfile.dart';
import 'AdminChangePassword.dart';
import 'AdminUserListPage.dart';
import 'AdminUserHistoryPage.dart';
import 'AdminUserStatusPage.dart';

/// Optional: If you have user profile/change pages too, you can import them as fallbacks
/// import 'ProfilePage.dart';
/// import 'ChangePassword.dart';

class HomePageAdmin extends StatelessWidget {
  const HomePageAdmin({
    super.key,

    // header info
    this.adminName,
    this.adminEmail,
    this.avatarUrl,

    // quick stats
    this.totalUsers,
    this.devicesOnline,
    this.errors24h,

    // header menu
    this.onOpenProfile,
    this.onChangePassword,
    this.onSignOut,

    // action cards
    this.onOpenUserList,
    this.onOpenDevices,
    this.onOpenUserHistory,
    this.onOpenUserStatus,
  });

  final String? adminName;
  final String? adminEmail;
  final String? avatarUrl;

  final int? totalUsers;
  final int? devicesOnline;
  final int? errors24h;

  final VoidCallback? onOpenProfile;
  final VoidCallback? onChangePassword;
  final VoidCallback? onSignOut;

  final VoidCallback? onOpenUserList;
  final VoidCallback? onOpenDevices;
  final VoidCallback? onOpenUserHistory;
  final VoidCallback? onOpenUserStatus;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final nowStr = DateFormat('EEE, MMM d').format(DateTime.now());

    // ===== Helpers ===========================================================
    void go(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    // Built-in fallbacks so taps still work even if parent forgot to pass handlers.
    final openProfile = onOpenProfile ??
        () => go(const AdminEditProfilePage()); // change to ProfilePage() if you prefer
    final changePassword = onChangePassword ??
        () => go(const AdminChangePasswordPage()); // change to ChangePassword() if needed
    final signOut = onSignOut ?? () async {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign out failed: $e')),
          );
        }
      }
    };

    final openUserList =
        onOpenUserList ?? () => go(const AdminUserListPage());
    final openDevices = onOpenDevices ??
        () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Devices page not wired yet')),
            );
    final openUserHistory =
        onOpenUserHistory ?? () => go(const AdminUserHistoryPage());
    final openUserStatus =
        onOpenUserStatus ?? () => go(const AdminUserStatusPage());

    // ===== UI ================================================================
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3C4), Color(0xFFFFFFFF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----- TOP BAR -----
                    Row(
                      children: [
                        Image.asset("assets/logo.png", height: 44),
                        const SizedBox(width: 10),
                        Text(
                          "Admin",
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        _TopMenuButtonAdmin(
                          onEditProfile: openProfile,
                          onChangePassword: changePassword,
                          onSignOut: signOut,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ----- WELCOME -----
                    Text(
                      "Welcome, ${adminName?.isNotEmpty == true ? adminName : "Administrator"}",
                      style: t.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(nowStr, style: t.bodySmall),

                    const SizedBox(height: 14),

                    // ----- PROFILE CARD -----
                    Card(
                      color: const Color(0xFFFFF8E1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  (avatarUrl != null && avatarUrl!.isNotEmpty)
                                      ? NetworkImage(avatarUrl!)
                                      : null,
                              backgroundColor:
                                  const Color(0xFFFFD54F).withOpacity(0.20),
                              child: (avatarUrl == null || avatarUrl!.isEmpty)
                                  ? const Icon(Icons.admin_panel_settings,
                                      color: Color(0xFFFFA000), size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    adminName?.isNotEmpty == true
                                        ? adminName!
                                        : "Administrator",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    adminEmail?.isNotEmpty == true
                                        ? adminEmail!
                                        : "admin@pawpal.app",
                                    style: t.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: openProfile,
                              icon: const Icon(Icons.edit),
                              label: const Text("Edit"),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ----- QUICK STATS (responsive grid) -----
                    _StatsGrid(
                      items: [
                        StatItem(
                          icon: Icons.group,
                          label: 'Users',
                          value: (totalUsers ?? 0).toString(),
                        ),
                        StatItem(
                          icon: Icons.wifi_tethering,
                          label: 'Devices online',
                          value: (devicesOnline ?? 0).toString(),
                        ),
                        StatItem(
                          icon: Icons.error_outline,
                          label: 'Errors (24h)',
                          value: (errors24h ?? 0).toString(),
                          valueColor: Colors.red.shade700,
                        ),
                      ],
                      crossAxisCount: isWide ? 3 : 2,
                    ),

                    const SizedBox(height: 16),

                    // ----- ACTIONS (responsive grid) -----
                    _ActionGrid(
                      crossAxisCount: isWide ? 3 : 2,
                      children: [
                        ActionItem(
                          title: 'Users',
                          subtitle: 'List',
                          icon: Icons.people,
                          active: true,
                          onTap: openUserList,
                        ),
                        ActionItem(
                          title: 'Devices',
                          subtitle: 'View',
                          icon: Icons.memory,
                          onTap: openDevices,
                        ),
                        ActionItem(
                          title: 'History',
                          subtitle: 'Logs',
                          icon: Icons.history,
                          onTap: openUserHistory,
                        ),
                        ActionItem(
                          title: 'Status',
                          subtitle: 'Live',
                          icon: Icons.monitor_heart,
                          onTap: openUserStatus,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ----- FAB -----
        floatingActionButton: FloatingActionButton.extended(
          onPressed: openUserList,
          icon: const Icon(Icons.people),
          label:
              const Text('User List', style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFFFB300),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

// ===== Top-right menu =====
class _TopMenuButtonAdmin extends StatelessWidget {
  const _TopMenuButtonAdmin({
    required this.onEditProfile,
    required this.onChangePassword,
    this.onSignOut,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AdminMenuAction>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        switch (v) {
          case _AdminMenuAction.editProfile:
            onEditProfile.call();
            break;
          case _AdminMenuAction.changePassword:
            onChangePassword.call();
            break;
          case _AdminMenuAction.signOut:
            onSignOut?.call();
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: _AdminMenuAction.editProfile,
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Profile'),
          ),
        ),
        const PopupMenuItem(
          value: _AdminMenuAction.changePassword,
          child: ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
          ),
        ),
        if (onSignOut != null) const PopupMenuDivider(),
        if (onSignOut != null)
          const PopupMenuItem(
            value: _AdminMenuAction.signOut,
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign out'),
            ),
          ),
      ],
    );
  }
}

enum _AdminMenuAction { editProfile, changePassword, signOut }

// ===== Stats Grid =====
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.items,
    this.crossAxisCount = 3,
  });

  final List<StatItem> items;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.4,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        final text = Theme.of(context).textTheme;
        return Card(
          color: const Color(0xFFFFF8E1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(it.icon, size: 18),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.label, style: text.bodyMedium),
                    Text(
                      it.value,
                      style: TextStyle(
                        color: it.valueColor ?? Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StatItem {
  const StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}

// ===== Action Grid =====
class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.children,
    this.crossAxisCount = 2,
  });

  final List<ActionItem> children;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.35,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: children
          .map((e) => _ActionCardAdmin(
                title: e.title,
                subtitle: e.subtitle,
                icon: e.icon,
                active: e.active,
                onTap: e.onTap,
              ))
          .toList(),
    );
  }
}

class ActionItem {
  const ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.active = false,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
}

// ===== Action tile =====
class _ActionCardAdmin extends StatelessWidget {
  const _ActionCardAdmin({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.active = false,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFFFC107) : const Color(0xFFFFF8E1);
    final fg = active ? Colors.white : Colors.grey[800];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: fg),
                const SizedBox(height: 8),
                Text(title,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, color: fg)),
                Text(subtitle,
                    style: TextStyle(
                        color: active ? Colors.white : Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Duplicate placeholder pages removed. Concrete implementations live in:
// - AdminUserListPage.dart
// - AdminUserHistoryPage.dart
// - AdminUserStatusPage.dart
