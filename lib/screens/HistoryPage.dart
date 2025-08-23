import 'package:flutter/material.dart';

class HomePageView extends StatelessWidget {
  const HomePageView({
    Key? key,
    required this.isAuthorizing,
    this.errorMessage,
    this.onRetryAuthorize,

    // profile & history navigation
    this.onOpenProfile,
    this.onOpenHistory,
    this.onSignOut,

    // status data
    this.username,
    this.avatarUrl,
    this.foodWeightGrams,
    this.catDetected = false,

    // quick actions
    this.onDispense,
    this.onSchedule,
    this.onConnectDevice,

    // empty-state props
    this.showEmptyState = false,
    this.emptyImageAsset,
    this.emptyText,
  }) : super(key: key);

  final bool isAuthorizing;
  final String? errorMessage;
  final VoidCallback? onRetryAuthorize;

  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onSignOut;

  final String? username;
  final String? avatarUrl;
  final int? foodWeightGrams;
  final bool catDetected;

  final VoidCallback? onDispense;
  final VoidCallback? onSchedule;
  final VoidCallback? onConnectDevice;

  final bool showEmptyState;
  final String? emptyImageAsset;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final bool showingBusyOrError = isAuthorizing || errorMessage != null;
    final text = Theme.of(context).textTheme;

    // ---------- TOP BAR ----------
    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 8, 12),
      child: Row(
        children: [
          Image.asset("assets/logo.png", height: 48), // logo a bit larger
          const Spacer(),
          _TopMenuButton(
            onProfile: onOpenProfile,
            onHistory: onOpenHistory,
            onSignOut: onSignOut,
          ),
        ],
      ),
    );

    // ---------- STATUS ----------
    final statusStrip = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (username != null)
          Row(
            children: [
              CircleAvatar(
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                radius: 16,
                child: avatarUrl == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 8),
              Text("Hi, $username", style: text.bodyLarge),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricCard(
              icon: Icons.scale,
              label: "Food Left",
              value: foodWeightGrams != null ? "${foodWeightGrams}g" : "—",
            ),
            const SizedBox(width: 12),
            _MetricCard(
              icon: catDetected ? Icons.pets : Icons.pets_outlined,
              label: "Cat",
              value: catDetected ? "Detected" : "Not detected",
              valueColor: catDetected ? Colors.green : text.bodyMedium?.color,
            ),
          ],
        ),
      ],
    );

    // ---------- QUICK ACTIONS ----------
    final quickActions = Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionCard(
            title: "Dispense",
            subtitle: "Food",
            icon: Icons.restaurant,
            onTap: onDispense,
          ),
          _ActionCard(
            title: "Schedule",
            subtitle: "Feed",
            icon: Icons.timer,
            onTap: onSchedule, // callback from main.dart
            active: true,      // highlighted in blue now
          ),
          _ActionCard(
            title: "Connect",
            subtitle: "Device",
            icon: Icons.wifi_tethering,
            onTap: onConnectDevice,
          ),
        ],
      ),
    );

    // ---------- BODY ----------
    Widget body;
    if (showingBusyOrError) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (errorMessage == null)
              const CircularProgressIndicator()
            else
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 10),
            Text(
              errorMessage ?? "Authorizing",
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (errorMessage != null && onRetryAuthorize != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetryAuthorize,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
            ],
          ],
        ),
      );
    } else if (showEmptyState) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emptyImageAsset != null)
              Image.asset(emptyImageAsset!, height: 170),
            const SizedBox(height: 24),
            Text(
              emptyText ?? "Voops! Couldn't find any PawFeeder.",
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      body = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            topBar,
            statusStrip,
            quickActions,
          ],
        ),
      );
    }

    // ---------- FAB ----------
    final fab = FloatingActionButton.extended(
      onPressed: showEmptyState ? onConnectDevice : onSchedule,
      icon: const Icon(Icons.add),
      label: Text(
        showEmptyState ? 'PawFeeder' : 'Schedule',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      backgroundColor: const Color.fromARGB(255, 2, 42, 76), // blue FAB
      foregroundColor: const Color.fromARGB(255, 236, 225, 70),
    );

    // ---------- GRADIENT WRAPPER ----------
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFA9D3FF), // icier blue top
            Color(0xFFEFF6FF), // soft ice bottom
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // let the gradient show
        body: body,
        floatingActionButton: fab,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  } // CLOSE build()
} // CLOSE class HomePageView

class _TopMenuButton extends StatelessWidget {
  const _TopMenuButton({
    this.onProfile,
    this.onHistory,
    this.onSignOut,
  });

  final VoidCallback? onProfile;
  final VoidCallback? onHistory;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TopMenuAction>(
      icon: const Icon(Icons.menu),
      onSelected: (v) {
        switch (v) {
          case _TopMenuAction.profile:
            onProfile?.call();
            break;
          case _TopMenuAction.history:
            onHistory?.call();
            break;
          case _TopMenuAction.signOut:
            onSignOut?.call();
            break;
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(
          value: _TopMenuAction.profile,
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text("Profile"),
          ),
        ),
        PopupMenuItem(
          value: _TopMenuAction.history,
          child: ListTile(
            leading: Icon(Icons.history),
            title: Text("History"),
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _TopMenuAction.signOut,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text("Sign out"),
          ),
        ),
      ],
    );
  }
}

enum _TopMenuAction { profile, history, signOut }

// ===== Cards =====
class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
        color: const Color(0xFFFFF8E1), // crisp white surface
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
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
        // Soft yellow for normal buttons, blue for the active one
        color: active ? const Color(0xFF1E88E5) : const Color(0xFFFFF8E1), // <- changed
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
