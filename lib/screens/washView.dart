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
    futureWashers = _populateWashers(prov, widget.id);
    futureUpd = _populateUpdates(widget.id);
  }

  Widget build(BuildContext context) {
    int mid = widget.id;
    String washDate;

    return Consumer<RootProvider>(builder: (context, prov, child) {
      Wash wash = prov.washesMap[mid];
      if (wash == null) {
        return Container();
      }
      Text paidString;
      washDate = '${wash.time['start']}';
      List<Widget> actionBtns = [];
      Widget startedAtWidget = SizedBox();

      if (wash.paid == null) {
        paidString =
            Text('Не оплачено', style: TextStyle(color: Colors.red[300]));
        actionBtns.add(RaisedButton(
          onPressed: () {
            //prov.requestPaid(mid);
            prov.washPaid(wash);
          },
          color: Colors.blue[300],
          child: Text('Оплачено', style: TextStyle(color: Colors.white)),
        ));
      } else {
        paidString =
            Text('Оплачено', style: TextStyle(color: Colors.green[300]));
      }
      if (wash.finishedAt == null) {
        startedAtWidget = startStrBuild(wash.startedAt, false);
        actionBtns.add(SizedBox(
          width: 12.0,
        ));
        actionBtns.add(RaisedButton(
          onPressed: () {
            //prov.requestFinish(mid);
            prov.finishWash(wash);
          },
          color: Colors.green,
          child: Text('Завершить', style: TextStyle(color: Colors.white)),
        ));
      } else {
        washDate +=
            ' - ' + wash.time['end'] + ' (' + wash.time['duration'] + ')';
      }

      List<Widget> viewList = [
        Text('Гос номер', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
        Text(
          wash.plate,
          style: TextStyle(fontSize: 16.0),
        ),
        SizedBox(height: 12.0),
        pic(wash),
        marka(wash),
        Text('Категория', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
        Text(
          wash.category,
          style: TextStyle(fontSize: 16.0),
        ),
        SizedBox(height: 12.0),
        Text('Услуга', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
        Text(
          wash.service,
          style: TextStyle(fontSize: 16.0),
        ),
        SizedBox(height: 12.0),
        Text('Персонал', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
        washersWidget(wash),
        SizedBox(height: 12.0),
        Text('Время', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
        Text(
          washDate,
          style: TextStyle(fontSize: 16.0),
        ),
        startedAtWidget,
        SizedBox(height: 12.0),
        Text('Цена', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
        Row(
          children: [
            Text(
              '${wash.price}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(width: 12.0),
            paidString
          ],
        ),
      ];

      if (wash.phone != null && wash.phone != '') {
        _launchCaller() async {
          var url = "tel:${wash.phone}";
          if (await canLaunch(url)) {
            await launch(url);
          }
        }

        viewList.add(SizedBox(height: 12.0));
        viewList.add(Text('Телефон',
            style: TextStyle(fontSize: 12.0, color: Colors.grey)));

        viewList.add(
          InkWell(
            child: Text(wash.phone, style: TextStyle(fontSize: 16.0)),
            onTap: _launchCaller,
          ),
        );
      }

      if (wash.comment != null && wash.comment != '') {
        viewList.add(SizedBox(height: 12.0));
        viewList.add(Text('Коммент',
            style: TextStyle(fontSize: 12.0, color: Colors.grey)));

        viewList.add(Text(
          wash.comment,
          style: TextStyle(fontSize: 16.0),
        ));
      }

      viewList.add(updWidget(wash, prov));

      viewList.add(SizedBox(height: 24.0));
      viewList.add(Row(
        children: actionBtns,
        mainAxisAlignment: MainAxisAlignment.end,
      ));

      return Scaffold(
        appBar: AppBar(
          title: Text('Мойка ID $mid'),
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
      );
    });
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

  Widget updWidget(Wash wash, RootProvider prov) {
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

  Widget updWidgetServer(Wash wash) {
    List<Widget> updRows = [];
    if (wash.updates != null && wash.updates.isNotEmpty) {
      updRows.add(SizedBox(height: 12.0));
      updRows.add(Text('Изменения',
          style: TextStyle(fontSize: 12.0, color: Colors.grey)));
      wash.updates.forEach((upd) {
        updRows.add(Text(
          upd,
          style: TextStyle(fontSize: 16.0),
        ));
      });
      return Column(children: updRows);
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

  Widget marka(Wash wash) {
    if (wash.marka != null && wash.marka != '') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Марка', style: TextStyle(fontSize: 12.0, color: Colors.grey)),
          Text(
            wash.marka,
            style: TextStyle(fontSize: 16.0),
          ),
          SizedBox(height: 12.0)
        ],
      );
    }
    return Container(width: 0.0, height: 0.0);
  }
}

Future<String> _populateWashers(RootProvider prov, int washId) async {
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
}
