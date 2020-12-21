import 'package:flutter/material.dart';
import 'dart:async';

//from https://www.youtube.com/watch?v=nfU8HMwCtRQ

bool startBtnEnabled = true;
bool stopBtnDisabled = true;
bool resetBtnDisabled = true;

String timeDisplay = '00:00:00';

Stopwatch swatch = Stopwatch();

void startSW() {
  startBtnEnabled = false; //setstate
  stopBtnDisabled = false; //setstate
  swatch.start();
  startTimer();
}

void stopSW() {
  resetBtnDisabled = false; //setstate
  stopBtnDisabled = true; //setstate
  swatch.stop();
}

void resetSW() {
  resetBtnDisabled = true; //setstate
  startBtnEnabled = true; //setstate
  swatch.reset();
  timeDisplay = '00:00:00';
}

void startTimer() {
  Timer(const Duration(seconds: 1), keepRunning);
}

void keepRunning() {
  if (swatch.isRunning) {
    startTimer();
  }

  //setstate
  timeDisplay = swatch.elapsed.inHours.toString().padLeft(2, '0') +
      ':' +
      (swatch.elapsed.inMinutes % 60).toString().padLeft(2, '0') +
      ':' +
      (swatch.elapsed.inSeconds % 60).toString().padLeft(2, '0');
}

Widget stopwatch() {
  return Container(
    child: Column(
      children: [
        Expanded(
            flex: 6,
            child: Container(
              alignment: Alignment.center,
              child: Text(timeDisplay,
                  style: TextStyle(fontSize: 50, fontWeight: FontWeight.w700)),
            )),
        Expanded(
            flex: 4,
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RaisedButton(
                        onPressed: stopBtnDisabled ? null : stopSW,
                        color: Colors.red,
                        padding: EdgeInsets.symmetric(
                            horizontal: 40.0, vertical: 15.0),
                        child: Text('Stop',
                            style:
                                TextStyle(fontSize: 20.0, color: Colors.white)),
                      ),
                      RaisedButton(
                        onPressed: resetBtnDisabled ? null : resetSW,
                        color: Colors.teal,
                        padding: EdgeInsets.symmetric(
                            horizontal: 40.0, vertical: 15.0),
                        child: Text('Reset',
                            style:
                                TextStyle(fontSize: 20.0, color: Colors.white)),
                      ),
                    ],
                  ),
                  RaisedButton(
                    onPressed: startBtnEnabled ? startSW : null,
                    color: Colors.green,
                    padding:
                        EdgeInsets.symmetric(horizontal: 80.0, vertical: 20.0),
                    child: Text('Start',
                        style: TextStyle(fontSize: 24.0, color: Colors.white)),
                  ),
                ],
              ),
            )),
      ],
    ),
  );
}
