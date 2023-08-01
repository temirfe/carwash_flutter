import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carwash/resources/provider.dart';
import 'package:carwash/resources/progressDialog.dart';

class Washers extends StatelessWidget {
  final ProgressDialog pdial = ProgressDialog();
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(title: Text('Персонал')), body: body(context));
  }

  Widget body(BuildContext context) {
    return Consumer<RootProvider>(builder: (context, prov, child) {
      if (prov.washers == null) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
      List<Widget> widList = [];
      for (int i = 0; i < prov.washers!.length; i++) {
//cprint('washers ${prov.washers}');
        bool washerBool = true;
        /* if (prov.washers[i]['in_service'] == 0) {
          washerBool = false;
        } */
        if (prov.washers![i]['in_service'] == '0') {
          washerBool = false;
        }
        widList.add(
          ListTileTheme(
            contentPadding: EdgeInsets.all(0),
            child: CheckboxListTile(
              dense: true,
              title: new Text(prov.washers![i]['username']),
              controlAffinity: ListTileControlAffinity.leading,
              value: washerBool,
              onChanged: (bool? isTicked) async {
                pdial.show(context);
                await prov.changeWasherStatus(
                    prov.washers![i]['id'], isTicked!);
                pdial.hide();
              },
            ),
          ),
        );
      }

      return Scrollbar(
          child: ListView(
        children: widList,
      ));
    });
  }
}
