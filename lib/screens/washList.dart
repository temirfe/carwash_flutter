import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carwash/resources/provider.dart';
import 'package:carwash/resources/timerStream.dart';
import 'package:carwash/resources/session.dart';

Widget washList(BuildContext context, RootProvider prov) {
  //print('washList build');
  List<Widget> localist = [];
  int iReverse = prov.xTotalCount;
  if (iReverse != null && iReverse < prov.washesMap.length) {
    iReverse = prov.xTotalCount;
  }
  prov.washesMap.forEach((k, v) {
    Color cardColor = Colors.white;
    //print('washList wash $k');
    /*  Icon progressStatus = Icon(Icons.done, color: Colors.green);
    Icon paymentStatus = Icon(Icons.attach_money, color: Colors.green);
    if (v.finishedAt == null) {
      progressStatus = Icon(Icons.hourglass_empty, color: Colors.orange);
    }
    if (v.paid == null) {
      paymentStatus = Icon(Icons.money_off, color: Colors.orange);
    } */

//#region duration
    Widget durationWidget;
    List<Widget> durChildrn = [];
    v.services.forEach((ws) {
      Color durClr = Colors.grey;
      if (ws['finished_at'] == null) {
        durClr = Colors.orange;
      }

      if (ws['duration'] != null) {
        if (ws['duration_status'] == 1) {
          durClr = Colors.green;
        } else if (ws['duration_status'] == 2) {
          durClr = Colors.red[200];
        }
        int durationMin = (ws['duration'] / 60).round();
        durationWidget = Text('$durationMin', style: TextStyle(color: durClr));
      } else if (ws['started_at'] == null) {
        durationWidget = Text('0', style: TextStyle(color: durClr));
        cardColor = Colors.orange[50];
      } else {
        durationWidget = startStrBuild(ws['started_at'], false, color: durClr);
        cardColor = Colors.orange[50];
      }
      durChildrn.add(Icon(Icons.timer, size: 16.0, color: durClr));
      durChildrn.add(SizedBox(width: 3.0));
      durChildrn.add(Container(width: 52.0, child: durationWidget));
      durChildrn.add(SizedBox(width: 5.0));
    });
    Row durationRow = Row(
      children: durChildrn,
    );
    /* Color durClr = Colors.grey;
    if (v.finishedAt == null) {
      durClr = Colors.orange;
    }

    if (v.duration != null) {
      if (v.durationStatus == 1) {
        durClr = Colors.green;
      } else if (v.durationStatus == 2) {
        durClr = Colors.red[200];
      }
      int durationMin = (v.duration / 60).round();
      durationWidget = Text('$durationMin', style: TextStyle(color: durClr));
    } else {
      durationWidget = startStrBuild(v.startedAt, false, color: durClr);
    }
    Row durationRow = Row(
      children: [
        Icon(Icons.timer, size: 16.0, color: durClr),
        SizedBox(width: 3.0),
        Container(width: 52.0, child: durationWidget)
      ],
    ); */
//#endregion

    Color moneyClr = Colors.green;
    if (v.paid == null) {
      moneyClr = Colors.orange;
      cardColor = Colors.orange[50];
    }

    List<Widget> iconInfoRowList = [];
    if (v.phone != null && v.phone != '') {
      iconInfoRowList.add(Icon(Icons.phone, size: 14.0, color: Colors.grey));
      iconInfoRowList.add(SizedBox(
        width: 4.0,
      ));
    }
    if (v.comment != null && v.comment != '') {
      iconInfoRowList.add(Icon(Icons.comment, size: 14.0, color: Colors.grey));
      iconInfoRowList.add(SizedBox(
        width: 4.0,
      ));
    }
    if (v.photo != null || v.photoLocal != null) {
      iconInfoRowList.add(Icon(Icons.image, size: 14.0, color: Colors.grey));
      int photoCount = 0;
      if (v.photo != null) {
        photoCount = v.photo.split(';').length;
      } else {
        photoCount = v.photoLocal.split(';').length;
      }
      if (photoCount > 1) {
        iconInfoRowList.add(Text('$photoCount',
            style: TextStyle(fontSize: 12.0, color: Colors.grey)));
      }
      iconInfoRowList.add(SizedBox(
        width: 4.0,
      ));
    }
    if (v.updatedAt != null && v.updatedAt != v.startedAt) {
      iconInfoRowList.add(SizedBox());
      iconInfoRowList.add(Icon(Icons.create, size: 14.0, color: Colors.grey));
    }
    Widget marka() {
      if (v.marka != null && v.marka != '') {
        return Container(
          width: 148.0,
          child: Text(v.marka,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black54)),
        );
      }
      return Container(width: 150.0, height: 0.0);
    }

    Widget price() {
      return Text('${v.price} c', style: TextStyle(color: moneyClr));
      /* return Row(
        children: [
          Icon(Icons.attach_money, size: 16.0, color: moneyClr),
          SizedBox(width: 3.0),
          Text('${v.price} c', style: TextStyle(color: moneyClr))
        ],
      ); */
    }

    Widget plate() {
      RegExp exp = new RegExp(r"(\d{2})(KG)(\d{3})(\w{3})",
          caseSensitive: false, multiLine: false);
      Widget plt;
      if (exp.hasMatch(v.plate)) {
        var matches = exp.firstMatch(v.plate);
        plt = Row(children: [
          Column(
            children: [
              Text(matches.group(1), style: TextStyle(fontSize: 7.0)),
              Text(matches.group(2), style: TextStyle(fontSize: 7.0)),
            ],
          ),
          SizedBox(width: 2.0),
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.ideographic,
              children: [
                Text(matches.group(3), style: TextStyle(fontSize: 18.0)),
                SizedBox(width: 2.0),
                Text(matches.group(4), style: TextStyle(fontSize: 14.0)),
              ])
        ]);
      } else {
        plt = Text(v.plate, style: TextStyle(fontSize: 18.0));
      }

      return InkWell(
          child: Padding(
            padding: EdgeInsets.only(bottom: 6.0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 3.0, horizontal: 6.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.all(Radius.circular(3.0)),
              ),
              child: plt,
            ),
          ),
          onTap: () {
            prov.washesMap = {};
            prov.plateQueryRequest(v.plate);
          });
    }

    Widget cardNumber() {
      return Text('$iReverse',
          style: TextStyle(fontSize: 26.0, color: Colors.grey[400]));
    }

    Widget ctg() {
      return Container(
          width: 170.0,
          margin: EdgeInsets.only(right: 10.0),
          child: Text('${v.category}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black54)));
    }

    Widget service() {
      return Expanded(
        child: Container(
          child: Text('${v.service}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    List<Widget> titleChildren = [
      Row(
          children: [cardNumber(), plate(), marka()],
          mainAxisAlignment: MainAxisAlignment.spaceBetween),
      Row(
        children: [ctg(), service()],
      ),
      Row(children: [
        Text(v.startTime, style: TextStyle(color: Colors.blue)),
        price(),
        Container(
            width: 75.0,
            child: Row(
              children: iconInfoRowList,
              mainAxisAlignment: MainAxisAlignment.end,
            )),
      ], mainAxisAlignment: MainAxisAlignment.spaceBetween),
      SizedBox(height: 2.0),
      durationRow,
    ];

    localist.add(
      Card(
        color: cardColor,
        child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: titleChildren,
            ),
            //subtitle: Row(children: tileChildren),
            /* trailing: Container(
                width: 52.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [progressStatus, paymentStatus],
                )), */
            onTap: () {
              Navigator.pushNamed(context, '/$k');
              /*  Navigator.push(
            context,
            new MaterialPageRoute(
                builder: (BuildContext context) => WashView(k)),
          ); */
            }),
      ),
    );
    iReverse--;
  });

  double scrollMax;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final after = notification.metrics.extentAfter;
      final max = notification.metrics.maxScrollExtent;
      if (after < 200) {
        if (scrollMax != max) {
          if (prov.xPageCount != null && prov.xCurrentPage < prov.xPageCount) {
            prov.requestList();
            //prov.requestListFromDb(cont: true);
          }
          scrollMax = max;
        }
      }
    }
    return false;
  }

  if (prov.isLoading) {
    return Center(child: CircularProgressIndicator());
  }
  if (prov.washesMap.isEmpty) {
    return Center(
      child: Text('Нет данных'),
    );
  }

  //When ListView reaches end the NotificationListener notifies about it
  //and new portion of data will be loaded and added at the end of ListView
  return NotificationListener(
    onNotification: _onScrollNotification,
    child: RefreshIndicator(
      onRefresh: () async {
        prov.xCurrentPage = 0;
        prov.washesMap =
            {}; //clear washesMap, otherwise the new loaded data gets appended
        prov.requestList();
        //prov.requestListFromDb();
      },
      child: Scrollbar(
        child: ListView(
          //FAB closes last item so padding is added
          padding:
              const EdgeInsets.only(bottom: kFloatingActionButtonMargin + 48),
          children: localist,
        ),
      ),
    ),
  );
}
