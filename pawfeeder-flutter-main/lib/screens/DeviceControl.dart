import 'package:app/helper/LocalStorage.dart';
import 'package:app/helper/Server.dart';
import 'package:app/helper/MessageBar.dart';
import 'package:app/screens/HomePage.dart';
import 'package:app/widgets/InstantFeed.dart';
import 'package:app/widgets/Scheduler.dart';
import 'package:app/widgets/OptionCard.dart';
import 'package:app/widgets/ScheduleList.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceControl extends StatefulWidget {
  @override
  _DeviceControlState createState() => _DeviceControlState();
}

class _DeviceControlState extends State<DeviceControl> {
  Server server = Server();
  LocalStorage localStorage = LocalStorage();

  List<String> _cards = ["SCHEDULE_FEED", "RELEASE_FOOD", "CONNECT_DEVICE"];
  String activeCard;
  String scheduledDate;
  bool _loading;
  bool _error;

  void _logout() async {
    await localStorage.del("token");
    await localStorage.del("id");
    this._navigateToHome();
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => HomePage(),
      ),
      (route) => false,
    );
  }

  void _handleScheduleFeedResponse(Map<String, dynamic> response) {
    if (response == null) {
      // Show error message
      setState(() {
        _error = true;
        _loading = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showMessageBar(context, "Request failed.",
          error: true, actionLabel: "Retry", action: this._getScheduledFeed);
    } else if (response["success"] == true && response.containsKey("date")) {
      // Scheduled feed data
      setState(() {
        scheduledDate = response["date"];
        _loading = false;
      });
    } else if (response["success"] == false &&
        response.containsKey("action") &&
        response["action"] == "LOGOUT") {
      // logout
      this._navigateToHome();
    } else {
      // No scheduled found
      setState(() {
        _loading = false;
      });
    }
  }

  void _getScheduledFeed() async {
    setState(() {
      _loading = true;
      _error = false;
      scheduledDate = "";
    });
    String token = await localStorage.get("token");
    String id = await localStorage.get("id");
    if (id != null && token != null) {
      Map<String, dynamic> response = await server.scheduledFeedList(token, id);
      this._handleScheduleFeedResponse(response);
    } else {
      // Logout
      this._navigateToHome();
    }
  }

  void _handleDescheduleFeedResponse(Map<String, dynamic> response) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (response == null) {
      // Show error message
      setState(() {
        _error = true;
        _loading = false;
      });
      showMessageBar(context, "Request failed.",
          error: true, actionLabel: "Retry", action: this._getScheduledFeed);
    } else if (response['success'] == true) {
      // Scheduled feed data
      setState(() {
        scheduledDate = "";
        _loading = false;
      });
      showMessageBar(context, "Schedule cancelled.", error: false);
    } else if (response["success"] == false &&
        response.containsKey("action") &&
        response["action"] == "LOGOUT") {
      // logout
      this._navigateToHome();
    } else {
      // No scheduled found
      setState(() {
        _loading = false;
      });
      showMessageBar(context, "Schedule cancellation failed.",
          error: true,
          actionLabel: "Close",
          action: () => ScaffoldMessenger.of(context).hideCurrentSnackBar());
    }
  }

  void _decheduleFeed() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    String token = await localStorage.get("token");
    String id = await localStorage.get("id");
    if (id != null && token != null) {
      Map<String, dynamic> response = await server.descheduleFeed(token, id);
      this._handleDescheduleFeedResponse(response);
    } else {
      // Logout
      this._navigateToHome();
    }
  }

  void _launchSetupPage() async {
    String url = "http://192.168.1.1/";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      showMessageBar(context, "Something went wrong", error: true);
    }
  }

  void onCardClick(int cardIdx) async {
    if (_cards[cardIdx] == _cards[2]) {
      this._launchSetupPage();
      return;
    }
    if (activeCard != _cards[cardIdx]) {
      setState(() {
        activeCard = _cards[cardIdx];
      });
    }
    if (activeCard == _cards[0]) {
      this._getScheduledFeed();
      return;
    }
    if (activeCard == _cards[1]) {
      this._feedNowModal();
      return;
    }
  }

  void _openScheduler(
      {bool reschedule = false, DateTime date, String datef, String timef}) {
    if (reschedule == true && date != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (date.difference(DateTime.now()).inSeconds <= 0) {
        showMessageBar(context, "Past schedule.",
            error: true, actionLabel: "Close", action: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        });
        setState(() {
          scheduledDate = "";
        });
        return;
      }
      if (date.difference(DateTime.now()).inMinutes <= 3) {
        showMessageBar(context, "Rescheduling not allowed.",
            error: true, actionLabel: "Close", action: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        });
        return;
      }
    }
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Container(
            height: reschedule == true ? 200 : 300,
            color: Color(0xFF737373),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
                color: Colors.white,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).requestFocus(new FocusNode());
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Scheduler(
                        reschedule: reschedule,
                        date: date,
                        datef: datef,
                        timef: timef)
                  ],
                ),
              ),
            ),
          );
        }).then((value) {
      if (value == true) {
        // Feed Scheduled
        this._getScheduledFeed();
      }
    });
  }

  void _feedNowModal() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Container(
            height: 230,
            color: Color(0xFF737373),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
                color: Colors.white,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).requestFocus(new FocusNode());
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[InstantFeed()],
                ),
              ),
            ),
          );
        }).then((value) {
      // Instant Feed Done
      setState(() {
        activeCard = _cards[0];
      });
    });
  }

  void _syncNotificationTokenWithServer() async {
    // CHECK IF FCM TOKEN IS SENT TO THE SERVER
    String token = await localStorage.get("token");
    String id = await localStorage.get("id");
    if (token != null && id != null) {
      String fcmToken = await FirebaseMessaging.instance.getToken();
      await server.sendNotificationToken(token, id, fcmToken);
    }
  }

  @override
  void initState() {
    super.initState();
    activeCard = _cards[0];
    _loading = true;
    _error = false;
    scheduledDate = "";
    this._getScheduledFeed();
    this._syncNotificationTokenWithServer();
  }

  @override
  Widget build(BuildContext context) {
    Widget _getCardContent() {
      if (_error == false) {
        return activeCard == _cards[0] || activeCard == _cards[1]
            ? ScheduleList(
                date: scheduledDate,
                scheduler: this._openScheduler,
                descheduler: this._decheduleFeed,
                loading: this._loading,
              )
            : Container();
      }
      return Container();
    }

    Widget _floatingActionButton() {
      if (_loading == true || _error == true) return Container();
      if (activeCard == _cards[0] && scheduledDate == "") {
        return FloatingActionButton.extended(
          onPressed: this._openScheduler,
          label: Text(
            'Schedule',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          icon: Icon(Icons.timer),
          tooltip: 'Schedule Feed',
          elevation: 2,
          backgroundColor: Color(0xFF0e2a47),
          foregroundColor: Theme.of(context).primaryColor,
        );
      }
      return Container();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Container(
        margin: EdgeInsets.only(left: 15.0, right: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0, 25.0, 0, 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Icon(
                      Icons.network_check,
                      color: Theme.of(context).textTheme.bodyText2.color,
                      size: 20.0,
                    ),
                  ),
                  Image.asset(
                    "assets/logo.png",
                    height: 70,
                  ),
                  GestureDetector(
                    onTap: this._logout,
                    child: Icon(
                      Icons.exit_to_app_rounded,
                      color: Theme.of(context).textTheme.bodyText2.color,
                      size: 20.0,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OptionCard(
                  id: 0,
                  title: "Schedule",
                  title2: "Feed",
                  icon: "assets/scheduler.png",
                  active: this.activeCard == _cards[0],
                  onClick: this.onCardClick,
                ),
                OptionCard(
                  id: 1,
                  title: "Release",
                  title2: "Food",
                  icon: "assets/feeder.png",
                  active: this.activeCard == _cards[1],
                  onClick: this.onCardClick,
                ),
                OptionCard(
                  id: 2,
                  title: "Connect",
                  title2: "Device",
                  icon: "assets/conn.png",
                  active: this.activeCard == _cards[2],
                  onClick: this.onCardClick,
                ),
              ],
            ),
            _getCardContent(),
          ],
        ),
      ),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

//FIXME: connect device ++ connection state ++ sound record
