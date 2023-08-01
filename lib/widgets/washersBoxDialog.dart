import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carwash/resources/provider.dart';

final ScrollController _ctgScrlCntr = ScrollController();

washersBoxDialog(BuildContext context, Map box) {
  showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, Animation animation,
          Animation secondaryAnimation) {
        return Center(
          child: Material(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.0)),
            child: Container(
              width: MediaQuery.of(context).size.width - 20,
              height: MediaQuery.of(context).size.height - 80,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(3),
                          topLeft: Radius.circular(3)),
                    ),
                    width: MediaQuery.of(context).size.width - 20,
                    child:
                        Consumer<RootProvider>(builder: (context, prov, child) {
                      return Padding(
                          child: Text(
                            box['title'],
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          padding: EdgeInsets.all(16.0));
                    }),
                  ),
                  Divider(color: Colors.grey[300], height: 0.0),
                  Expanded(
                    child: Consumer<RootProvider>(
                      builder: (context, prov, child) {
                        List<Widget> widList = [];
                        prov.washers?.forEach((map) {
                          if (map['in_service'] == '1') {
                            bool washerBool = false;
                            if (prov.washFormMap.containsKey('washers') &&
                                prov.washFormMap['washers']
                                    .containsKey(box['id']) &&
                                prov.washFormMap['washers'][box['id']]
                                    .contains(map['id'])) {
                              washerBool = true;
                            }
                            widList.add(
                              ListTileTheme(
                                contentPadding: EdgeInsets.all(0),
                                child: CheckboxListTile(
                                  dense: true,
                                  title: new Text(map['username']),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  value: washerBool,
                                  onChanged: (bool? value) {
                                    prov.formWasher(
                                        box['id'], map['id'], value!);
                                  },
                                ),
                              ),
                            );
                          }
                        });

                        return Scrollbar(
                            child: ListView(
                          controller: _ctgScrlCntr,
                          padding: EdgeInsets.symmetric(
                              vertical: 0.0, horizontal: 5.0),
                          children: widList,
                        ));
                      },
                    ),
                  ),
                  Divider(color: Colors.grey[300], height: 0.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(3),
                          bottomLeft: Radius.circular(3)),
                    ),
                    width: MediaQuery.of(context).size.width - 20,
                    child: Align(
                      child: TextButton(
                        //////////////
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("Закрыть"),
                      ),
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
}
