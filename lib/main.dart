import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paw_ui/screens/DeviceControl.dart';

import 'firebase_options.dart';

// Screens & widgets
import 'screens/HomePage.dart'; // HomePageView
import 'screens/HistoryPage.dart';
import 'screens/HomePageAdmin.dart';

// USER pages
import 'screens/ProfilePage.dart';
import 'screens/VerifyEmail.dart';
import 'screens/ChangePassword.dart';

// ADMIN pages
import 'screens/AdminEditProfile.dart';
import 'screens/AdminChangePassword.dart';
import 'screens/AdminUserListPage.dart';
import 'screens/AdminUserHistoryPage.dart';
import 'screens/AdminUserStatusPage.dart';

// Services
import 'services/FirestoreService.dart';

import 'widgets/Login.dart';
import 'widgets/Scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Avoid duplicate initialization during hot restart or native auto-init.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      // Ensure the default app is available before continuing.
      await Firebase.app();
    }
  } on FirebaseException catch (e) {
    // If the native layer auto-initialized already, ignore duplicate error.
    if (e.code != 'duplicate-app') rethrow;
  }
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
      routes: {
        '/verify': (context) => const VerifyEmail(),
        '/change-password': (context) => const ChangePassword(),
      },
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  User? _user;
  final _fs = FirestoreService();
  late final StreamSubscription<User?> _authSub;
  StreamSubscription? _userDocSub;
  int _role = 0; // 0=user, 1=admin

  bool get _loggedIn => _user != null;
  bool get _isAdmin => _role == 1;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) async {
      if (!mounted) return;
      setState(() {
        _user = u;
        _role = 0;
      });

      // cancel previous user doc subscription
      await _userDocSub?.cancel();
      _userDocSub = null;

      if (u != null) {
        // Ensure user doc exists; default role 0
        await _fs.upsertUserFromAuth(u, role: 0);
        // Listen for role changes from Firestore
        _userDocSub = _fs.streamUser(u.uid).listen((doc) {
          if (!mounted) return;
          final data = doc.data();
          final r = (data?['role'] is int)
              ? (data?['role'] as int)
              : (data?['role'] == 'admin' ? 1 : 0); // backward compat
          setState(() => _role = r);
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }

  Future<void> _openLoginSheet() async {
    await showModalBottomSheet<void>(
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
            child: const SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Login(),
                ),
              ),
            ),
          ),
        );
      },
    );
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
                    if (!mounted) return;
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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // Ensure we return to a clean root route
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ===================== ADMIN LANDING =====================
    if (_loggedIn && _isAdmin) {
      return HomePageAdmin(
        adminName: _user?.email?.split('@').first ?? 'Admin',
        adminEmail: _user?.email ?? 'admin@pawpal.app',
        totalUsers: 12,
        devicesOnline: 8,
        errors24h: 1,
        onOpenProfile: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminEditProfilePage()));
        },
        onChangePassword: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminChangePasswordPage()));
        },
        onOpenUserList: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminUserListPage()));
        },
        onOpenDevices: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Devices page (placeholder)')),
          );
        },
        onOpenUserHistory: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminUserHistoryPage()));
        },
        onOpenUserStatus: () {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminUserStatusPage()));
        },
        onSignOut: _signOut,
      );
    }

    // ===================== USER LANDING ======================
    return HomePageView(
      showEmptyState: !_loggedIn,
      emptyImageAsset: 'assets/petfeed.png',
      emptyText: "Voops! Couldn't find any PawFeeder.",
      isAuthorizing: false,
      errorMessage: null,
      onRetryAuthorize: null,
      onOpenLogin: !_loggedIn ? _openLoginSheet : null,
      onOpenProfile: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProfilePage()));
      },
      onOpenHistory: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HistoryPage()));
      },
      onSignOut: _signOut,
      username: _loggedIn ? (_user?.email?.split('@').first) : null,
      avatarUrl: null,
      foodWeightGrams: _loggedIn ? 420 : null,
      catDetected: _loggedIn,
      onDispense: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispensing food… (UI-only)')),
        );
      },
      onSchedule: () => _openSchedulerSheet(),
      onConnectDevice: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DeviceControl()));
      },
    );
  }
}
