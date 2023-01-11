import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carwash/resources/provider.dart';
//import 'package:carwash/resources/session.dart';

Widget navbar(RootProvider prov) {
  return Consumer<RootProvider>(
    builder: (context, prov, child) => BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Главная',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment),
          label: 'Учёт',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Настройки',
        ),
      ],
      currentIndex: prov.navIndex,
      selectedItemColor: Colors.amber[800],
      onTap: (int index) {
        prov.setNavIndex(index);
        if (index == 1) {
          prov.requestAllday();
        }
      },
    ),
  );
}

const TextStyle optionStyle =
    TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
