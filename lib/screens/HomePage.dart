import 'package:flutter/material.dart';

class HomePageView extends StatelessWidget {
  const HomePageView({
    super.key,
    required this.isAuthorizing,
    this.errorMessage,
    this.onRetryAuthorize,

    // profile & history navigation
    this.onOpenProfile,
    this.onOpenHistory,
    this.onOpenFeedingHistory, // prominent button
    this.onOpenWeightHistory,
    this.onOpenCatHistory,
    this.onSignOut,

    // status data
    this.username,
    this.avatarUrl,
    this.foodWeightGrams,
    this.catDetected = false,
    this.statusUpdatedAt,

    // quick actions
    this.onDispense,
    this.onSchedule,
    this.onConnectDevice,

    // empty-state props
    this.showEmptyState = false,
    this.emptyImageAsset,
    this.emptyText,

    // auth
    this.onOpenLogin,
  });

  final bool isAuthorizing;
  final String? errorMessage;
  final VoidCallback? onRetryAuthorize;

  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenFeedingHistory;
  final VoidCallback? onOpenWeightHistory;
  final VoidCallback? onOpenCatHistory;
  final VoidCallback? onSignOut;

  final String? username;
  final String? avatarUrl;
  final int? foodWeightGrams;
  final bool catDetected;
  final DateTime? statusUpdatedAt;

  final VoidCallback? onDispense;
  final VoidCallback? onSchedule;
  final VoidCallback? onConnectDevice;

  final bool showEmptyState;
  final String? emptyImageAsset;
  final String? emptyText;
  final VoidCallback? onOpenLogin;

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
        if (statusUpdatedAt != null) ...[
          const SizedBox(height: 6),
          Text(
            _fmtUpdatedAt(statusUpdatedAt!),
            style: text.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
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
            active: true, // highlighted in blue now
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

    // ---------- HISTORY SHORTCUTS (optional) ----------
    final historyShortcuts = (onOpenFeedingHistory == null &&
            onOpenWeightHistory == null &&
            onOpenCatHistory == null)
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final hasAllThree = onOpenFeedingHistory != null &&
                    onOpenWeightHistory != null &&
                    onOpenCatHistory != null;

                // If we have all 3, render a single row aligned with action cards
                if (hasAllThree) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BigHistoryButton(
                        icon: Icons.history,
                        label: 'Feeding History',
                        onPressed: onOpenFeedingHistory,
                        square: true, // match 100x100 action cards
                      ),
                      _BigHistoryButton(
                        icon: Icons.scale,
                        label: 'Food Weight History',
                        onPressed: onOpenWeightHistory,
                        square: true,
                      ),
                      _BigHistoryButton(
                        icon: Icons.pets,
                        label: 'Cat Detection History',
                        onPressed: onOpenCatHistory,
                        square: true,
                      ),
                    ],
                  );
                }

                // Otherwise, fall back to a centered wrap for 1-2 buttons
                return Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      if (onOpenFeedingHistory != null)
                        _BigHistoryButton(
                          icon: Icons.history,
                          label: 'Feeding History',
                          onPressed: onOpenFeedingHistory,
                        ),
                      if (onOpenWeightHistory != null)
                        _BigHistoryButton(
                          icon: Icons.scale,
                          label: 'Food Weight History',
                          onPressed: onOpenWeightHistory,
                        ),
                      if (onOpenCatHistory != null)
                        _BigHistoryButton(
                          icon: Icons.pets,
                          label: 'Cat Detection History',
                          onPressed: onOpenCatHistory,
                        ),
                    ],
                  ),
                );
              },
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
            const SizedBox(height: 16),
            if (onOpenLogin != null)
              ElevatedButton(
                onPressed: onOpenLogin,
                child: const Text('Login / Sign up'),
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
            historyShortcuts,
          ],
        ),
      );
    }

    // ---------- FAB ----------
    final fab = FloatingActionButton.extended(
      onPressed: showEmptyState ? (onOpenLogin ?? onConnectDevice) : onSchedule,
      icon: const Icon(Icons.add),
      label: Text(
        showEmptyState
            ? (onOpenLogin != null ? 'Login' : 'PawFeeder')
            : 'Schedule',
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
        // Soft yellow for normal buttons, light blue for the active one
        color: active
            // Give Schedule Feed a distinct light blue color
            ? const Color(0xFF64B5F6) // light blue 300
            : const Color(0xFFFFF8E1),
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

String _fmtUpdatedAt(DateTime dt) {
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final time = "${two(dt.hour)}:${two(dt.minute)}";
  final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
  if (sameDay) return "Updated $time";
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];
  return "Updated ${months[dt.month - 1]} ${dt.day}, $time";
}

class _BigHistoryButton extends StatelessWidget {
  const _BigHistoryButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.square = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final width = square ? 100.0 : (fullWidth ? double.infinity : 160.0);
    final height = square ? 100.0 : 48.0;

    final style = ElevatedButton.styleFrom(
      elevation: 2,
      backgroundColor: const Color(0xFF0e2a47), // dark blue palette
      foregroundColor: const Color(0xFFFFC34D), // brand yellow for text/icons
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      side: BorderSide(color: const Color(0xFFFFC34D).withOpacity(0.25), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );

    return SizedBox(
      width: width,
      height: height,
      child: square
          ? ElevatedButton(
              style: style,
              onPressed: onPressed,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ],
              ),
            )
          : ElevatedButton.icon(
              style: style,
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
    );
  }
}

