// lib/screens/HomeRoute.dart  (put anywhere; update imports as needed)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- adjust these imports to your actual file locations ---
import 'HomePage.dart';        // contains HomePageView
import 'ProfilePage.dart';     // target page
import 'HistoryPage.dart';     // target page
import '../widgets/Scheduler.dart';   // target page (if it's under widgets/)
import 'DeviceControl.dart';   // optional: if you have a device page

class HomeRoute extends StatelessWidget {
  const HomeRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return HomePageView(
      // ===== state / loading =====
      isAuthorizing: false,
      errorMessage: null,
      onRetryAuthorize: null,

      // ===== nav actions (WIRED) =====
      onOpenProfile: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      },
      onOpenHistory: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistoryPage()),
        );
      },
      onSignOut: () async {
        try {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (route) => false);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign out failed: $e')),
          );
        }
      },

      // ===== status data (sample; bind your real data) =====
      username: 'Ainaa',
      avatarUrl: null,           // or a real network image URL
      foodWeightGrams: 420,      // example
      catDetected: true,         // example

      // ===== quick actions (WIRED) =====
      onDispense: () {
        // Do your instant-dispense logic or navigate to a detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispensing 20g...')),
        );
      },
      onSchedule: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const Scheduler()),
        );
      },
      onConnectDevice: () {
        // If you have a device page, push it; otherwise repurpose as needed
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DeviceControl()),
        );
      },

      // ===== empty state (if you use it) =====
      showEmptyState: false,
      emptyImageAsset: 'assets/petfeed.jpg',
      emptyText: "Voops! Couldn't find any PawFeeder.",
    );
  }
}
