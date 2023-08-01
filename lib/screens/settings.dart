import 'package:flutter/material.dart';
import 'package:carwash/resources/provider.dart';
import 'package:carwash/resources/session.dart';

Widget settings(BuildContext context, RootProvider prov) {
  if (prov.errorMessage != '') {
    return Text(prov.errorMessage);
  }
  return ListView(
    children: [
      ListTile(
          title: Text('Персонал'),
          trailing: Icon(Icons.arrow_right, color: Colors.grey),
          onTap: () {
            prov.requestWashers();
            Navigator.pushNamed(context, 'washers');
          }),
      Divider(),
      ListTile(
          title: Text('Прайслист'),
          trailing: Icon(Icons.arrow_right, color: Colors.grey),
          onTap: () {
            prov.requestPrices();
            Navigator.pushNamed(context, 'price');
          }),
      /* Divider(),
      ListTile(
          title: Text('Test'),
          trailing: Icon(Icons.arrow_right, color: Colors.grey),
          onTap: () {
            prov.requestPrices();
            Navigator.pushNamed(context, 'test');
          }), */
      Divider(),
      SizedBox(
        height: 24.0,
      ),
      Row(
        children: [
          SizedBox(width: 12.0),
          Text(session.getString('username') ?? '')
        ],
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        child: prov.versionInfo(),
      ),
    ],
  );
}
