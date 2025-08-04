import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleList extends StatelessWidget {
  final String date;
  final Function scheduler;
  final Function descheduler;
  final bool loading;
  const ScheduleList(
      {Key key, this.date = "", this.scheduler, this.descheduler, this.loading})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String datef;
    String timef;
    DateTime parsedDate;
    if (date != "") {
      parsedDate = DateTime.parse(date).toLocal();
      datef = DateFormat.yMMMd('en_US').format(parsedDate);
      timef = DateFormat.jm().format(parsedDate);
    }
    var cardWidget = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 20.0, left: 5.0),
          child: Text(
            "Upcoming",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyText2.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Card(
          color: Color(0xFFffffff),
          shadowColor: Color(0xFFf9f9f9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          color: Theme.of(context).textTheme.bodyText2.color,
                          size: 15.0,
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                        ),
                        Text(
                          "$datef",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText1.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: Theme.of(context).textTheme.bodyText2.color,
                          size: 15.0,
                        ),
                        Padding(
                          padding: EdgeInsets.all(5.0),
                        ),
                        Text(
                          "$timef",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyText1.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(padding: EdgeInsets.all(10.0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFF0e2a47),
                          primary: Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          'Reschedule',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.0,
                            letterSpacing: 0.4,
                          ),
                        ),
                        onPressed: () => this.scheduler(
                          reschedule: true,
                          date: parsedDate,
                          datef: datef,
                          timef: timef,
                        ),
                      ),
                    ),
                    Container(
                      child: ElevatedButton(
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.0,
                            letterSpacing: 0.4,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          onPrimary: Color(0xFFff3300),
                          primary: Color(0xFFffffff),
                        ),
                        onPressed: this.descheduler,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height - 450,
      margin: EdgeInsets.fromLTRB(0, 25.0, 0, 0),
      child: date == "" || loading == true
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                loading == true
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Icon(
                        Icons.lock_clock,
                        size: 36.0,
                        color: Theme.of(context).textTheme.bodyText2.color,
                      ),
                Padding(
                  padding: EdgeInsets.all(5.0),
                ),
                Text(
                  loading == true
                      ? "Fetching"
                      : "You haven't scheduled any feed!",
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ],
            )
          : cardWidget,
    );
  }
}
