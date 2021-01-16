import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ansicolor/ansicolor.dart';

SharedPreferences session;
sessionSaveAuth(Map<String, dynamic> map) {
  session.setInt('userId', map['id']);
  //session.setInt('roleId', map['role_id']);
  session.setString('username', map['username']);
  session.setString('authKey', map['auth_key']);
}

cprint(String msg) {
  ansiColorDisabled = false;
  AnsiPen pen = new AnsiPen()
    ..white()
    ..rgb(r: 1.0, g: 0.8, b: 0.2);

  print(pen(msg));
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

Widget text16(String tx, {Color clr}) {
  TextStyle ts = TextStyle(fontSize: 16.0);
  if (clr != null) {
    ts = TextStyle(fontSize: 16.0, color: clr);
  }
  return Text(tx, style: ts);
}

Text textLink(String str, {double size}) {
  TextStyle ts = TextStyle(color: Colors.blue[300]);
  if (size != null) {
    ts = TextStyle(color: Colors.blue[300], fontSize: size);
  }
  return Text(str, style: ts);
}
