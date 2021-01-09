import 'package:intl/intl.dart';
import 'package:carwash/resources/session.dart';
import 'package:flutter/material.dart';

class Wash {
  final int id;
  final int serverId;
  final int categoryId;
  final int serviceId;
  final int userId;
  final int startedAt;
  int finishedAt;
  int updatedAt;
  int duration; //in seconds
  final int price;
  final int finalPrice;
  int paid;
  final String plate;
  final String category;
  final String service;
  String washers;
  Map time;
  final Map discount;
  final String startTime;
  final String comment;
  final String photo;
  final String photoLocal;
  final String phone;
  final String marka;
  int durationStatus;
  List<String> washerIds;
  List services; //List<Map>
  final List boxes; //List<Map> WashBoxes
  final List updates; //string

  Wash.fromJson(Map<String, dynamic> fromJson)
      : id = fromJson['id'],
        serverId = fromJson['server_id'],
        categoryId = intVal(fromJson['category_id']),
        serviceId = intVal(fromJson['service_id']),
        userId = intVal(fromJson['user_id']),
        price = intVal(fromJson['price']),
        startedAt = fromJson['started_at'],
        finishedAt = fromJson['finished_at'],
        updatedAt = fromJson['updated_at'],
        duration = fromJson['duration'],
        comment = fromJson['comment'],
        category = fromJson['category'],
        service = fromJson['service'],
        photo = fromJson['photo'],
        photoLocal = fromJson['photo_local'],
        phone = fromJson['phone'],
        marka = fromJson['marka'],
        plate = setPlate(fromJson['plate']),
        paid = fromJson['paid'],
        durationStatus = fromJson['duration_status'],
        //additional = setServices(fromJson['additional']),
        washers = fillWashers(fromJson['washers']),
        washerIds = fillWasherIds(fromJson['washers']),
        time = fillTimes(fromJson),
        startTime = formatStart(fromJson['started_at']),
        services = fromJson['services'],
        boxes = fromJson['boxes'],
        discount = fromJson['discount'],
        finalPrice = intVal(fromJson['final_price']),
        updates = fromJson['updates'];

  static setPlate(String plate) {
    if (plate == '' || plate == null) {
      return '---';
    }
    return plate;
  }

  static intVal(val) {
    if (val == null) {
      return null;
    }
    return val is int ? val : int.parse(val);
  }

  static setServices(Map<String, dynamic> service) {
    List services = [];
    service.forEach((k, v) {
      services.add(v);
    });
    return services.join(', ');
  }

  static fillWashers(List washer) {
    List washers = [];
    if (washer != null) {
      washer.forEach((washerMap) {
        washers.add(washerMap['name']);
      });
      return washers.join(', ');
    }
    return null;
  }

  static fillWasherIds(List washer) {
    if (washer != null) {
      List<String> washers = [];
      washer.forEach((washerMap) {
        washers.add(washerMap['id'].toString());
      });
      return washers;
    }
    return null;
  }

  set setWasherIds(List washer) {
    if (washer != null) {
      //cprint('prov setWasherIds $washer');
      List<String> washers = [];
      washer.forEach((washerMap) {
        washers.add(washerMap['user_id'].toString());
      });
      this.washerIds = washers;
      //cprint('prov washerIds $washerIds');
    } else {
      //cprint('prov setWasherIds washer is null');
    }
  }

  static formatStart(int startedTs) {
    DateTime startDateTime =
        new DateTime.fromMillisecondsSinceEpoch(startedTs * 1000);
    return DateFormat('H:mm').format(startDateTime);
  }

  /* static formatFinish(int finishTs) {
    if (finishTs != null) {
      DateTime endTime =
          new DateTime.fromMillisecondsSinceEpoch(finishTs * 1000);
      String endTimeFormatted = DateFormat('H:mm').format(endTime);
      Duration difference = endTime.difference(startTime);
      if (difference.inDays > 0) {
        endTimeFormatted = DateFormat('d/M, H:mm').format(endTime);
      }
      differenceFormatted = _formatDuration(difference);
    }
    return null;
  } */

  //from server
  static fillTimes(Map fromJson) {
    Map<String, dynamic> time = {'end': null, 'duration': null};
    DateTime startTime =
        new DateTime.fromMillisecondsSinceEpoch(fromJson['started_at'] * 1000);
    String startTimeFormatted = '${startTime.day} ' +
        monthsAbbr[startTime.month] +
        ' ' +
        DateFormat('H:mm').format(startTime);
    time['start'] = startTimeFormatted;
    if (fromJson['finished_at'] != null) {
      DateTime endTime = new DateTime.fromMillisecondsSinceEpoch(
          fromJson['finished_at'] * 1000);
      String endTimeFormatted = DateFormat('H:mm').format(endTime);
      Duration difference = endTime.difference(startTime);
      if (difference.inDays > 0) {
        endTimeFormatted = '${endTime.day} ' +
            monthsAbbr[startTime.month] +
            ' ' +
            DateFormat('H:mm').format(endTime);
      }
      time['end'] = endTimeFormatted;
      time['duration'] = _formatDuration(difference);
    }
    return time;
  }

  set setTimes(Wash wash) {
    Map<String, dynamic> timeMap = {'end': null, 'duration': null};
    DateTime startTime =
        new DateTime.fromMillisecondsSinceEpoch(wash.startedAt * 1000);
    String startTimeFormatted = '${startTime.day} ' +
        monthsAbbr[startTime.month] +
        ' ' +
        DateFormat('H:mm').format(startTime);
    timeMap['start'] = startTimeFormatted;
    if (wash.finishedAt != null) {
      DateTime endTime =
          new DateTime.fromMillisecondsSinceEpoch(wash.finishedAt * 1000);
      String endTimeFormatted = DateFormat('H:mm').format(endTime);
      Duration difference = endTime.difference(startTime);
      if (difference.inDays > 0) {
        endTimeFormatted = '${endTime.day} ' +
            monthsAbbr[startTime.month] +
            ' ' +
            DateFormat('H:mm').format(endTime);
      }
      timeMap['end'] = endTimeFormatted;
      timeMap['duration'] = _formatDuration(difference);
    }
    this.time = timeMap;
  }

  static Widget timesWid(int start, int finish, int durStatus) {
    DateTime startTime = new DateTime.fromMillisecondsSinceEpoch(start * 1000);
    List<Widget> trow = [text16(DateFormat('H:mm').format(startTime))];

    if (finish != null) {
      DateTime endTime = new DateTime.fromMillisecondsSinceEpoch(finish * 1000);
      String endTimeFormatted = DateFormat('H:mm').format(endTime);
      Duration difference = endTime.difference(startTime);
      if (difference.inDays > 0) {
        endTimeFormatted = '${endTime.day} ' +
            monthsAbbr[startTime.month] +
            ' ' +
            DateFormat('H:mm').format(endTime);
      }
      trow.add(Text(' - '));
      trow.add(text16(endTimeFormatted));
      trow.add(SizedBox(width: 5.0));

      String durStr = _formatDuration(difference);
      Color clr;
      if (durStatus == 1) {
        clr = Colors.green;
      } else if (durStatus == 2) {
        clr = Colors.red[300];
      }
      trow.add(text16('('));
      trow.add(text16(durStr, clr: clr));
      trow.add(text16(')'));
    }
    return Row(children: trow);
  }

  static String getDate(int ts) {
    DateTime dt = new DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day} ' + monthsAbbr[dt.month];
  }

  static String _formatDuration(Duration dur) {
    String formatted = "";
    if (dur.inHours > 0) {
      formatted += dur.inHours.toString() + " ч ";
    }
    formatted += (dur.inMinutes % 60).toString() + " мин";
    return formatted;
  }

  set setPaid(int val) {
    paid = val;
  }

  set setProgress(String progress) {
    time['duration'] = progress;
  }
}
