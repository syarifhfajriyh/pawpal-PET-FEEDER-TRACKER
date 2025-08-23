import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePageAdmin extends StatelessWidget {
  const HomePageAdmin({
    super.key,

    // header
    this.adminName,
    this.adminEmail,
    this.avatarUrl,

    // quick stats
    this.totalUsers,
    this.devicesOnline,
    this.errors24h,

    // actions (wire these in main.dart)
    this.onOpenProfile,
    this.onOpenUserList,
    this.onOpenUserHistory,
    this.onOpenUserStatus,
    this.onSignOut,
  });

  final String? adminName;
  final String? adminEmail;
  final String? avatarUrl;

  final int? totalUsers;
  final int? devicesOnline;
  final int? errors24h;

  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenUserList;
  final VoidCallback? onOpenUserHistory;
  final VoidCallback? onOpenUserStatus;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final nowStr = DateFormat('EEE, MMM d').format(DateTime.now());

    // ----- TOP BAR (logo + menu) -----
    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 8, 12),
      child: Row(
        children: [
          Image.asset("assets/logo.png", height: 36),
          const Spacer(),
          _TopMenuButtonAdmin(
  onSignOut: onSignOut,
),

        ],
      ),
    );

    // ----- WELCOME -----
    final welcome = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome, Admin", style: t.bodyLarge),
          const SizedBox(height: 6),
          Text(nowStr, style: t.bodyMedium),
        ],
      ),
    );

    // ----- PROFILE SECTION CARD -----
    final profileCard = Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Card(
    color: const Color(0xFFE3F2FD), // light blue surface ✅
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? NetworkImage(avatarUrl!)
                    : null,
                backgroundColor: const Color(0xFF1565C0).withOpacity(0.08),
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? const Icon(Icons.admin_panel_settings, color: Color(0xFF1565C0), size: 28)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(adminName?.isNotEmpty == true ? adminName! : "Administrator",
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(adminEmail?.isNotEmpty == true ? adminEmail! : "admin@pawpal.app",
                        style: t.bodyMedium),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onOpenProfile,
                icon: const Icon(Icons.edit),
                label: const Text("Edit"),
              ),
            ],
          ),
        ),
      ),
    );

    // ----- QUICK STATS (like your MetricCards) -----
    final statsRow = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _MetricCardAdmin(
            icon: Icons.group,
            label: "Users",
            value: (totalUsers ?? 0).toString(),
          ),
          const SizedBox(width: 12),
          _MetricCardAdmin(
            icon: Icons.wifi_tethering,
            label: "Devices online",
            value: (devicesOnline ?? 0).toString(),
          ),
          const SizedBox(width: 12),
          _MetricCardAdmin(
            icon: Icons.error_outline,
            label: "Errors (24h)",
            value: (errors24h ?? 0).toString(),
            valueColor: Colors.red.shade600,
          ),
        ],
      ),
    );

    // ----- ACTIONS (User list / history / status) -----
    final actionRow = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionCardAdmin(
            title: "Users",
            subtitle: "List",
            icon: Icons.people,
            onTap: onOpenUserList,
            active: true,
          ),
          _ActionCardAdmin(
            title: "User",
            subtitle: "History",
            icon: Icons.history,
            onTap: onOpenUserHistory,
          ),
          _ActionCardAdmin(
            title: "User",
            subtitle: "Status",
            icon: Icons.monitor_heart,
            onTap: onOpenUserStatus,
          ),
        ],
      ),
    );

    // (optional) FAB – you can rewire this to “Add User” if you want
    final fab = FloatingActionButton.extended(
      onPressed: onOpenUserList,
      icon: const Icon(Icons.people),
      label: const Text('User List', style: TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,


    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            topBar,
            welcome,
            profileCard,
            statsRow,
            actionRow,
          ],
        ),
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ===== Top menu (Profile / Sign out) =====
class _TopMenuButtonAdmin extends StatelessWidget {
  const _TopMenuButtonAdmin({this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AdminMenuAction>(
      icon: const Icon(Icons.menu),
      onSelected: (v) {
        if (v == _AdminMenuAction.signOut) onSignOut?.call();
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(
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

enum _AdminMenuAction { signOut }


// ===== Reusable cards (same look as Home) =====
class _MetricCardAdmin extends StatelessWidget {
  const _MetricCardAdmin({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
    child: Card(
    color: const Color(0xFFE3F2FD), // light blue surface
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(

          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.bodyMedium),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.black,
                      fontWeight: FontWeight.bold,
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

class _ActionCardAdmin extends StatelessWidget {
  const _ActionCardAdmin({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: active ? const Color(0xFF90CAF9) : Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: 100,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? Colors.white : Colors.grey[800]),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Optional placeholder pages (UI-only) =====
// You can delete these and use your own pages if you prefer.
class AdminUserListPage extends StatelessWidget {
  const AdminUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mock = List.generate(12, (i) => 'User #${i + 1}');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Users'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: mock.length,
        itemBuilder: (_, i) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(child: Text(mock[i].substring(5, 6))),
            title: Text(mock[i], style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Devices: ${2 + (i % 3)}', style: t.bodyMedium),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Open ${mock[i]} details (UI-only)')),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AdminUserHistoryPage extends StatelessWidget {
  const AdminUserHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('User History'),
      ),
      body: const Center(child: Text('Filter by user + show history (UI-only)')),
    );
  }
}

class AdminUserStatusPage extends StatelessWidget {
  const AdminUserStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('User Status'),
      ),
      body: const Center(child: Text('Online/offline, battery, last feed (UI-only)')),
    );
  }
}
