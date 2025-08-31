// lib/widgets/Scheduler.dart
import 'package:paw_ui/widgets/CarouselPicker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Scheduler extends StatefulWidget {
  /// When true, shows reschedule mode (no portion picker).
  final bool? reschedule;
  final String? datef, timef;
  final DateTime? date;

  /// UI-only: parent can listen when user confirms scheduling/rescheduling.
  /// If [reschedule] == true, portionSize may be null.
  final void Function({
    DateTime? scheduledDateTime,
    String? portionSize,
  })? onSubmit;

  const Scheduler({
    super.key,
    this.reschedule,
    this.date,
    this.datef,
    this.timef,
    this.onSubmit,
  });

  @override
  State<Scheduler> createState() => _SchedulerState();
}

class _SchedulerState extends State<Scheduler> {
  String? datef, timef, _message;
  bool _scheduling = false, _error = false, _scheduled = false;
  DateTime? scheduledDate;
  TimeOfDay? scheduledTime;

  String? portionSize;
  final List<String> portionSizes = const [
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
  int defaultPosition = 3;

  void selectedPortion(String v) {
    portionSize = v;
  }

  bool _selectableDateRange(DateTime day) {
    return day.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
        day.isBefore(DateTime.now().add(const Duration(days: 10)));
  }

  Future<void> _pickDate() async {
    if (_error) {
      setState(() {
        _message = "";
        _error = false;
      });
    }

    final currentDate = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: scheduledDate ?? currentDate,
      firstDate: currentDate,
      lastDate: DateTime(currentDate.year + 1),
      selectableDayPredicate: _selectableDateRange,
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );

    if (pickedDate != null) {
      scheduledDate = pickedDate;
      setState(() {
        datef = DateFormat.yMMMd('en_US').format(scheduledDate!);
      });
    }
  }

  Future<void> _pickTime() async {
    if (_error) {
      setState(() {
        _message = "";
        _error = false;
      });
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: scheduledTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (pickedTime != null) {
      scheduledTime = pickedTime;
      setState(() {
        timef = pickedTime.format(context);
      });
    }
  }

  void _scheduleFeed() {
    setState(() {
      _scheduling = true;
      _error = false;
      _message = "";
      _scheduled = false;
    });

    if (scheduledDate != null && scheduledTime != null) {
      final combined = DateTime(
        scheduledDate!.year,
        scheduledDate!.month,
        scheduledDate!.day,
        scheduledTime!.hour,
        scheduledTime!.minute,
      );

      if (combined.isAfter(DateTime.now())) {
        widget.onSubmit?.call(
          scheduledDateTime: combined,
          portionSize: (widget.reschedule == true) ? null : portionSize,
        );
        setState(() {
          _scheduled = true;
          _scheduling = false;
        });
        Navigator.pop(context, true);
        return;
      } else {
        setState(() {
          _error = true;
          _message = "Please select valid date and time.";
          _scheduling = false;
        });
        return;
      }
    }

    // Validation messages
    if (scheduledDate == null && scheduledTime == null) {
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
    datef = widget.datef ?? "";
    timef = widget.timef ?? "";
    scheduledTime =
        widget.date != null ? TimeOfDay.fromDateTime(widget.date!) : null;
    scheduledDate = widget.date;
    portionSize = portionSizes[defaultPosition];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dateTimeView = Container(
      margin: const EdgeInsets.only(top: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Select date and time:",
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickDate,
                child: Row(
                  children: [
                    const Icon(Icons.date_range, size: 15.0),
                    Container(
                      margin: const EdgeInsets.all(6.0),
                      child: Text(
                        (datef == null || datef!.isEmpty) ? "Date" : "$datef",
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(10.0),
                child: Text(
                  "|",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 20.0,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _pickTime,
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 15.0),
                    Container(
                      margin: const EdgeInsets.all(6.0),
                      child: Text(
                        (timef == null || timef!.isEmpty) ? "Time" : "$timef",
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
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

    final portionPickerView = (widget.reschedule == true)
        ? const SizedBox.shrink()
        : Container(
            margin: const EdgeInsets.only(top: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Select feeding portion size:",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 16.0),
                  child: CarouselPicker(
                    values: portionSizes,
                    onSelect: selectedPortion,
                    defaultPosition: defaultPosition,
                  ),
                ),
              ],
            ),
          );

    final messageBar = Container(
      width: MediaQuery.of(context).size.width,
      height: 30.0,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        color: _error != true
            ? (theme.textTheme.bodyMedium?.color ?? Colors.black54)
                .withOpacity(0.1)
            : Colors.red,
      ),
      child: Center(
        child: Text(
          _message ?? "",
          style: const TextStyle(
            color: Color(0xFFffffff),
            fontWeight: FontWeight.w700,
            fontSize: 14.0,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );

    final scheduleBtn = Container(
      margin: const EdgeInsets.only(top: 20.0),
      child: _scheduling
          ? const Center(child: RefreshProgressIndicator())
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: _scheduled
                    ? const Color(0xFFffffff)
                    : const Color(0xFF0e2a47),
                backgroundColor: _scheduled
                    ? Colors.green
                    : theme.colorScheme.primary,
                elevation: 0.5,
              ),
              onPressed: _scheduled ? null : _scheduleFeed,
              child: Text(
                _scheduled ? 'Scheduled' : 'Schedule',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                  letterSpacing: 0.4,
                ),
              ),
            ),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        messageBar,
        dateTimeView,
        portionPickerView,
        scheduleBtn,
      ],
    );
  }
}
