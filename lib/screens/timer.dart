import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<TimePage> {
  String _timeString = "--:--";
  Timer timer;

  @override
  void initState() {
    print('timer init state');
    //_timeString = _formatDateTime(DateTime.now());
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(_timeString),
    );
  }

  void _getTime() {
    final DateTime now = DateTime.now();

    DateTime start = new DateTime.fromMillisecondsSinceEpoch(1596973462000);
    Duration difference = now.difference(start);

    final String formattedDateTime = _formatDateTime(difference);
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  String _formatDateTime(Duration dur) {
    return dur.inHours.toString().padLeft(2, '0') +
        ':' +
        (dur.inMinutes % 60).toString().padLeft(2, '0') +
        ':' +
        (dur.inSeconds % 60).toString().padLeft(2, '0');
    //return DateFormat('MM/dd/yyyy hh:mm:ss').format(dateTime);
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
