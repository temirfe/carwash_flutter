import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:carwash/resources/request.dart';
import 'package:provider/provider.dart';
import 'package:device_info/device_info.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:carwash/resources/session.dart';
import 'package:carwash/resources/provider.dart';
import 'package:carwash/resources/navbar.dart';
//import 'package:carwash/resources/dbhelper.dart';
import 'washList.dart';
import 'analytics.dart';
import 'settings.dart';
import 'package:intl/intl.dart';
import 'package:ansicolor/ansicolor.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RootProvider prov;
  List<Widget> _widgetOptions;
  String today, yesterday, beforeYesterday;
  //Timer exportTimer, importTimer;

  @override
  void initState() {
    super.initState();
    prov = Provider.of<RootProvider>(context, listen: false);
    /* if (prov.ctgsMap.length == 0) {
      prov.requestCtgs();
    } */
    prov.requestList();
    prov.formRequests();
    prov.requestAllday();

    //syncWithServer();

    cprint('home init');
    final DateTime now = DateTime.now();
    final DateTime yesterdayDT = new DateTime(now.year, now.month, now.day - 1);
    final DateTime beforeYesterdayDT =
        new DateTime(now.year, now.month, now.day - 2);
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    today = formatter.format(now);
    yesterday = formatter.format(yesterdayDT);
    beforeYesterday = formatter.format(beforeYesterdayDT);
    prov.today = today;
  }

  /* void syncWithServer() async {
    //cprint('home init formRequest sent');
    await prov.formRequests();
    // cprint('home init formRequest finished');
    prov.requestListFromDb();
    if (session.getString('deviceId') == null) {
      await _getDeviceId();
    }
    await prov.exportWash();
    prov.importWash();
    const exportDelay = const Duration(seconds: 25);
    const importDelay = const Duration(seconds: 30);
    exportTimer =
        new Timer.periodic(exportDelay, (Timer t) => prov.exportWash());
    importTimer =
        new Timer.periodic(importDelay, (Timer t) => prov.importWash());

    prov.deleteOldWashesLocal();
  } */

  @override
  Widget build(BuildContext context) {
    prov.setContext(context);
    return Consumer<RootProvider>(builder: (context, prov, child) {
      //cprint('home build');
      _widgetOptions = <Widget>[
        washList(context, prov),
        analytics(context, prov),
        settings(context, prov),
      ];
      String appTitle = session.getString('username');
      if (appTitle == null) {
        appTitle = 'CarWash';
      }
      /* if (prov.navIndex == 1) {
        appTitle = 'Новая мойка';
      } */
      String iniDay = prov.showListFromDate;
      if (iniDay == null) {
        iniDay = today;
      }
      List<Widget> titleRow = [
        new Theme(
          child: new DropdownButtonHideUnderline(
            child: new DropdownButton<String>(
              value: iniDay,
              items: <DropdownMenuItem<String>>[
                new DropdownMenuItem(
                  child: new Text('Сегодня'),
                  value: today,
                ),
                new DropdownMenuItem(
                  child: new Text('Вчера'),
                  value: yesterday,
                ),
                new DropdownMenuItem(
                  child: new Text('Позавчера'),
                  value: beforeYesterday,
                ),
              ],
              onChanged: (String value) {
                //prov.requestListFromDb();
                prov.setDay(value);
                prov.requestList();
              },
            ),
          ),
          data: new ThemeData.dark(),
        ),
        SizedBox(
          width: 6.0,
        ),
      ];
      if (prov.queryPlate != '') {
        titleRow.add(Text(prov.queryPlate));
        titleRow.add(IconButton(
            icon: Icon(Icons.delete),
            iconSize: 20,
            onPressed: () {
              prov.washesMap = {};
              prov.plateQueryRequest('');
            }));
      }
      return Scaffold(
        appBar: AppBar(
          //title: Text(appTitle),
          title: Row(
            children: titleRow,
          ),
          actions: <Widget>[
            InkWell(
              child: Padding(
                child: Icon(Icons.exit_to_app),
                padding: EdgeInsets.all(6.0),
              ),
              onTap: () {
                session.clear();
                prov.loginSuccess = false;
                Navigator.pushReplacementNamed(context, 'login');
              },
            ),
          ],
        ),
        bottomNavigationBar: navbar(prov),
        body: Center(
          child: _widgetOptions.elementAt(prov.navIndex),
          //child: _widgetOptions.elementAt(0),
        ),
        floatingActionButton: Visibility(
          visible: prov.fabVisible,
          child: FloatingActionButton.extended(
            onPressed: () {
              //prov.formRequests();
              Navigator.pushNamed(context, 'add');
            },
            label: Text('Новая мойка'),
            icon: Icon(Icons.add),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    //cprint('home dispose');
    //prov.washesMap = {};
    prov.closeStreams();
    //exportTimer.cancel();
    //importTimer.cancel();
    super.dispose();
  }

  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        //cprint('androidId ${build.androidId}');
        session.setString('deviceId', build.androidId);
        return build.androidId; //UUID for Android
      } else if (Platform.isIOS) {
        var data = await deviceInfoPlugin.iosInfo;
        session.setString('deviceId', data.identifierForVendor);
        return data.identifierForVendor; //UUID for iOS
      }
    } on PlatformException {
      print('Failed to get platform version');
    }
    return null;
  }
}
