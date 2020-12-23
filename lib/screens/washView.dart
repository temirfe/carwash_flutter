import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carwash/resources/provider.dart';
import 'package:carwash/resources/session.dart';
import 'package:carwash/resources/washModel.dart';
import 'package:carwash/resources/timerStream.dart';
import 'package:carwash/resources/endpoints.dart';
import 'package:carwash/resources/dbhelper.dart';
import 'washForm.dart';
import 'photoView.dart';
import 'addService.dart';

class WashView extends StatefulWidget {
  //final int id;
  final int id;
  WashView(this.id);

  @override
  _WashViewState createState() => _WashViewState();
}

class _WashViewState extends State<WashView> {
  RootProvider prov;
  Future<String> futureWashers;
  Future<List<Map<String, dynamic>>> futureUpd;

  @override
  void initState() {
    super.initState();
    prov = Provider.of<RootProvider>(context, listen: false);
    //futureWashers = _populateWashers(prov, widget.id);
    //futureUpd = _populateUpdates(widget.id);
    prov.subserv2Map = {'washers': []};
    prov.addServMap = {'washers': []};
    prov.activeWashers.forEach((am) {
      if (am['service_num'] == '2') {
        prov.subserv2Map['washers'].add(am['user_id']);
      }
      if (am['service_num'] == '3') {
        prov.addServMap['washers'].add(am['user_id']);
      }
    });
  }

  Widget build(BuildContext context) {
    int mid = widget.id;
    //String washDate;
    Text paidString;

    return Consumer<RootProvider>(builder: (context, prov, child) {
      Wash wash = prov.washesMap[mid];
      if (wash == null) {
        return Container();
      }
      //washDate = '${wash.time['start']}';
      List<Widget> actionBtns = [];
      //Widget startedAtWidget = SizedBox();

      if (wash.paid == null) {
        paidString =
            Text('Не оплачено', style: TextStyle(color: Colors.red[300]));
        actionBtns.add(paidBtn(mid));
      } else {
        paidString =
            Text('Оплачено', style: TextStyle(color: Colors.green[300]));
      }

      /* if (wash.finishedAt == null) {
        startedAtWidget = startStrBuild(wash.startedAt, false);
        actionBtns.add(SizedBox(
          width: 12.0,
        ));
        actionBtns.add(RaisedButton(
          onPressed: () {
            prov.requestFinish(mid);
            //prov.finishWash(wash);
          },
          color: Colors.green,
          child: Text('Завершить', style: TextStyle(color: Colors.white)),
        ));
      } else {
        washDate +=
            ' - ' + wash.time['end'] + ' (' + wash.time['duration'] + ')';
      } */

      List<Widget> viewList = [
        Row(children: [lbl('Гос номер'), text16(wash.plate)]),
        SizedBox(height: 10.0),
        pic(wash),
        marka(wash),
        SizedBox(height: 10.0),
        phone(wash.phone),
        Row(children: [lbl('Категория'), text16(wash.category)]),
        SizedBox(height: 10.0),
        Row(children: [
          lbl('Цена'),
          text16(wash.price.toString()),
          SizedBox(width: 12.0),
          paidString
        ]),
        SizedBox(height: 10.0),
        Row(children: [lbl('Услуга'), text16(wash.service)]),
        SizedBox(height: 10.0),
        services(wash.id, wash.services)
        /* Text('Персонал', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
        washersWidget(wash),
        SizedBox(height: 10.0),
        Text('Время', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
        Text(
          washDate,
          style: TextStyle(fontSize: 16.0),
        ),
        startedAtWidget, */
      ];

      if (wash.comment != null && wash.comment != '') {
        viewList.add(SizedBox(height: 12.0));
        viewList.add(Text('Коммент',
            style: TextStyle(fontSize: 12.0, color: Colors.grey)));

        viewList.add(Text(
          wash.comment,
          style: TextStyle(fontSize: 16.0),
        ));
      }

      viewList.add(updWidget(wash));

      viewList.add(SizedBox(height: 24.0));
      viewList.add(Row(
        children: actionBtns,
        mainAxisAlignment: MainAxisAlignment.end,
      ));
      viewList.add(SizedBox(height: 24.0));

      return Scaffold(
          appBar: AppBar(
            title: Text(Wash.getDate(wash.startedAt) + ' (id$mid)'),
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  //prov.formRequests();
                  Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (BuildContext context) => WashForm(widget.id)),
                  );
                },
              ),
              SizedBox(
                width: 10.0,
              )
            ],
          ),
          body: ListView(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            children: viewList,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.miniStartFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (BuildContext context) =>
                        AddService(widget.id, wash.categoryId)),
              );
            },
            backgroundColor: Colors.green,
            label: Text('Добавить услугу'),
            icon: Icon(Icons.add_circle),
          ));
    });
  }

  Widget services(int washId, List services) {
    List<Widget> list = [];
    bool hasntFinished =
        false; //subserv2 cannot be started before subserv1 is finished;
    services.forEach((servMap) {
      list.add(text16(servMap['title'], clr: Colors.blue));
      if (servMap['washers'] != '') {
        list.add(text16(servMap['washers']));
      }
      if (servMap['finished_at'] != null) {
        list.add(text16(
            Wash.timesStr(servMap['started_at'], servMap['finished_at'])));
      } else if (servMap['started_at'] != null) {
        hasntFinished = true;
        list.add(startStrBuild(servMap['started_at'], false));
        list.add(finishBtn(washId, servMap['id']));
      } else {
        if (hasntFinished) {
          list.add(Text('В ожидании'));
        } else {
          list = washersSel(list);
          list.add(startBtn(washId, servMap['id']));
        }
      }
      list.add(Divider());
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: list);
  }

  Widget startBtn(int washId, int wsId) {
    Widget btnChild = Text('Начать', style: TextStyle(color: Colors.white));
    return StreamBuilder<Map>(
      stream: prov.mapStrmCtrl.stream,
      builder: (context, AsyncSnapshot<Map> snapshot) {
        if (snapshot.hasData &&
            snapshot.data.containsKey('second') &&
            snapshot.data['second']) {
          btnChild = Container(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white)));
        }
        return RaisedButton(
          onPressed: () {
            prov.startSecond(washId, wsId);
          },
          color: Colors.green,
          child: btnChild,
        );
      },
    );
  }

  Widget paidBtn(int washId) {
    Widget btnChild = Text('Оплачено', style: TextStyle(color: Colors.white));
    return StreamBuilder<Map>(
      stream: prov.mapStrmCtrl.stream,
      builder: (context, AsyncSnapshot<Map> snapshot) {
        if (snapshot.hasData &&
            snapshot.data.containsKey('paid') &&
            snapshot.data['paid']) {
          btnChild = Container(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white)));
        }
        return RaisedButton(
          onPressed: () {
            prov.requestPaid(washId);
            //prov.washPaid(wash);
          },
          color: Colors.blue[300],
          child: btnChild,
        );
      },
    );
  }

  Widget finishBtn(int washId, int washServiceId) {
    Widget btnChild = Text('Завершить', style: TextStyle(color: Colors.white));
    return StreamBuilder<Map>(
      stream: prov.mapStrmCtrl.stream,
      builder: (context, AsyncSnapshot<Map> snapshot) {
        if (snapshot.hasData &&
            snapshot.data.containsKey('finish') &&
            snapshot.data['finish']) {
          btnChild = Container(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white)));
        }
        return RaisedButton(
          onPressed: () {
            prov.requestFinish(washId, washServiceId);
          },
          color: Colors.green,
          child: btnChild,
        );
      },
    );
  }

  List washersSel(List widList) {
    prov.washers.forEach((map) {
      bool washerBool = false;
      prov.subserv2Map['washers'].forEach((wid) {
        if (wid == map['id']) {
          washerBool = true;
        }
      });
      widList.add(
        ListTileTheme(
          contentPadding: EdgeInsets.all(0),
          child: CheckboxListTile(
            dense: true,
            title: new Text(map['username']),
            controlAffinity: ListTileControlAffinity.leading,
            value: washerBool,
            onChanged: (bool value) {
              prov.formWasher(map['id'], value);
            },
          ),
        ),
      );
    });
    return widList;
  }

  Widget washersWidget(Wash wash) {
    if (wash.washers != null) {
      return Text(
        wash.washers,
        style: TextStyle(fontSize: 16.0),
      );
    }
    return FutureBuilder<String>(
      future: futureWashers,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Text(
            snapshot.data,
            style: TextStyle(fontSize: 16.0),
          );
        }
        return Container();
      },
    );
  }

  Widget updWidgetDb(Wash wash, RootProvider prov) {
    // cprint('updWidget build');
    List<Widget> updRows = [];
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureUpd,
      builder: (BuildContext context,
          AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasData && snapshot.data.length > 0) {
          updRows.add(SizedBox(height: 12.0));
          updRows.add(Text('Изменения',
              style: TextStyle(fontSize: 12.0, color: Colors.grey)));
          snapshot.data.forEach((updRow) {
            List<Widget> updText = [];
            String oldVal, newVal;
            if (updRow['field'] == 'service_id') {
              oldVal = prov.servNameMap[int.parse(updRow['old_value'])];
              newVal = prov.servNameMap[int.parse(updRow['new_value'])];
            } else if (updRow['field'] == 'category_id') {
              oldVal = prov.ctgNameMap[int.parse(updRow['old_value'])];
              newVal = prov.ctgNameMap[int.parse(updRow['new_value'])];
            } else {
              oldVal =
                  updRow['old_value'] == null ? 'пусто' : updRow['old_value'];
              newVal =
                  updRow['new_value'] == null ? 'пусто' : updRow['new_value'];
            }
            DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                updRow['created_at'] * 1000);
            String upd;
            if (updRow['username'] != null) {
              upd = updRow['username'];
            } else {
              upd = 'admin';
            }
            upd += ' ' +
                /* DateFormat(DateFormat.ABBR_MONTH_DAY).format(dt) +
                ', ' + */
                DateFormat.Hm().format(dt) +
                ' ';
            updText.add(Text(upd));
            updText.add(Text(oldVal, style: TextStyle(color: Colors.red[300])));
            updText.add(Text('->'));
            updText
                .add(Text(newVal, style: TextStyle(color: Colors.green[700])));
            updRows.add(
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: updText),
              ),
            );
          });
          return Column(
            children: updRows,
            crossAxisAlignment: CrossAxisAlignment.start,
          );
        }
        return Container();
      },
    );
  }

  Widget updWidget(Wash wash) {
    List<Widget> updRows = [];
    if (wash.updates != null && wash.updates.isNotEmpty) {
      updRows.add(SizedBox(height: 12.0));
      updRows.add(Text('Изменения',
          style: TextStyle(fontSize: 12.0, color: Colors.grey)));
      wash.updates.forEach((updRow) {
        List<Widget> updText = [];
        String oldVal, newVal;
        if (updRow['field'] == 'service_id') {
          oldVal = prov.servNameMap[int.parse(updRow['old_value'])];
          newVal = prov.servNameMap[int.parse(updRow['new_value'])];
        } else if (updRow['field'] == 'category_id') {
          oldVal = prov.ctgNameMap[int.parse(updRow['old_value'])];
          newVal = prov.ctgNameMap[int.parse(updRow['new_value'])];
        } else {
          oldVal = updRow['old_value'] == null ? 'пусто' : updRow['old_value'];
          newVal = updRow['new_value'] == null ? 'пусто' : updRow['new_value'];
        }
        DateTime dt =
            DateTime.fromMillisecondsSinceEpoch(updRow['created_at'] * 1000);
        String upd;
        if (updRow['username'] != null) {
          upd = updRow['username'];
        } else {
          upd = 'admin';
        }
        upd += ' ' +
            /* DateFormat(DateFormat.ABBR_MONTH_DAY).format(dt) +
                ', ' + */
            DateFormat.Hm().format(dt) +
            ' ';
        updText.add(Text(upd));
        updText.add(Text(oldVal, style: TextStyle(color: Colors.red[300])));
        updText.add(Text('->'));
        updText.add(Text(newVal, style: TextStyle(color: Colors.green[700])));
        updRows.add(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: updText),
          ),
        );
      });
      return Column(
        children: updRows,
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    }
    return Container();
  }

  Widget pic(Wash wash) {
    List<Widget> photosList = [];
    if (wash != null && wash.photo != null) {
      var photos = wash.photo.split(';');
      photos.forEach((photoUrl) {
        photosList.add(
          GestureDetector(
            child: CachedNetworkImage(
                imageUrl: Endpoints.baseUrl + photoUrl, fit: BoxFit.fitHeight),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    maintainState: false,
                    builder: (context) => MyPhotoView(photoUrl),
                  ));
            },
          ),
        );
        photosList.add(SizedBox(width: 3.0));
      });
    }
    if (wash != null && wash.photoLocal != null) {
      var photos = wash.photoLocal.split(';');
      photos.forEach((photoPath) {
        photosList.add(
          GestureDetector(
            child: Image.file(File(photoPath), fit: BoxFit.fitHeight),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    maintainState: false,
                    builder: (context) => MyPhotoView(photoPath, local: true),
                  ));
            },
          ),
        );
        photosList.add(SizedBox(width: 3.0));
      });
    }

    if (photosList.isNotEmpty) {
      return Container(
        padding: EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: photosList,
        ),
        height: 100.0,
      );
    }
    return Container(height: 0.0, width: 0.0);
  }

  Widget phone(String phone) {
    if (phone != null && phone != '') {
      _launchCaller() async {
        var url = "tel:$phone";
        if (await canLaunch(url)) {
          await launch(url);
        }
      }

      return Column(
        children: [
          Row(children: [
            lbl('Телефон'),
            InkWell(
              child: text16(phone),
              onTap: _launchCaller,
            )
          ]),
          SizedBox(height: 10.0),
        ],
      );
    }
    return Container();
  }

  Widget marka(Wash wash) {
    if (wash.marka != null && wash.marka != '') {
      return Row(children: [lbl('Марка'), text16(wash.marka)]);
    }
    return Container(width: 0.0, height: 0.0);
  }
}

/* Future<String> _populateWashers(RootProvider prov, int washId) async {
  final DatabaseHelper db = DatabaseHelper();
  List<Map<String, dynamic>> washerUsers = await db.findWashUsers(washId);
  List<String> washerNamesList = [];
  washerUsers.forEach((washerUser) {
    String washer;
    if (prov.washersMap.containsKey(washerUser['user_id'])) {
      washer = prov.washersMap[washerUser['user_id']]['name'];
    } else {
      washer = 'user${washerUser['user_id']}';
    }
    washerNamesList.add(washer);
  });
  prov.washesMap[washId].setWasherIds = washerUsers;
  //cprint('washView washerUsers $washerUsers');
  //cprint('washView washerIds ${prov.washesMap[washId].washerIds}');
  return washerNamesList.join(', ');
}

Future<List<Map<String, dynamic>>> _populateUpdates(int washId) async {
  final DatabaseHelper db = DatabaseHelper();
  return await db.findUpd(washId);
} */
