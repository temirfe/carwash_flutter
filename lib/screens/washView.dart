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
//import 'package:carwash/resources/dbhelper.dart';
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
  late RootProvider prov;

  @override
  void initState() {
    super.initState();
    prov = Provider.of<RootProvider>(context, listen: false);
  }

  Widget build(BuildContext context) {
    int mid = widget.id;
    //String washDate;
    Text paidString;

    return Consumer<RootProvider>(builder: (context, prov, child) {
      Wash? wash = prov.washesMap[mid];
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

      List<Widget> viewList = [
        Row(children: [lbl('Гос номер'), text16(wash.plate)]),
        SizedBox(height: 10.0),
        pic(wash),
        marka(wash),
        SizedBox(height: 10.0),
        phone(wash.phone),
        Row(children: [lbl('Категория'), text16(wash.category)]),
        SizedBox(height: 10.0),
        priceRow(wash, paidString),
        SizedBox(height: 10.0),
        Row(children: [lbl('Услуга'), text16(wash.service)]),
        SizedBox(height: 10.0),
        extraServices(wash.services),
        boxes(wash.id, wash.boxes)
      ];

      if (wash.comment != '') {
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
      );
    });
  }

  Widget priceRow(Wash wash, Text paidString) {
    List<Widget> lst = [
      Row(children: [
        lbl('Цена'),
        text16(wash.price.toString()),
        SizedBox(width: 12.0),
        paidString
      ])
    ];
    if (wash.discount.isNotEmpty) {
      String discStr = wash.discount['discount'].toString();
      if (wash.discount['is_pct'] == 1) {
        discStr += '%';
      } else {
        discStr += ' сом';
      }
      lst.add(Row(children: [lbl('Скидка'), text16(discStr)]));
      lst.add(Row(children: [
        lbl('Конечная цена'),
        text16(wash.finalPrice.toString())
      ]));
    }
    return Column(children: lst);
  }

  Widget extraServices(List services) {
    if (services.isNotEmpty) {
      List<String> titles = [];
      services.forEach((sm) {
        titles.add(sm['title']);
      });
      return Column(
        children: [
          Row(children: [lbl('Доп услуги'), text16(titles.join(', '))]),
          SizedBox(height: 10.0),
        ],
      );
    }
    return Container();
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
        /* list.add(text16(
            Wash.timesStr(servMap['started_at'], servMap['finished_at']))); */
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

  Widget boxes(int washId, List boxes) {
    List<Widget> list = [];
    bool hasntFinished =
        false; //box2 cannot be started before box1 is finished;
    boxes.forEach((servMap) {
      list.add(text16(servMap['title'], clr: Colors.blue));
      if (servMap['finished_at'] != null) {
        /* list.add(text16(
            Wash.timesStr(servMap['started_at'], servMap['finished_at']))); */
        list.add(Wash.timesWid(servMap['started_at'], servMap['finished_at'],
            servMap['duration_status']));
      } else if (servMap['started_at'] != null) {
        hasntFinished = true;
        list.add(startStrBuild(servMap['started_at'], false));
        list.add(finishBtn(washId, servMap['id']));
      } else {
        if (hasntFinished) {
          list.add(Text('В ожидании'));
        } else {
          //list = washersSel(list);
          list.add(startBtn(washId, servMap['id']));
        }
      }
      if (servMap['washers'] != []) {
        servMap['washers'].forEach((wm) {
          List<Widget> wlist = [
            Container(width: 100.0, child: text16(wm['name']))
          ];
          if (wm['wage'] != 0 && wm['wage'] != wm['wage_final']) {
            wlist.add(SizedBox(width: 5.0));
            wlist.add(Text(wm['wage'].toString(),
                style: TextStyle(
                    color: Colors.red[300],
                    decoration: TextDecoration.lineThrough)));
          }
          if (wm['wage_final'] != null) {
            wlist.add(SizedBox(width: 5.0));
            wlist.add(text16(wm['wage_final'].toString()));
          }

          list.add(Row(children: wlist));
        });
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
            snapshot.data!.containsKey('second') &&
            snapshot.data!['second']) {
          btnChild = Container(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white)));
        }
        return ElevatedButton(
          onPressed: () {
            prov.startSecond(washId, wsId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
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
            snapshot.data!.containsKey('paid') &&
            snapshot.data!['paid']) {
          btnChild = Container(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white)));
        }
        return ElevatedButton(
          onPressed: () {
            prov.requestPaid(washId);
            //prov.washPaid(wash);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[300],
          ),
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
            snapshot.data!.containsKey('finish') &&
            snapshot.data!['finish']) {
          btnChild = Container(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white)));
        }
        return ElevatedButton(
          onPressed: () {
            prov.requestFinish(washId, washServiceId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: btnChild,
        );
      },
    );
  }

  List<Widget> washersSel(List<Widget> widList) {
    prov.washers?.forEach((map) {
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
            onChanged: (bool? value) {
              //prov.formWasher(map['id'], value);
            },
          ),
        ),
      );
    });
    return widList;
  }

  Widget updWidget(Wash wash) {
    List<Widget> updRows = [];
    if (wash.updates.isNotEmpty) {
      updRows.add(SizedBox(height: 12.0));
      updRows.add(Text('Изменения',
          style: TextStyle(fontSize: 12.0, color: Colors.grey)));
      wash.updates.forEach((updRow) {
        List<Widget> updText = [];
        String oldVal = '', newVal = '';
        if (updRow['field'] == 'service_id') {
          oldVal = prov.servNameMap[int.parse(updRow['old_value'])]!;
          newVal = prov.servNameMap[int.parse(updRow['new_value'])]!;
        } else if (updRow['field'] == 'category_id') {
          oldVal = prov.ctgNameMap[int.parse(updRow['old_value'])]!;
          newVal = prov.ctgNameMap[int.parse(updRow['new_value'])]!;
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
    var photos2 = wash.photoLocal.split(';');
    photos2.forEach((photoPath) {
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
    if (phone != '') {
      _launchCaller() async {
        var url = "tel:$phone";
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
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
    if (wash.marka != '') {
      return Row(children: [lbl('Марка'), text16(wash.marka)]);
    }
    return Container(width: 0.0, height: 0.0);
  }
}
