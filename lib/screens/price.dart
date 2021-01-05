import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carwash/resources/provider.dart';
//import 'package:carwash/resources/session.dart';

class Price extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(title: Text('Прайслист')), body: body(context));
  }

  Widget body(BuildContext context) {
    return Consumer<RootProvider>(builder: (context, prov, child) {
      if (prov.prices == null) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      List<DataRow> priceRows = [];
      List<DataRow> durRows = [];
      List<String> serviceList = [''];
      Map<String, Map> ctgPriceMap = {};
      Map<String, Map> ctgDurMap = {};
      prov.prices.forEach((prMap) {
        if (!serviceList.contains(prMap['service'])) {
          serviceList.add(prMap['service']);
        }
        if (ctgPriceMap.containsKey(prMap['category'])) {
          ctgPriceMap[prMap['category']][prMap['service']] = prMap['price'];
        } else {
          ctgPriceMap[prMap['category']] = {prMap['service']: prMap['price']};
        }

        if (ctgDurMap.containsKey(prMap['category'])) {
          ctgDurMap[prMap['category']][prMap['service']] = prMap['duration'];
        } else {
          ctgDurMap[prMap['category']] = {prMap['service']: prMap['duration']};
        }
      });
      List<DataColumn> dtCols = [];
      serviceList.forEach((serv) {
        dtCols.add(DataColumn(
          label: Text(serv),
          numeric: false,
        ));
      });
      serviceList.remove('');
      ctgPriceMap.forEach((ctgName, servPriceMap) {
        if (ctgName == null) {
          ctgName = 'Для всех';
        }
        List<DataCell> priceCells = [
          DataCell(
            Text(ctgName),
          )
        ];
        serviceList.forEach((serv) {
          String txt = servPriceMap[serv].toString();
          if (txt == 'null') {
            txt = '';
          }
          priceCells.add(DataCell(
            Text(txt),
          ));
        });
        priceRows.add(DataRow(cells: priceCells));
      });

      //duration
      ctgDurMap.forEach((ctgName, servDurMap) {
        if (ctgName == null) {
          ctgName = 'Для всех';
        }
        List<DataCell> durCells = [
          DataCell(
            Text(ctgName),
          )
        ];

        serviceList.forEach((serv) {
          String txt = servDurMap[serv].toString();
          if (txt == 'null') {
            txt = '';
          }
          durCells.add(DataCell(
            Text(txt),
          ));
        });
        durRows.add(DataRow(cells: durCells));
      });

      /*  prov.prices.forEach((prMap) {
        pRows.add(DataRow(cells: [
          DataCell(
            Text(prMap['category']),
          ),
          DataCell(
            Text(prMap['service']),
          ),
          DataCell(
            Text('${prMap['price']}'),
          ),
          DataCell(
            Text('${prMap['duration']}'),
          ),
        ]));
      }); */

      /* List<DataColumn> dtCols = [
        DataColumn(
          label: Text("Категория"),
          numeric: false,
        ),
        DataColumn(
          label: Text("Услуга"),
          numeric: false,
        ),
        DataColumn(
          label: Text("Цена"),
          numeric: false,
        ),
        DataColumn(
          label: Text("Продолж"),
          numeric: false,
        ),
      ]; */

      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DataTable(
                columnSpacing: 20.0,
                columns: dtCols,
                rows: priceRows,
              ),
              SizedBox(
                height: 30.0,
              ),
              Container(
                child: Text(
                  'Продолжительность',
                  style: TextStyle(color: Colors.blue),
                ),
                margin: EdgeInsets.only(left: 20.0),
              ),
              DataTable(
                columnSpacing: 20.0,
                columns: dtCols,
                rows: durRows,
              )
            ],
          ),
        ),
      );
    });
  }
}
