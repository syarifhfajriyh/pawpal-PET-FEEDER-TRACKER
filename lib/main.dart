import 'package:flutter/material.dart';

import 'screens/HomePage.dart';
import 'widgets/Login.dart';
import 'widgets/Scheduler.dart';
import 'screens/ProfilePage.dart';
import 'screens/HistoryPage.dart';
import 'screens/VerifyEmail.dart';
import 'screens/HomePageAdmin.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PawFeederApp());
}

class PawFeederApp extends StatelessWidget {
  const PawFeederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawFeeder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFffc34d),
          primary: const Color(0xFFffc34d),
          secondary: const Color(0xFFffc34d),
          background: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        fontFamily: 'Nunito',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Color(0xFF0e2a47),
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF5f7d95),
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // 🔗 Routes
      routes: {
        '/verify': (context) => const VerifyEmail(),
        '/home':   (context) => const _Root(),
      },

      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({super.key});
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _loggedIn = false;
  bool _isAdmin = false;

  Future<void> _openLoginSheet() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
      builder: (ctx) {
        return Container(
          height: 520,
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
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Login(),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (ok == true && mounted) {
      setState(() => _loggedIn = true);
    }
  }

  Future<void> _openSchedulerSheet({bool reschedule = false, DateTime? date}) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
      builder: (ctx) {
        return Container(
          height: 520,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Scheduler(
                  reschedule: reschedule,
                  date: date,
                  onSubmit: ({DateTime? scheduledDateTime, String? portionSize}) {
                    Navigator.of(ctx).pop(true);
                    if (scheduledDateTime != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Scheduled ${portionSize ?? "(reschedule)"} at $scheduledDateTime',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // === ADMIN LANDING ===
    if (_loggedIn && _isAdmin) {
      return HomePageAdmin(
        adminName: 'Admin',
        adminEmail: 'admin@pawpal.app',
        totalUsers: 12,
        devicesOnline: 8,
        errors24h: 1,
        onOpenProfile: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        },
        onOpenUserList: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminUserListPage()),
          );
        },
        onOpenUserHistory: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminUserHistoryPage()),
          );
        },
        onOpenUserStatus: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminUserStatusPage()),
          );
        },
        onSignOut: () => setState(() {
          _loggedIn = false;
          _isAdmin = false;
        }),
      );
    }

    return HomePageView(
      showEmptyState: !_loggedIn,
      emptyImageAsset: 'assets/petfeed.jpg',
      emptyText: "Voops! Couldn't find any PawFeeder.",
      isAuthorizing: false,
      errorMessage: null,
      onRetryAuthorize: null,
      onOpenProfile: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      },
      onOpenHistory: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryPage()),
        );
      },
      onSignOut: () => setState(() => _loggedIn = false),
      username: null,
      avatarUrl: null,
      foodWeightGrams: _loggedIn ? 420 : null,
      catDetected: _loggedIn,
      onDispense: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispensing food… (UI-only)')),
        );
      },
      onSchedule: () => _openSchedulerSheet(),
      onConnectDevice: _openLoginSheet,
    );
  }
}
