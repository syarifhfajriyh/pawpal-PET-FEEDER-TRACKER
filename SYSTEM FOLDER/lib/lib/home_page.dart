import 'dart:async' show Timer;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'auth_screen.dart';
import 'profile_page.dart';

class RedesignedAnimatedBackground extends StatefulWidget {
  final bool isAdmin;

  const RedesignedAnimatedBackground({super.key, required this.isAdmin});

  @override
  State<RedesignedAnimatedBackground> createState() => _RedesignedAnimatedBackgroundState();
}

class _RedesignedAnimatedBackgroundState extends State<RedesignedAnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color1 = widget.isAdmin ? const Color(0xFF1a0d2b) : const Color(0xFF0d0d2b);
    final Color color2 = widget.isAdmin ? const Color(0xFF2d1a3d) : const Color(0xFF1a1a3d);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.black.withOpacity(0.1)),
              ),
            );
          },
        ),
      ],
    );
  }
}

class RedesignedGlassmorphicContainer extends StatelessWidget {
  final Widget child;
  const RedesignedGlassmorphicContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _mainTabController;
  late TabController _historyTabController;

  String? _profileImageUrl;
  String _userRole = 'user';
  String? _displayName;

  String? _selectedUserId;
  String? _selectedUserEmail;
  List<Map<String, dynamic>> _usersList = [];
  bool _isLoadingUserData = false;

  String _foodStatus = 'Medium';
  bool _catDetected = true;
  List<Map<String, dynamic>> _feedingHistory = [];
  List<Map<String, dynamic>> _detectionHistory = [];
  List<Map<String, dynamic>> _foodLevelHistory = [];

  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isDaily = true;
  List<Map<String, dynamic>> _scheduledFeedings = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Timer? _scheduleCheckerTimer;

  late AnimationController _dispenseButtonController;
  late AnimationController _refreshButtonController;
  late AnimationController _profileButtonController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _historyTabController = TabController(length: 3, vsync: this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    _dispenseButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _refreshButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _profileButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _loadInitialData().then((_) {
      _initializeDevicePaths();
    });
    _initializeNotifications();
    tz.initializeTimeZones();

    _setupRealtimeListeners();

    _startScheduleChecker();
  }

  void _startScheduleChecker() {
    _scheduleCheckerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkScheduledFeedings();
    });
  }

  Future<void> _checkScheduledFeedings() async {
    try {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      for (final schedule in _scheduledFeedings) {
        if (schedule['active'] == true && schedule['time'] == currentTime) {
          final lastTriggered = schedule['lastTriggered'] as String?;
          final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          if (lastTriggered != today) {
            await _triggerScheduledFeeding(schedule);

            await FirebaseFirestore.instance
                .collection('users')
                .doc(_selectedUserId)
                .collection('scheduled_feedings')
                .doc(schedule['id'] as String)
                .update({
              'lastTriggered': today,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking scheduled feedings: $e');
    }
  }

  Future<void> _triggerScheduledFeeding(Map<String, dynamic> schedule) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref();
      await databaseRef.child('device/feedCommand').set(1);

      final now = DateTime.now();
      final newFeedingEntry = {
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
        'type': 'Scheduled',
        'scheduleTime': schedule['time'],
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedUserId)
          .collection('feeding_history')
          .add(newFeedingEntry);

      await _showScheduledFeedingNotification(schedule['time'] as String);

      if (mounted) {
        _loadUserSpecificData(_selectedUserId!);
      }
    } catch (e) {
      debugPrint('Error triggering scheduled feeding: $e');
    }
  }

  Future<void> _showScheduledFeedingNotification(String scheduleTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'scheduled_feeding_channel',
      'Scheduled Feedings',
      channelDescription: 'Notifications for scheduled pet feedings',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      'Scheduled Feeding',
      'Food dispensed at $scheduleTime',
      platformChannelSpecifics,
    );
  }

  Future<void> _initializeDevicePaths() async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref();

      await databaseRef.child('device/feedCommand').set(0);
      await databaseRef.child('device/buttonState').set(0);
      await databaseRef.child('device/foodLevel').set('Medium');

    } catch (e) {
    }
  }

  Future<void> _recordCatDetection(bool detected) async {
    try {
      final now = DateTime.now();
      final newDetectionEntry = {
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
        'status': detected ? 'Detected' : 'Not Detected',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedUserId)
          .collection('detection_history')
          .add(newDetectionEntry);

      if (mounted) {
        setState(() {
          _detectionHistory.insert(0, newDetectionEntry);
        });
      }
    } catch (e) {
      debugPrint('Error recording cat detection: $e');
    }
  }

  Future<void> _recordFoodLevelChange(String oldLevel, String newLevel) async {
    try {
      final now = DateTime.now();
      final newFoodLevelEntry = {
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
        'oldLevel': oldLevel,
        'newLevel': newLevel,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedUserId)
          .collection('food_level_history')
          .add(newFoodLevelEntry);

      if (mounted) {
        setState(() {
          _foodLevelHistory.insert(0, newFoodLevelEntry);
        });
      }
    } catch (e) {
      debugPrint('Error recording food level change: $e');
    }
  }

  void _setupRealtimeListeners() {
    final databaseRef = FirebaseDatabase.instance.ref();
    String previousFoodLevel = _foodStatus;

    databaseRef.child('device/foodLevel').onValue.listen((event) {
      if (event.snapshot.exists) {
        final newFoodLevel = event.snapshot.value.toString();
        if (newFoodLevel != previousFoodLevel) {
          setState(() {
            _foodStatus = newFoodLevel;
          });

          _recordFoodLevelChange(previousFoodLevel, newFoodLevel);
          previousFoodLevel = newFoodLevel;
        }
      }
    });

    databaseRef.child('device/buttonState').onValue.listen((event) {
      if (event.snapshot.exists) {
        bool newDetectedState = event.snapshot.value == 1;

        if (newDetectedState != _catDetected) {
          setState(() {
            _catDetected = newDetectedState;
          });

          _recordCatDetection(newDetectedState);
        }
      }
    });
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRole = await AuthService().getUserRole(user.uid);
      final userData = await AuthService().getUserData(user.uid);

      if (mounted) {
        setState(() {
          _userRole = userRole;
          _selectedUserId = user.uid;
          _selectedUserEmail = user.email;
          _profileImageUrl = userData?['profileImageUrl'];
          _displayName = userData?['displayName'];
        });
      }

      await _loadUserSpecificData(user.uid);

      if (_userRole == 'admin') {
        await _loadUsersList();
      }
    }
  }

  Future<void> _loadUsersList() async {
    try {
      final users = await AuthService().getAllUsers();
      if (mounted) {
        setState(() => _usersList = users);
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  Future<void> _switchUser(String? userId, String? userEmail) async {
    if (userId == null) return;

    setState(() {
      _selectedUserId = userId;
      _selectedUserEmail = userEmail;
      _isLoadingUserData = true;
    });

    await _loadUserSpecificData(userId);

    if (mounted) {
      setState(() => _isLoadingUserData = false);
    }
  }

  Future<void> _loadUserSpecificData(String userId) async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref();

      final foodLevelSnapshot = await databaseRef.child('device/foodLevel').get();
      if (foodLevelSnapshot.exists) {
        setState(() {
          _foodStatus = foodLevelSnapshot.value.toString();
        });
      }

      final catStatusSnapshot = await databaseRef.child('device/buttonState').get();
      if (catStatusSnapshot.exists) {
        setState(() {
          _catDetected = catStatusSnapshot.value == 1;
        });
      }

      final feedingHistorySnapshot = await FirebaseFirestore.instance
          .collection('users').doc(userId)
          .collection('feeding_history')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final detectionHistorySnapshot = await FirebaseFirestore.instance
          .collection('users').doc(userId)
          .collection('detection_history')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final foodLevelHistorySnapshot = await FirebaseFirestore.instance
          .collection('users').doc(userId)
          .collection('food_level_history')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final scheduledFeedingsSnapshot = await FirebaseFirestore.instance
          .collection('users').doc(userId)
          .collection('scheduled_feedings')
          .orderBy('time')
          .get();

      if (mounted) {
        setState(() {
          _feedingHistory = feedingHistorySnapshot.docs.where((doc) => doc.id != 'initial_doc').map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          _detectionHistory = detectionHistorySnapshot.docs.where((doc) => doc.id != 'initial_doc').map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          _foodLevelHistory = foodLevelHistorySnapshot.docs.where((doc) => doc.id != 'initial_doc').map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          _scheduledFeedings = scheduledFeedingsSnapshot.docs.where((doc) => doc.id != 'initial_doc').map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading user data for $userId: $e');
    }
  }

  void _dispenseFood() async {
    try {
      await _dispenseButtonController.forward();
      await _dispenseButtonController.reverse();

      final databaseRef = FirebaseDatabase.instance.ref();
      await databaseRef.child('device/feedCommand').set(1);

      final now = DateTime.now();
      final newFeedingEntry = {
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
        'type': 'Manual',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedUserId)
          .collection('feeding_history')
          .add(newFeedingEntry);

      if (mounted) {
        _loadUserSpecificData(_selectedUserId!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Food dispensed successfully!', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Error dispensing food: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to dispense food.', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _addScheduledFeeding() async {
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    final newSchedule = {
      'time': timeStr,
      'daily': _isDaily,
      'active': true,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('users').doc(_selectedUserId).collection('scheduled_feedings').add(newSchedule);
      if (mounted) {
        _loadUserSpecificData(_selectedUserId!);
      }
      _scheduleNotification(timeStr);
      Navigator.of(context).pop();


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scheduled feeding at $timeStr ${_isDaily ? '(Daily)' : ''}', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Error adding scheduled feeding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add scheduled feeding.', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _toggleScheduledFeeding(int index) async {
    final scheduleId = _scheduledFeedings[index]['id'];
    final newActiveState = !(_scheduledFeedings[index]['active'] ?? false);

    try {
      await FirebaseFirestore.instance.collection('users').doc(_selectedUserId).collection('scheduled_feedings').doc(scheduleId as String).update({'active': newActiveState});
      if (mounted) {
        _loadUserSpecificData(_selectedUserId!);
      }
    } catch (e) {
      debugPrint('Error toggling schedule: $e');
    }
  }

  void _removeScheduledFeeding(int index) async {
    final scheduleId = _scheduledFeedings[index]['id'];

    try {
      await FirebaseFirestore.instance.collection('users').doc(_selectedUserId).collection('scheduled_feedings').doc(scheduleId as String).delete();
      if (mounted) {
        _loadUserSpecificData(_selectedUserId!);
      }


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scheduled feeding removed', style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Error removing schedule: $e');
    }
  }

  void _scheduleNotification(String timeStr) async {
    final timeParts = timeStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final scheduledDateTime = _nextInstanceOfTime(hour, minute);

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails('pet_feeder_channel', 'Pet Feeder Notifications', channelDescription: 'Notifications for scheduled pet feedings', importance: Importance.high, priority: Priority.high);
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.zonedSchedule(0, 'Pet Feeding Time!', 'Time to feed your pet!', scheduledDateTime, platformChannelSpecifics, androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, matchDateTimeComponents: _isDaily ? DateTimeComponents.time : null);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  @override
  void dispose() {
    _scheduleCheckerTimer?.cancel();
    _animationController.dispose();
    _mainTabController.dispose();
    _historyTabController.dispose();
    _dispenseButtonController.dispose();
    _refreshButtonController.dispose();
    _profileButtonController.dispose();
    super.dispose();
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfilePage())).then((_) => _loadInitialData());
  }


  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _userRole == 'admin' ? const Color(0xFF1a0d2b) : const Color(0xFF0d0d2b),
      body: Stack(
        children: [
          RedesignedAnimatedBackground(isAdmin: _userRole == 'admin'),
          SafeArea(
            child: _isLoadingUserData
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildMainStatusCard(),
                    const SizedBox(height: 30),
                    _buildDispenseButton(),
                    const SizedBox(height: 30),
                    _buildTabs(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 65,
                width: 520,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back,',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (_userRole == 'admin' && _usersList.isNotEmpty)
                        Expanded(child: _buildUserDropdown())
                      else
                        Text(
                          _displayName ?? 'User',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (_userRole == 'admin')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _userRole == 'admin' ? Colors.purple : Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_userRole == 'admin' && _selectedUserId != FirebaseAuth.instance.currentUser?.uid)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Viewing as: $_selectedUserEmail',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 0.9).animate(
                    CurvedAnimation(
                      parent: _refreshButtonController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () async {
                      await _refreshButtonController.forward();
                      await _refreshButtonController.reverse();
                      _loadInitialData();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Data refreshed', style: GoogleFonts.poppins(color: Colors.white)),
                          backgroundColor: Colors.blue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 0.9).animate(
                    CurvedAnimation(
                      parent: _profileButtonController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      await _profileButtonController.forward();
                      await _profileButtonController.reverse();
                      _navigateToProfile(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: ClipOval(
                        child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: _profileImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white70),
                        )
                            : const Icon(Icons.person, color: Colors.white70, size: 30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserDropdown() {
    final user = FirebaseAuth.instance.currentUser;
    final allUsers = [
      {'uid': user!.uid, 'email': user.email ?? 'Admin', 'displayName': 'My Device'},
      ..._usersList,
    ];

    return DropdownButton<String>(
      value: _selectedUserId,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      iconSize: 28,
      elevation: 16,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      dropdownColor: _userRole == 'admin' ? const Color(0xFF2d1a3d) : const Color(0xFF1a1a3d),
      underline: Container(height: 0, color: Colors.transparent),
      onChanged: (String? newValue) {
        if (newValue != null) {
          final selectedUser = allUsers.firstWhere((user) => user['uid'] == newValue);
          _switchUser(newValue, selectedUser['email']);
        }
      },
      items: allUsers.map<DropdownMenuItem<String>>((Map<String, dynamic> user) {
        return DropdownMenuItem<String>(
          value: user['uid'] as String,
          child: Text(
            user['displayName'] as String,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMainStatusCard() {
    Map<String, dynamic> foodStatusInfo = _getFoodStatusInfo();
    return RedesignedGlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fastfood, size: 20, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text('FOOD LEVEL', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      foodStatusInfo['label'],
                      style: GoogleFonts.poppins(
                        color: foodStatusInfo['color'],
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearPercentIndicator(
                      padding: EdgeInsets.zero,
                      percent: foodStatusInfo['percent'],
                      lineHeight: 10.0,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      progressColor: foodStatusInfo['color'],
                      barRadius: const Radius.circular(4),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(color: Colors.white12, thickness: 1, indent: 20, endIndent: 20),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 20, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text('CAT STATUS', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      _catDetected ? Icons.pets : Icons.visibility_off_outlined,
                      size: 42,
                      color: _catDetected ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _catDetected ? 'Detected' : 'Away',
                      style: GoogleFonts.poppins(
                        color: _catDetected ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getFoodStatusInfo() {
    switch (_foodStatus) {
      case 'High':
        return {'label': 'Full', 'color': Colors.greenAccent, 'percent': 1.0};
      case 'Medium':
        return {'label': 'Medium', 'color': Colors.orangeAccent, 'percent': 0.5};
      case 'Low':
        return {'label': 'Low', 'color': Colors.redAccent, 'percent': 0.2};
      case 'Empty':
        return {'label': 'Empty', 'color': Colors.red.shade400, 'percent': 0.0};
      default:
        return {'label': 'Unknown', 'color': Colors.grey, 'percent': 0.0};
    }
  }

  Widget _buildDispenseButton() {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(
          parent: _dispenseButtonController,
          curve: Curves.easeInOut,
        ),
      ),
      child: GestureDetector(
        onTap: _dispenseFood,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              colors: _userRole == 'admin'
                  ? [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)]
                  : [const Color(0xFF00BCD4), const Color(0xFF0097A7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: (_userRole == 'admin' ? const Color(0xFF9C27B0) : const Color(0xFF00BCD4)).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Dispense Food',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: (_userRole == 'admin' ? const Color(0xFF2d1a3d) : const Color(0xFF1a1a3d)).withOpacity(0.95),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.2))),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('New Schedule', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Time:', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
                          TextButton(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context, initialTime: _selectedTime,
                                builder: (context, child) => Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: ColorScheme.dark(
                                        primary: _userRole == 'admin' ? Colors.purple : Colors.cyan,
                                        onPrimary: Colors.black,
                                        surface: _userRole == 'admin' ? const Color(0xFF1a0d2b) : const Color(0xFF0d0d2b),
                                        onSurface: Colors.white
                                    ),
                                    dialogTheme: DialogThemeData(
                                      backgroundColor: _userRole == 'admin'
                                          ? const Color(0xFF1a0d2b)
                                          : const Color(0xFF0d0d2b),
                                    ),

                                  ), child: child!,
                                ),
                              );
                              if (pickedTime != null) {
                                setDialogState(() => _selectedTime = pickedTime);
                              }
                            },
                            child: Text(_selectedTime.format(context), style: GoogleFonts.poppins(fontSize: 24, color: _userRole == 'admin' ? Colors.purple : Colors.cyan, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Repeat Daily:', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
                          Switch(
                            value: _isDaily,
                            onChanged: (value) => setDialogState(() => _isDaily = value),
                            activeThumbColor: _userRole == 'admin' ? Colors.purple : Colors.cyan,
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16))
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _addScheduledFeeding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _userRole == 'admin' ? Colors.purple : Colors.cyan,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text('Save', style: GoogleFonts.poppins(fontSize: 16)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    return RedesignedGlassmorphicContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _mainTabController.animateTo(0),
                      child: AnimatedBuilder(
                        animation: _mainTabController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              color: _mainTabController.index == 0
                                  ? (_userRole == 'admin' ? Colors.purple.withOpacity(0.3) : Colors.cyan.withOpacity(0.3))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.schedule,
                                      size: 20,
                                      color: _mainTabController.index == 0
                                          ? Colors.white
                                          : Colors.white70),
                                  const SizedBox(width: 8),
                                  Text('Schedule',
                                      style: GoogleFonts.poppins(
                                          color: _mainTabController.index == 0
                                              ? Colors.white
                                              : Colors.white70,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _mainTabController.animateTo(1),
                      child: AnimatedBuilder(
                        animation: _mainTabController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              color: _mainTabController.index == 1
                                  ? (_userRole == 'admin' ? Colors.purple.withOpacity(0.3) : Colors.cyan.withOpacity(0.3))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history,
                                      size: 20,
                                      color: _mainTabController.index == 1
                                          ? Colors.white
                                          : Colors.white70),
                                  const SizedBox(width: 8),
                                  Text('History',
                                      style: GoogleFonts.poppins(
                                          color: _mainTabController.index == 1
                                              ? Colors.white
                                              : Colors.white70,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  _buildSchedulesSection(),
                  _buildHistorySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesSection() {
    return Column(
      children: [
        Expanded(
          child: _scheduledFeedings.isEmpty
              ? _EmptyState(
            icon: Icons.watch_later_outlined,
            message: 'No schedules set.',
            action: ElevatedButton.icon(
              onPressed: () => _showScheduleDialog(context),
              icon: const Icon(Icons.add, size: 20),
              label: Text('Create Schedule', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _userRole == 'admin' ? Colors.purple.withOpacity(0.8) : Colors.cyan.withOpacity(0.8),
                foregroundColor: Colors.black,
              ),
            ),
          )
              : ListView.builder(
            itemCount: _scheduledFeedings.length,
            itemBuilder: (context, index) {
              final schedule = _scheduledFeedings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0, left: 8, right: 8),
                child: _ScheduleCard(
                  schedule: schedule,
                  onToggle: () => _toggleScheduledFeeding(index),
                  onDelete: () => _removeScheduledFeeding(index),
                  isAdmin: _userRole == 'admin',
                ),
              );
            },
          ),
        ),
        if (_scheduledFeedings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showScheduleDialog(context),
                icon: const Icon(Icons.add, size: 22),
                label: Text('Add New Schedule', style: GoogleFonts.poppins(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userRole == 'admin' ? Colors.purple.withOpacity(0.2) : Colors.cyan.withOpacity(0.2),
                  foregroundColor: _userRole == 'admin' ? Colors.purple : Colors.cyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _historyTabController.animateTo(0),
                  child: AnimatedBuilder(
                    animation: _historyTabController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: _historyTabController.index == 0
                              ? (_userRole == 'admin' ? Colors.purple.withOpacity(0.3) : Colors.cyan.withOpacity(0.3))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('Feeding',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: _historyTabController.index == 0
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _historyTabController.animateTo(1),
                  child: AnimatedBuilder(
                    animation: _historyTabController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: _historyTabController.index == 1
                              ? (_userRole == 'admin' ? Colors.purple.withOpacity(0.3) : Colors.cyan.withOpacity(0.3))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('Detection',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: _historyTabController.index == 1
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _historyTabController.animateTo(2),
                  child: AnimatedBuilder(
                    animation: _historyTabController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: _historyTabController.index == 2
                              ? (_userRole == 'admin' ? Colors.purple.withOpacity(0.3) : Colors.cyan.withOpacity(0.3))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('Food Level',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: _historyTabController.index == 2
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _historyTabController,
            children: [
              _buildHistoryListView(_feedingHistory, isFeeding: true),
              _buildHistoryListView(_detectionHistory, isFeeding: false),
              _buildFoodLevelHistoryListView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryListView(List<Map<String, dynamic>> data, {required bool isFeeding}) {
    if (data.isEmpty) {
      return _EmptyState(
        icon: isFeeding ? Icons.fastfood_outlined : Icons.pets_outlined,
        message: 'No history records found.',
      );
    }

    return ListView.builder(
      itemCount: data.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final item = data[index];
        bool isDetected = item['status'] == 'Detected';
        String formattedDate = _formatDate(item['date']);
        String formattedTime = item['time'].substring(0, 5);
        bool isManual = item['type'] == 'Manual';

        String timeAgo = '';
        if (item['timestamp'] != null) {
          try {
            final timestamp = item['timestamp'] as Timestamp;
            timeAgo = _getTimeAgo(timestamp.toDate());
          } catch (e) {
            timeAgo = '$formattedDate at $formattedTime';
          }
        } else {
          timeAgo = '$formattedDate at $formattedTime';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isFeeding
                        ? (_userRole == 'admin' ? Colors.purple.withOpacity(0.2) : Colors.cyan.withOpacity(0.2))
                        : (isDetected ? Colors.greenAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFeeding ? Icons.restaurant_menu : (isDetected ? Icons.pets : Icons.visibility_off_outlined),
                    color: isFeeding ? (_userRole == 'admin' ? Colors.purple : Colors.cyan) : (isDetected ? Colors.greenAccent : Colors.orangeAccent),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFeeding ? "Food Dispensed" : "Cat ${item['status']}",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text('·', style: TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          Text(
                            '$formattedDate $formattedTime',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isFeeding)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isManual ? Colors.blueAccent.withOpacity(0.2) : Colors.purpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['type'],
                      style: GoogleFonts.poppins(color: isManual ? Colors.blueAccent : Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodLevelHistoryListView() {
    if (_foodLevelHistory.isEmpty) {
      return _EmptyState(
        icon: Icons.fastfood_outlined,
        message: 'No food level history found.',
      );
    }

    return ListView.builder(
      itemCount: _foodLevelHistory.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final item = _foodLevelHistory[index];
        String formattedDate = _formatDate(item['date']);
        String formattedTime = item['time'].substring(0, 5);

        String timeAgo = '';
        if (item['timestamp'] != null) {
          try {
            final timestamp = item['timestamp'] as Timestamp;
            timeAgo = _getTimeAgo(timestamp.toDate());
          } catch (e) {
            timeAgo = '$formattedDate at $formattedTime';
          }
        } else {
          timeAgo = '$formattedDate at $formattedTime';
        }

        Color getLevelColor(String level) {
          switch (level) {
            case 'High': return Colors.greenAccent;
            case 'Medium': return Colors.orangeAccent;
            case 'Low': return Colors.redAccent;
            case 'Empty': return Colors.red.shade400;
            default: return Colors.grey;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: getLevelColor(item['newLevel']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.fastfood,
                    color: getLevelColor(item['newLevel']),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Food Level Changed",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.arrow_forward, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            "${item['oldLevel']} → ${item['newLevel']}",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text('·', style: TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          Text(
                            '$formattedDate $formattedTime',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : dateStr;
    } catch (e) {
      return dateStr;
    }
  }
}


class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isAdmin;

  const _ScheduleCard({required this.schedule, required this.onToggle, required this.onDelete, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    bool isActive = schedule['active'] ?? false;
    final accentColor = isAdmin ? Colors.purple : Colors.cyan;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(isActive ? Icons.alarm_on : Icons.alarm_off, color: isActive ? accentColor : Colors.white38, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule['time'], style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.white38, letterSpacing: 1.2)),
                  Text(schedule['daily'] ? 'Repeats Daily' : 'One-time', style: GoogleFonts.poppins(color: isActive ? Colors.white70 : Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeThumbColor: accentColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _EmptyState({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white38, size: 50),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ]
        ],
      ),
    );
  }
}