import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/washView.dart';
import 'screens/washForm.dart';
import 'screens/price.dart';
import 'screens/washers.dart';
import 'screens/testPage.dart';
import 'package:carwash/resources/session.dart';
import 'package:carwash/resources/provider.dart';
//import 'package:desko/screens/post/categoryList.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  session = await SharedPreferences.getInstance();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => RootProvider()),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget openScreen = LoginPage();
    //openScreen = HomePage();
    if (session.getInt('userId') != null) {
      openScreen = HomePage();
      //openScreen = TestPage();
    }
    return MaterialApp(
        title: 'CarWash',
        home: openScreen,
        //initialRoute: 'ini',
        onGenerateRoute: routes,
        debugShowCheckedModeBanner: false);
  }

  Route routes(RouteSettings settings) {
    if (settings.name == '/') {
      return MaterialPageRoute(
          settings: RouteSettings(name: "/"),
          builder: (context) {
            return HomePage();
          });
    } else if (settings.name == 'login') {
      return MaterialPageRoute(
        builder: (context) {
          return LoginPage();
        },
        maintainState: false,
      );
    } else if (settings.name == 'add') {
      return MaterialPageRoute(
        builder: (context) {
          return WashForm(null);
        },
      );
    } else if (settings.name == 'price') {
      return MaterialPageRoute(
        builder: (context) {
          return Price();
        },
      );
    } else if (settings.name == 'washers') {
      return MaterialPageRoute(
        builder: (context) {
          return Washers();
        },
      );
    } else if (settings.name == 'test') {
      return MaterialPageRoute(
        builder: (context) {
          return TestPage();
        },
      );
    } else {
      return MaterialPageRoute(
          builder: (context) {
            final itemId = int.parse(settings.name.replaceFirst('/', ''));
            if (itemId != null && itemId > 0) {
              return WashView(itemId);
            } else {
              return HomePage();
            }
          },
          maintainState: false);
    }
  }
}
