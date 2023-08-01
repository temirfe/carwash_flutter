import 'dart:async';
import 'package:flutter/material.dart';
//import 'package:carwash/resources/session.dart';

Widget startStrBuild(int start, bool everyMinute, {Color? color}) {
  return StreamBuilder(
      stream: timerStream(start, everyMinute),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (!snapshot.hasData) {
          return Text(_formatProgress(getDifference(start), everyMinute),
              style: TextStyle(color: color));
        }
        return Text(snapshot.data!, style: TextStyle(color: color));
      });
}

String _formatProgress(Duration dur, bool everyMinute) {
  String hoursMinutes = dur.inHours.toString().padLeft(2, '0') +
      ':' +
      (dur.inMinutes % 60).toString().padLeft(2, '0');
  if (everyMinute) {
    return hoursMinutes;
  }
  //return hoursMinutes + ':' + (dur.inSeconds % 60).toString().padLeft(2, '0');
  return dur.inMinutes.toString() +
      ':' +
      (dur.inSeconds % 60).toString().padLeft(2, '0');
}

Duration getDifference(int start) {
  DateTime startTime = new DateTime.fromMillisecondsSinceEpoch(start * 1000);
  final DateTime now = DateTime.now();

  return now.difference(startTime);
}

Stream<String> timerStream(int startTS, bool everyMinute) {
  StreamController<String>? streamController;
  Timer? timer;
  Duration timerInterval;
  if (everyMinute) {
    timerInterval = Duration(minutes: 1);
  } else {
    timerInterval = Duration(seconds: 1);
  }

  void stopTimer() {
    //cprint('stream stopTimer');
    if (timer != null) {
      timer!.cancel();
      timer = null;
      streamController?.close();
    }
  }

  void getProgress(int start) {
    streamController?.add(_formatProgress(getDifference(start), everyMinute));
  }

  void startTimer() {
    //cprint('stream startTimer');
    timer = Timer.periodic(timerInterval, (Timer t) => getProgress(startTS));
  }

  streamController = StreamController<String>(
    onListen: startTimer,
    onCancel: stopTimer,
    onResume: startTimer,
    onPause: stopTimer,
  );

  return streamController.stream.asBroadcastStream();
}
