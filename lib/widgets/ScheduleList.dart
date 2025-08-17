import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleList extends StatelessWidget {
  final String date;
  final Function? scheduler;
  final VoidCallback? descheduler;
  final bool loading;

  const ScheduleList({
    super.key,
    this.date = "",
    this.scheduler,
    this.descheduler,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? datef;
    String? timef;
    DateTime? parsedDate;
    if (date.isNotEmpty) {
      parsedDate = DateTime.parse(date).toLocal();
      datef = DateFormat.yMMMd('en_US').format(parsedDate);
      timef = DateFormat.jm().format(parsedDate);
    }

    final cardWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20.0, left: 5.0),
          child: Text(
            "Upcoming",
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Card(
          color: const Color(0xFFffffff),
          shadowColor: const Color(0xFFf9f9f9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.date_range,
                          color: theme.textTheme.bodyMedium?.color, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        "$datef",
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ]),
                    Row(children: [
                      Icon(Icons.timer,
                          color: theme.textTheme.bodyMedium?.color, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        "$timef",
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF0e2a47),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      onPressed: () => scheduler?.call(
                        reschedule: true,
                        date: parsedDate,
                        datef: datef,
                        timef: timef,
                      ),
                      child: const Text(
                        'Reschedule',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        foregroundColor: const Color(0xFFff3300),
                        backgroundColor: const Color(0xFFffffff),
                      ),
                      onPressed: descheduler,
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                          letterSpacing: 0.4,
                        ),
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
      margin: const EdgeInsets.fromLTRB(0, 25.0, 0, 0),
      child: (date.isEmpty || loading)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Icon(Icons.lock_clock,
                      size: 36, color: theme.textTheme.bodyMedium?.color),
                const SizedBox(height: 5),
                Text(
                  loading ? "Fetching" : "You haven't scheduled any feed!",
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            )
          : cardWidget,
    );
  }
}
