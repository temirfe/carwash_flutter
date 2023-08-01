import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ansicolor/ansicolor.dart';

late SharedPreferences session;
sessionSaveAuth(Map<String, dynamic> map) {
  session.setInt('userId', map['id']);
  //session.setInt('roleId', map['role_id']);
  session.setString('username', map['username']);
  session.setString('authKey', map['auth_key']);
}

// makes print() colorful // 1 - red, 2 - green, 3 - blue
cprint(dynamic msg, {int? color = 2}) {
  ansiColorDisabled = false;
  AnsiPen pen = AnsiPen();
  pen.white();
  switch (color) {
    case 0:
      pen.rgb(r: 1.0, g: 0.6, b: 0.2);
      break;
    case 1:
      pen.rgb(r: 0.6, g: 1.0, b: 0.2);
      break;
    default:
      pen.rgb(r: 0.2, g: 0.6, b: 1.0);
  }

  debugPrint(pen(msg.toString()));
}

Widget padh(Widget child, double pad) {
  return Padding(padding: EdgeInsets.symmetric(horizontal: pad), child: child);
}

List<String> monthsAbbr = [
  '',
  'Янв',
  'Фев',
  'Мар',
  'Апр',
  'Май',
  'Июн',
  'Июл',
  'Авг',
  'Сен',
  'Окт',
  'Ноя',
  'Дек'
];

Widget lbl(String title) {
  return Container(
      width: 100.0,
      child: Text(title, style: TextStyle(fontSize: 12.0, color: Colors.grey)));
}

Widget text16(String tx, {Color? clr}) {
  TextStyle ts = TextStyle(fontSize: 16.0);
  if (clr != null) {
    ts = TextStyle(fontSize: 16.0, color: clr);
  }
  return Text(tx, style: ts);
}

Text textLink(String str, {double? size}) {
  TextStyle ts = TextStyle(color: Colors.blue[300]);
  if (size != null) {
    ts = TextStyle(color: Colors.blue[300], fontSize: size);
  }
  return Text(str, style: ts);
}
