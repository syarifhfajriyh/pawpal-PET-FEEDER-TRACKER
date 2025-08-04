import 'package:app/helper/LocalStorage.dart';
import 'package:app/helper/Server.dart';
import 'package:app/screens/HomePage.dart';
import 'package:app/widgets/CarouselPicker.dart';
import 'package:flutter/material.dart';

class InstantFeed extends StatefulWidget {
  @override
  _InstantFeedState createState() => _InstantFeedState();
}

class _InstantFeedState extends State<InstantFeed> {
  Server server = Server();
  LocalStorage localStorage = LocalStorage();

  bool _error, _loading;
  String _message;
  String portionSize;
  List<String> portionSizes = [
    "100g",
    "200g",
    "300g",
    "400g",
    "500g",
    "600g",
    "700g",
    "800g",
    "900g"
  ];
  int defaultPosition;

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => HomePage(),
      ),
      (route) => false,
    );
  }

  void selectedPortion(String portionSize) {
    this.portionSize = portionSize;
  }

  void _handleResponse(Map<String, dynamic> response) {
    if (response == null) {
      setState(() {
        _error = true;
        _message = "Request failed.";
      });
    } else if (response["success"] == true) {
      setState(() {
        _loading = false;
        _message = "Feed request sent.";
      });
    } else if (response["success"] == false &&
        response.containsKey("action") &&
        response["action"] == "LOGOUT") {
      // Logout
      this._navigateToHome();
    } else if (response.containsKey("message")) {
      setState(() {
        _error = true;
        _message = response["message"];
        _loading = false;
      });
    }
  }

  void _feedNow() async {
    if (this._error == true) {
      setState(() {
        _message = "";
        _error = false;
      });
    }
    String token = await localStorage.get('token');
    String id = await localStorage.get('id');
    if (token != null && id != null) {
      Map<String, dynamic> response;
      int quantity =
          int.parse(portionSize.substring(0, portionSize.length - 1));
      response = await server.feedNow(token, id, quantity);
      this._handleResponse(response);
    } else {
      // Logout
      this._navigateToHome();
    }
  }

  @override
  void initState() {
    super.initState();
    defaultPosition = 3;
    portionSize = portionSizes[defaultPosition];
    _message = "";
    _error = false;
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    var portionSizeView = Container(
      margin: EdgeInsets.only(top: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            child: Text(
              "Select feeding portion size:",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyText2.color,
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 16.0),
            child: CarouselPicker(
                values: this.portionSizes,
                onSelect: this.selectedPortion,
                defaultPosition: defaultPosition),
          ),
        ],
      ),
    );

    var messageBar = Container(
      width: MediaQuery.of(context).size.width,
      height: 30.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15), topRight: Radius.circular(15)),
        color: _error != true
            ? _message != ""
                ? Colors.green
                : Theme.of(context).textTheme.bodyText2.color.withOpacity(0.1)
            : Colors.red,
      ),
      child: Center(
        child: Text(
          '$_message',
          style: TextStyle(
            color: Color(0xFFffffff),
            fontWeight: FontWeight.w700,
            fontSize: 14.0,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );

    var feedBtn = Container(
      margin: EdgeInsets.only(top: 20.0),
      child: _loading
          ? Center(
              child: RefreshProgressIndicator(),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                onPrimary: Color(0xFF0e2a47),
                primary: Theme.of(context).primaryColor,
                elevation: 0.5,
              ),
              child: Text(
                'Feed Now',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                  letterSpacing: 0.4,
                ),
              ),
              onPressed: this._feedNow,
            ),
    );

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [messageBar, portionSizeView, feedBtn],
      ),
    );
  }
}
