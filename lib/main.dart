import 'package:flutter/material.dart';
import 'screens/HomePage.dart';
import 'widgets/Login.dart';
import 'widgets/Scheduler.dart';
import 'screens/ProfilePage.dart';
import 'screens/HistoryPage.dart';

void main() {
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
                  child: Login(
                    connecting: false,
                    errorMessage: "",
                    onSubmit: (u, p) {
                      Navigator.of(ctx).pop(true); // success (UI-only)
                    },
                    onRouteDecision: (isAdmin) => _isAdmin = isAdmin,
                    onSignUp: () {},
                    onForgotPassword: (_) {},
                  ),
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
    // Optional admin view (kept from earlier flow)
    if (_loggedIn && _isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: () => setState(() {
              _loggedIn = false;
              _isAdmin = false;
            }),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ),
      );
    }

    return HomePageView(
      // Empty state until “connected” (logged in)
      showEmptyState: !_loggedIn,
      emptyImageAsset: 'assets/petfeed.jpg',
      emptyText: "Voops! Couldn't find any PawFeeder.",

      // not using authorizing/error for this look
      isAuthorizing: false,
      errorMessage: null,
      onRetryAuthorize: null,

      // menu
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

      // status (NO username -> removes greeting)
      username: null,
      avatarUrl: null,
      foodWeightGrams: _loggedIn ? 420 : null,
      catDetected: _loggedIn,

      // actions
      onDispense: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispensing food… (UI-only)')),
        );
      },
      onSchedule: () => _openSchedulerSheet(), // <-- Schedule opens Scheduler sheet
      onConnectDevice: _openLoginSheet,        // navy “+ PawFeeder” opens Login sheet
    );
  }
}
