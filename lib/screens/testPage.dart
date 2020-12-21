import 'package:flutter/material.dart';
//import 'package:carwash/resources/request.dart';
import 'package:provider/provider.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:carwash/resources/session.dart';
import 'package:carwash/resources/provider.dart';
import 'package:carwash/resources/dbhelper.dart';
import 'washList.dart';
import 'analytics.dart';
import 'settings.dart';
import 'package:intl/intl.dart';

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  RootProvider prov;
  final DatabaseHelper db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    prov = Provider.of<RootProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('test')),
      body: ListView(children: [
        RaisedButton(
            child: Text('export wash'),
            onPressed: () async {
              prov.exportWash();
            }),
        RaisedButton(
            child: Text('oldvals'),
            onPressed: () async {
              List<Map<String, dynamic>> oldVals = await db.findAll('wash',
                  where: 'id=10',
                  fields: 'category_id,plate,service_id,phone,marka');
              // cprint('oldVals ${oldVals[0]}');
            }),
        RaisedButton(
            child: Text('Read ctg'),
            onPressed: () async {
              var result = await db.findAll('category');
              if (result != null) {
                cprint('category $result');
              } else {
                cprint('category result is null');
              }
            }),
        RaisedButton(
            child: Text('Read service'),
            onPressed: () async {
              var result = await db.findAll('service');
              if (result != null) {
                cprint('service $result');
              } else {
                cprint('service result is null');
              }
            }),
        RaisedButton(
            child: Text('Read user'),
            onPressed: () async {
              var result = await db.findAll('user');
              if (result != null) {
                cprint('user $result');
              } else {
                cprint('user result is null');
              }
            }),
        RaisedButton(
            child: Text('Read price'),
            onPressed: () async {
              var result = await db.findAll('price');
              if (result != null) {
                cprint('price $result');
              } else {
                cprint('price result is null');
              }
            }),
        RaisedButton(
            child: Text('Read test'),
            onPressed: () async {
              var result = await db.findAll('test');
              if (result != null) {
                cprint('test $result');
              } else {
                cprint('test result is null');
              }
            }),
        RaisedButton(
            child: Text('Read wash'),
            onPressed: () async {
              var result = await db.findAll('wash');
              if (result != null) {
                cprint('wash $result');
              } else {
                cprint('wash result is null');
              }
            }),
        RaisedButton(
            child: Text('Read washes'),
            onPressed: () async {
              var result = await db.findAll('wash');
              if (result != null) {
                result.forEach((wash) {
                  cprint(
                      'wash id:${wash['id']}, server_id: ${wash['server_id']}');
                });
              } else {
                cprint('wash result is null');
              }
            }),
        RaisedButton(
            child: Text('Read wash_user'),
            onPressed: () async {
              var result = await db.findAll('wash_user');
              if (result != null) {
                cprint('wash_user $result');
              } else {
                cprint('wash_user result is null');
              }
            }),
        RaisedButton(
            child: Text('Read washAllday'),
            onPressed: () async {
              var result = await db.findAllDay('2020-09-17');
              if (result != null) {
                cprint('washAllday $result');
              } else {
                cprint('washAllday result is null');
              }
            }),
        RaisedButton(
            child: Text('Read upd'),
            onPressed: () async {
              var result = await db.findAll('upd');
              if (result != null) {
                cprint('upd $result');
              } else {
                cprint('upd result is null');
              }
            }),
        RaisedButton(
            child: Text('Export test'),
            onPressed: () async {
              prov.export('test');
            }),
        /* RaisedButton(
            child: Text('Insert'),
            onPressed: () async {
              var result = await db.insertTest('yoba nah');
              if (result != null) {
                cprint('inserted $result');
              } else {
                cprint('insert result is null');
              }
            }), */
        /*  RaisedButton(
            child: Text('Update'),
            onPressed: () async {
              var result = await db.updateTest();
              if (result != null) {
                cprint('updated $result');
              } else {
                cprint('update result is null');
              }
            }), */
        /* RaisedButton(
            child: Text('Export'),
            onPressed: () {
              prov.export('test');
            }),
        RaisedButton(
            child: Text('Import'),
            onPressed: () {
              prov.import('test');
            }), */
        RaisedButton(
            child: Text('Truncate ctg'),
            onPressed: () async {
              await db.truncate('category');
            }),
        RaisedButton(
            child: Text('Truncate service'),
            onPressed: () async {
              await db.truncate('service');
            }),
        RaisedButton(
            child: Text('Truncate user'),
            onPressed: () async {
              await db.truncate('user');
            }),
        RaisedButton(
            child: Text('Truncate price'),
            onPressed: () async {
              await db.truncate('price');
            }),
        RaisedButton(
            child: Text('Truncate wash'),
            onPressed: () async {
              await db.truncate('wash');
            }),
        RaisedButton(
            child: Text('Truncate wash_user'),
            onPressed: () async {
              await db.truncate('wash_user');
            }),
        RaisedButton(
            child: Text('Truncate upd'),
            onPressed: () async {
              await db.truncate('upd');
            }),
        RaisedButton(
            child: Text('Truncate test'),
            onPressed: () async {
              await db.truncate('test');
            }),
        RaisedButton(
            child: Text('Delete wash'),
            onPressed: () async {
              db.deleteAll('wash', where: "id=1");
            }),
        RaisedButton(
            child: Text('drop db'),
            onPressed: () {
              db.dropDb();
            }),
        /* RaisedButton(
            child: Text('Check'),
            onPressed: () async {
              await db.checkLocal('test', 1);
            }) */
      ]),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
