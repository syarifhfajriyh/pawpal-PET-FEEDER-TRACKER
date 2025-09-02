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
import 'screens/VerifyEmail.dart';
import 'screens/ChangePassword.dart';

// ADMIN pages
import 'screens/AdminChangePassword.dart';
import 'screens/AdminUserListPage.dart';
import 'screens/AdminUserHistoryPage.dart';
import 'screens/AdminUserStatusPage.dart';
import 'screens/AdminMyProfileViewPage.dart';
import 'screens/UserMyProfileViewPage.dart';
import 'screens/UserWeightHistoryPage.dart';
import 'screens/UserCatHistoryPage.dart';

// Services
import 'services/FirestoreService.dart';
import 'services/FeederService.dart';

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
      Firebase.app();
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
        '/history-weight': (context) => const UserWeightHistoryPage(),
        '/history-cat': (context) => const UserCatHistoryPage(),
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
  final _feeder = FeederService();
  late final StreamSubscription<User?> _authSub;
  StreamSubscription? _userDocSub;
  int _role = 0; // 0=user, 1=admin

  bool get _loggedIn => _user != null;
  bool get _isAdmin => _role == 1;

  // In-app soft limit tracking (ui-only)
  final List<_DispenseLog> _dispenseLog = [];
  static const int _hourLimitG = 150; // total grams per hour (soft)
  static const int _dayLimitG = 500; // total grams per day (soft)

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

  // ===== Dispense flow: confirm + amount =====
  Future<void> _openDispenseSheet() async {
    if (!_loggedIn) return;
    await _openAmountDialog(context, (grams) async {
      final proceed = await _checkFeedLimits(grams);
      if (!proceed) return;
      // Wire to device command (default demo-device if not configured)
      await _feeder.dispense(grams: grams, byUid: _user?.uid, byRole: 'user');
      _dispenseLog.add(_DispenseLog(DateTime.now(), grams));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dispensing ${grams}g…')),
      );
    });
  }

  Future<bool> _checkFeedLimits(int newGrams) async {
    final now = DateTime.now();
    _dispenseLog.removeWhere((e) => now.difference(e.at).inDays >= 2);
    final hourTotal = _dispenseLog
        .where((e) => now.difference(e.at).inMinutes < 60)
        .fold<int>(0, (a, b) => a + b.grams);
    final dayTotal = _dispenseLog
        .where((e) => e.at.year == now.year && e.at.month == now.month && e.at.day == now.day)
        .fold<int>(0, (a, b) => a + b.grams);

    final willHour = hourTotal + newGrams;
    final willDay = dayTotal + newGrams;
    if (willHour <= _hourLimitG && willDay <= _dayLimitG) return true;

    final msg = StringBuffer('Feeding amount is high. ');
    if (willHour > _hourLimitG) {
      msg.write('Over hourly limit (${_hourLimitG}g). ');
    }
    if (willDay > _dayLimitG) {
      msg.write('Over daily limit (${_dayLimitG}g). ');
    }
    msg.write('Proceed anyway?');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Warning'),
        content: Text(msg.toString()),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Proceed')),
        ],
      ),
    );
    return ok == true;
  }

  // ***** FIXED METHOD (balanced brackets) *****
  Future<void> _openAmountDialog(BuildContext context, void Function(int grams) onConfirm) async {
    final options = <int>[10, 20, 30, 40, 50, 75, 100];
    int selected = 20;
    final ctrl = TextEditingController(text: '20');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 0.75,
          builder: (_, controller) => SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.restaurant, size: 20),
                          SizedBox(width: 8),
                          Text('Dispense Food', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Quick amounts'),
                      StatefulBuilder(
                        builder: (ctx2, setState) => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: options.map((g) {
                            final active = selected == g;
                            return ChoiceChip(
                              label: Text('${g}g'),
                              selected: active,
                              onSelected: (_) {
                                setState(() {
                                  selected = g;
                                  ctrl.text = g.toString();
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Custom amount (g)'),
                      Form(
                        key: formKey,
                        child: TextFormField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'e.g. 25'),
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null || n <= 0) return 'Enter a positive number';
                            if (n > 500) return 'Too large (max 500g)';
                            return null;
                          },
                          onChanged: (v) {
                            final n = int.tryParse(v.trim());
                            if (n != null) selected = n;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState?.validate() != true) return;
                                Navigator.of(ctx).pop();
                                onConfirm(int.tryParse(ctrl.text.trim()) ?? selected);
                              },
                              child: const Text('Dispense'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
            MaterialPageRoute(builder: (_) => const AdminMyProfileViewPage()));
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
          MaterialPageRoute(builder: (_) => const UserMyProfileViewPage()));
      },
      onOpenHistory: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HistoryPage()));
      },
      onOpenFeedingHistory: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HistoryPage()));
      },
      onOpenWeightHistory: () {
        Navigator.pushNamed(context, '/history-weight');
      },
      onOpenCatHistory: () {
        Navigator.pushNamed(context, '/history-cat');
      },
      onSignOut: _signOut,
      username: _loggedIn ? (_user?.email?.split('@').first) : null,
      avatarUrl: null,
      foodWeightGrams: _loggedIn ? 420 : null,
      catDetected: _loggedIn,
      statusUpdatedAt: _loggedIn ? DateTime.now().subtract(const Duration(minutes: 3)) : null,
      onDispense: _openDispenseSheet,
      onSchedule: () => _openSchedulerSheet(),
      onConnectDevice: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (_) => const DeviceControl()));
      },
    );
  }
}

class _DispenseLog {
  final DateTime at;
  final int grams;
  _DispenseLog(this.at, this.grams);
}
