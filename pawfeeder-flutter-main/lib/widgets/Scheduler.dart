import 'package:app/helper/LocalStorage.dart';
import 'package:app/helper/Server.dart';
import 'package:app/screens/HomePage.dart';
import 'package:app/widgets/CarouselPicker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Scheduler extends StatefulWidget {
  final bool reschedule;
  final String datef, timef;
  final DateTime date;
  Scheduler({Key key, this.reschedule, this.date, this.datef, this.timef})
      : super(key: key);
  @override
  _SchedulerState createState() => _SchedulerState();
}

class _SchedulerState extends State<Scheduler> {
  Server server = new Server();
  LocalStorage localStorage = new LocalStorage();

  String datef, timef, _message;
  bool _scheduling, _error, _scheduled;
  DateTime scheduledDate;
  TimeOfDay scheduledTime;
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

  bool _selectableDateRange(DateTime day) {
    if ((day.isAfter(DateTime.now().subtract(Duration(days: 1))) &&
        day.isBefore(DateTime.now().add(Duration(days: 10))))) {
      return true;
    }
    return false;
  }

  void _pickDate() async {
    if (this._error == true) {
      setState(() {
        _message = "";
        _error = false;
      });
    }
    DateTime currentDate = DateTime.now();
    final DateTime pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: currentDate,
      lastDate: DateTime(currentDate.year + 1),
      selectableDayPredicate: _selectableDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child,
        );
      },
    );
    if (pickedDate != null && pickedDate != currentDate) {
      scheduledDate = pickedDate;
      setState(() {
        datef = DateFormat.yMMMd('en_US').format(scheduledDate);
      });
    }
  }

  void _pickTime() async {
    if (this._error == true) {
      setState(() {
        _message = "";
        _error = false;
      });
    }

    TimeOfDay currentTime = TimeOfDay.now();
    final TimeOfDay pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark(),
          child: child,
        );
      },
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (pickedTime != null && pickedTime != currentTime) {
      scheduledTime = pickedTime;
      setState(() {
        timef = scheduledTime.format(context);
      });
    }
  }

  void _handleResponse(Map<String, dynamic> response) {
    if (response == null) {
      setState(() {
        _error = true;
        _message = "Request failed.";
        _scheduling = false;
      });
    } else if (response["success"] == true) {
      setState(() {
        _scheduled = true;
        _scheduling = false;
      });
      Navigator.pop(context, true);
    } else if (response["success"] == false &&
        response.containsKey("action") &&
        response["action"] == "LOGOUT") {
      // Logout
      this._navigateToHome();
    } else if (response.containsKey("message")) {
      setState(() {
        _error = true;
        _message = response["message"];
        _scheduling = false;
      });
    }
  }

  void _sendRequest(String date) async {
    String token = await localStorage.get('token');
    String id = await localStorage.get('id');
    if (token != null && id != null) {
      Map<String, dynamic> response;
      if (widget.reschedule == true) {
        response = await server.rescheduleFeed(token, id, date);
      } else {
        int quantity =
            int.parse(portionSize.substring(0, portionSize.length - 1));
        response = await server.scheduleFeed(token, id, date, quantity);
      }
      this._handleResponse(response);
    } else {
      // Logout
      this._navigateToHome();
    }
  }

  void _scheduleFeed() async {
    setState(() {
      _scheduling = true;
      _error = false;
      _message = "";
      _scheduled = false;
    });
    String date;
    if (scheduledDate != null && scheduledTime != null) {
      scheduledDate = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );
      date = scheduledDate.compareTo(DateTime.now()) > 0
          ? scheduledDate.toUtc().toString()
          : null;
      if (date != null) {
        this._sendRequest(date);
      } else {
        setState(() {
          _error = true;
          _message = "Please select valid date and time.";
          _scheduling = false;
        });
      }
    } else if (scheduledDate == null && scheduledTime == null) {
      setState(() {
        _error = true;
        _message = "Please select date and time.";
        _scheduling = false;
      });
    } else if (scheduledDate == null) {
      setState(() {
        _error = true;
        _message = "Please select a date.";
        _scheduling = false;
      });
    } else if (scheduledTime == null) {
      setState(() {
        _error = true;
        _message = "Please select a time.";
        _scheduling = false;
      });
    } else {
      setState(() {
        _error = true;
        _message = "Something went wrong!";
        _scheduling = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    datef = widget.datef != null ? widget.datef : "";
    timef = widget.timef != null ? widget.timef : "";
    scheduledTime =
        widget.date != null ? TimeOfDay.fromDateTime(widget.date) : null;
    scheduledDate = widget.date;
    _message = "";
    _error = false;
    _scheduling = false;
    _scheduled = false;
    defaultPosition = 3;
    portionSize = portionSizes[defaultPosition];
  }

  @override
  Widget build(BuildContext context) {
    var dateTimeView = Container(
      margin: EdgeInsets.only(top: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            child: Text(
              "Select date and time:",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyText2.color,
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: this._pickDate,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 15.0,
                    ),
                    Container(
                      margin: EdgeInsets.all(6.0),
                      child: Text(
                        datef == "" ? "Date" : "$datef",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText1.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.all(10.0),
                child: Text(
                  "|",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText2.color,
                    fontWeight: FontWeight.normal,
                    fontSize: 20.0,
                  ),
                ),
              ),
              GestureDetector(
                onTap: this._pickTime,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 15.0,
                    ),
                    Container(
                      margin: EdgeInsets.all(6.0),
                      child: Text(
                        timef == "" ? "Time" : "$timef",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText1.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    var portionPickerView = widget.reschedule != true
        ? Container(
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
          )
        : Container();

    var messageBar = Container(
      width: MediaQuery.of(context).size.width,
      height: 30.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15), topRight: Radius.circular(15)),
        color: _error != true
            ? Theme.of(context).textTheme.bodyText2.color.withOpacity(0.1)
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

    var scheduleBtn = Container(
      margin: EdgeInsets.only(top: 20.0),
      child: _scheduling
          ? Center(
              child: RefreshProgressIndicator(),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                onPrimary:
                    _scheduled == true ? Color(0xFFffffff) : Color(0xFF0e2a47),
                primary: _scheduled == true
                    ? Colors.green
                    : Theme.of(context).primaryColor,
                elevation: 0.5,
              ),
              child: Text(
                _scheduled == true ? 'Scheduled' : 'Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                  letterSpacing: 0.4,
                ),
              ),
              onPressed: _scheduled == true ? () {} : this._scheduleFeed,
            ),
    );

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          messageBar,
          dateTimeView,
          portionPickerView,
          scheduleBtn,
        ],
      ),
    );
  }
}
