import 'package:flutter/material.dart';
import 'package:paw_ui/widgets/OptionCard.dart';

/// UI-only version of DeviceControl.
/// - No server calls, no Firebase, no URL launch.
/// - You pass in state and wire up callbacks.
/// - For the content area, you can pass [content] (e.g., a ScheduleList).
class DeviceControlView extends StatelessWidget {
  const DeviceControlView({
    Key? key,
    required this.activeIndex, // 0: Schedule, 1: Release, 2: Connect
    this.scheduledDate,
    required this.loading,
    required this.error,
    this.onLogout,
    this.onNetworkIconTap,
    this.onCardSelected,
    this.onSchedulePressed, // FAB "Schedule"
    this.content, // e.g., ScheduleList(...)
  }) : super(key: key);

  final int activeIndex;
  final String? scheduledDate;
  final bool loading;
  final bool error;

  final VoidCallback? onLogout;
  final VoidCallback? onNetworkIconTap;
  final ValueChanged<int>? onCardSelected;
  final VoidCallback? onSchedulePressed;

  /// Optional body below the option cards (e.g., ScheduleList widget).
  final Widget? content;

  bool get _showScheduleFab {
    if (loading || error) return false;
    if (activeIndex != 0) return false;
    final hasSchedule = (scheduledDate != null && scheduledDate!.isNotEmpty);
    return !hasSchedule;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(0, 25.0, 0, 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onNetworkIconTap,
            child: Icon(
              Icons.network_check,
              color: theme.textTheme.bodyMedium?.color,
              size: 20.0,
            ),
          ),
          Image.asset("assets/logo.png", height: 70),
          GestureDetector(
            onTap: onLogout,
            child: Icon(
              Icons.exit_to_app_rounded,
              color: theme.textTheme.bodyMedium?.color,
              size: 20.0,
            ),
          ),
        ],
      ),
    );

    final options = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OptionCard(
          id: 0,
          title: "Schedule",
          title2: "Feed",
          icon: "assets/scheduler.png",
          active: activeIndex == 0,
          onClick: onCardSelected,
        ),
        OptionCard(
          id: 1,
          title: "Release",
          title2: "Food",
          icon: "assets/feeder.png",
          active: activeIndex == 1,
          onClick: onCardSelected,
        ),
        OptionCard(
          id: 2,
          title: "Connect",
          title2: "Device",
          icon: "assets/conn.png",
          active: activeIndex == 2,
          onClick: onCardSelected,
        ),
      ],
    );

    // When loading or error, you can still show your [content] if you want,
    // but here we mirror the original: content hidden on error.
    final Widget bodyContent = error
        ? const SizedBox.shrink()
        : (content ?? const SizedBox.shrink());

    final fab = _showScheduleFab
        ? FloatingActionButton.extended(
            onPressed: onSchedulePressed,
            label: const Text(
              'Schedule',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.timer),
            tooltip: 'Schedule Feed',
            elevation: 2,
            backgroundColor: const Color(0xFF0e2a47),
            foregroundColor: theme.primaryColor,
          )
        : const SizedBox.shrink();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            topBar,
            options,
            // Spacer content area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: bodyContent,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
