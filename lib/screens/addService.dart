import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carwash/resources/provider.dart';

class AddService extends StatefulWidget {
  final int washId;
  final int categoryId;
  AddService(this.washId, this.categoryId);
  @override
  _AddServiceState createState() => _AddServiceState();
}

class _AddServiceState extends State<AddService> {
  RootProvider prov;

  @override
  void initState() {
    super.initState();
    prov = Provider.of<RootProvider>(context, listen: false);
    prov.addServMap['wash_id'] = widget.washId;
    prov.addServMap['category_id'] = widget.categoryId;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить услугу'),
      ),
      body: Consumer<RootProvider>(builder: (context, prov, child) {
        List<Widget> widList = [
          Text('Услуга', style: TextStyle(color: Colors.blue)),
          serviceRadioList(context, prov)
        ];

        widList.add(Container(
          child: Text('Персонал', style: TextStyle(color: Colors.blue)),
          padding: EdgeInsets.only(top: 16.0),
        ));
        widList = washersSel(widList);
        widList.add(Container(
          child: Text('Скидка', style: TextStyle(color: Colors.blue)),
          padding: EdgeInsets.only(top: 16.0),
        ));
        widList.add(discountRadioList(context, prov));
        widList.add(SizedBox(height: 12.0));
        widList.add(submitBtn());
        //widList.add();
        return ListView(
          children: widList,
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        );
      }),
    );
  }

  Widget serviceRadioList(BuildContext context, RootProvider prov) {
    String inival;
    if (prov.addServMap.containsKey('service_id')) {
      inival = prov.addServMap['service_id'];
    }
    List<ListTileTheme> ctgItems = [];
    prov.services.forEach((map) {
      if (map['can_be_secondary'] == '1' || map['only_secondary'] == '1') {
        ctgItems.add(
          ListTileTheme(
            contentPadding: EdgeInsets.all(0),
            child: RadioListTile<String>(
              dense: true,
              title: Text(map['title']),
              value: map['id'],
              groupValue: inival,
              onChanged: (String value) {
                prov.addServSelect('service_id', value);
              },
            ),
          ),
        );
      }
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ctgItems,
    );
  }

  Widget discountRadioList(BuildContext context, RootProvider prov) {
    String inival;
    if (prov.addServMap.containsKey('discount_id')) {
      inival = prov.addServMap['discount_id'];
    }
    List<ListTileTheme> ctgItems = [];
    prov.discounts.forEach((map) {
      String title = map['discount'];
      if (map['is_pct'] == '1') {
        title += '%';
      } else {
        title += ' сом';
      }
      ctgItems.add(
        ListTileTheme(
          contentPadding: EdgeInsets.all(0),
          child: RadioListTile<String>(
            dense: true,
            title: Text(title),
            value: map['id'],
            groupValue: inival,
            onChanged: (String value) {
              prov.addServSelect('discount_id', value);
            },
          ),
        ),
      );
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ctgItems,
    );
  }

  List washersSel(List widList) {
    prov.washers.forEach((map) {
      bool washerBool = false;
      prov.addServMap['washers'].forEach((wid) {
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
              //prov.formWasher(map['id'], value);
            },
          ),
        ),
      );
    });
    return widList;
  }

  Widget submitBtn() {
    var onPres;
    if (prov.addServMap.containsKey('service_id') &&
        prov.addServMap['washers'].length > 0) {
      onPres = () {
        Future<bool> subm = prov.requestAddService(widget.washId);
        subm.then((resp) {
          if (resp) {
            new Future.delayed(new Duration(milliseconds: 100), () {
              Navigator.of(context).pop();
            });
          }
        });
      };
    }
    Widget btnChild = Text('Добавить', style: TextStyle(color: Colors.white));
    return StreamBuilder<Map>(
      stream: prov.mapStrmCtrl.stream,
      builder: (context, AsyncSnapshot<Map> snapshot) {
        if (snapshot.hasData &&
            snapshot.data.containsKey('addService') &&
            snapshot.data['addService']) {
          btnChild = Container(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white)));
        }
        return ElevatedButton(
          child: btnChild,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 6.0),
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey,
          ),
          onPressed: onPres,
        );
      },
    );
  }
}
