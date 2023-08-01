import 'package:flutter/material.dart';
import 'package:carwash/resources/provider.dart';
//import 'package:carwash/resources/session.dart';

Widget analytics(BuildContext context, RootProvider prov) {
  if (prov.errorMessage != '') {
    return Text(prov.errorMessage);
  }
  if (prov.analyticsList == null || prov.analyticsList!.isEmpty) {
    return Text('Нет данных');
  } else {
    int washCount = 0;
    int totalPrice = 0;
    int discountPrice = 0;
    int totalPricePaid = 0;
    int discount = 0;
    Map<int, Map<String, dynamic>> washers = {};
    prov.analyticsList?.forEach((map) {
      washCount++;
      if (map['price'] != null) {
        totalPrice += int.parse(map['price'].toString());
      }
      if (map['final_price'] != null) {
        discountPrice += int.parse(map['final_price'].toString());
      }
      discount = totalPrice - discountPrice;
      if (map['paid'] == 1) {
        totalPricePaid += int.parse(map['final_price'].toString());
      }
      map['boxes'].forEach((bmap) {
        bmap['washers'].forEach((wmap) {
          int wage = wmap['wage_final'] == null ? 0 : wmap['wage_final'];
          if (washers.containsKey(wmap['id'])) {
            washers[wmap['id']]!['wage'] += wage;
          } else {
            washers[wmap['id']] = {'name': wmap['name'], 'wage': wage};
          }
        });
      });
    });
    List<Widget> rows = [
      Row(children: [
        Container(width: 100.0, child: Text('Количество:')),
        Text('$washCount', style: TextStyle(fontSize: 16.0))
      ]),
      Row(children: [
        Container(width: 100.0, child: Text('Сумма:')),
        Text('$totalPrice сом', style: TextStyle(fontSize: 16.0))
      ]),
      Row(children: [
        Container(width: 100.0, child: Text('Скидка:')),
        Text('$discount сом', style: TextStyle(fontSize: 16.0))
      ]),
      Row(children: [
        Container(width: 100.0, child: Text('Сумма после скидки:')),
        Text('$discountPrice сом', style: TextStyle(fontSize: 16.0))
      ]),
      Row(children: [
        Container(width: 100.0, child: Text('Оплачено:')),
        Text('$totalPricePaid сом', style: TextStyle(fontSize: 16.0))
      ]),
      SizedBox(
        height: 12.0,
      ),
      Text('Оклад'),
      SizedBox(
        height: 6.0,
      ),
    ];
    washers.forEach((id, wm) {
      rows.add(Row(children: [
        Container(width: 100.0, child: Text('${wm['name']}:')),
        Text('${wm['wage']} сом', style: TextStyle(fontSize: 16.0))
      ]));
    });
    return Padding(
        padding: EdgeInsets.all(12.0), child: Column(children: rows));
  }
}
