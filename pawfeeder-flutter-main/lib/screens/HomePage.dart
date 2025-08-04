import 'package:app/helper/FirebaseMessaging.dart';
import 'package:app/helper/LocalStorage.dart';
import 'package:app/helper/MessageBar.dart';
import 'package:app/helper/Server.dart';
import 'package:app/screens/DeviceControl.dart';
import 'package:app/widgets/Login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Server server = Server();
  LocalStorage localStorage = LocalStorage();

  bool isAuthorizing;
  String errorMessage;

  void _navigateToDeviceScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => DeviceControl(),
      ),
      (route) => false,
    );
  }

  void _authorize() async {
    setState(() {
      isAuthorizing = true;
    });
    String token = await localStorage.get("token");
    String id = await localStorage.get("id");
    bool allowAccess = false;
    if (token != null && id != null) {
      allowAccess = await server.isAuthorized(token, id);
    }
    if (allowAccess == null) {
      setState(() {
        errorMessage = "Voops! Something went wrong.";
        isAuthorizing = false;
      });
      showMessageBar(context, "Connection not available.",
          error: true, actionLabel: "Refresh", action: this._authorize);
      return;
    }
    if (allowAccess == true) {
      this._navigateToDeviceScreen();
      return;
    } else if (allowAccess == false) {
      await localStorage.del("token");
      await localStorage.del("id");
      await localStorage.del("fcmToken");
    }
    setState(() {
      isAuthorizing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    this._authorize();
    configureFirebaseMessaging();
  }

  @override
  Widget build(BuildContext context) {
    var _default = Container(
      child: Center(
        child: isAuthorizing == true || errorMessage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    errorMessage == null
                        ? CircularProgressIndicator()
                        : Icon(
                            Icons.error_outline,
                            color: Theme.of(context).textTheme.bodyText2.color,
                          ),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                    ),
                    Text(
                      errorMessage == null ? "Authorizing" : errorMessage,
                      style: Theme.of(context).textTheme.bodyText2,
                    )
                  ])
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 150.0),
                  ),
                  Image.asset(
                    "assets/petfeed.jpg",
                    height: 250,
                    width: 250,
                  ),
                  Text(
                    "Voops! Couldn't find any PawFeeder.",
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                ],
              ),
      ),
    );

    void _login() {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return Container(
              height: 400,
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
                    FocusScopeNode currentFocus = FocusScope.of(context);

                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[Login()],
                  ),
                ),
              ),
            );
          }).then((value) {
        if (value == true) {
          // Device added
          this._navigateToDeviceScreen();
        }
      });
    }

    var _fab = isAuthorizing == true || errorMessage != null
        ? Container()
        : FloatingActionButton.extended(
            onPressed: _login,
            label: Text(
              'PawFeeder',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            icon: Icon(Icons.add),
            tooltip: 'Add PawFeeder',
            elevation: 2,
            backgroundColor: Color(0xFF0e2a47),
            foregroundColor: Theme.of(context).primaryColor,
          );

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: _default,
      floatingActionButton: _fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
