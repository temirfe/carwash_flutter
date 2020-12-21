import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'home.dart';
import 'package:carwash/resources/session.dart';
import 'package:carwash/resources/provider.dart';
import 'package:carwash/resources/dbhelper.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginScreenPage createState() => _LoginScreenPage();
}

class _LoginScreenPage extends State<LoginPage> {
  FocusNode focus;
  final _loginTC = new TextEditingController();
  final _passTC = new TextEditingController();
  //Stream myStream;
  StreamController<bool> connectionStreamController;
  RootProvider prov;

  @override
  void initState() {
    super.initState();

    focus = FocusNode();

    //myStream = timedCounter(Duration(seconds: 2));
    connectionStreamController = StreamController<bool>();
    checkConnection();

    prov = Provider.of<RootProvider>(context, listen: false);
    prov.formRequests();
  }

  void checkConnection() {
    //return hasConnection;
    Timer.periodic(Duration(seconds: 3), (timer) async {
      bool hasConnection = await DataConnectionChecker().hasConnection;
      //cprint('login checkconeection $hasConnection');
      if (!connectionStreamController.isClosed &&
          connectionStreamController.hasListener) {
        connectionStreamController.sink.add(hasConnection);
      }
    });
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    focus.dispose();
    connectionStreamController.close();
    super.dispose();
  }

  Widget build(context) {
    //cprint('Login build');
    return Scaffold(
      appBar: AppBar(
        title: Text('Вход'),
        centerTitle: true,
      ),
      body: _buildBody(context),
    );
  }

  Widget inetInfo() {
    return StreamBuilder<bool>(
      stream: connectionStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData && !snapshot.data) {
          return Text(
            'Нет подключения к сети!',
            style: TextStyle(color: Colors.red),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Consumer<RootProvider>(builder: (context, prov, child) {
        List<Widget> childrn = [
          loginField(context, prov),
          passwordField(context, prov),
          SizedBox(height: 24.0),
          submitButton(context, prov),
          SizedBox(height: 24.0),
          prov.versionInfo(),
          SizedBox(height: 10.0),
          inetInfo(),
        ];
        return Column(
          children: childrn,
        );
      }),
    );
  }

  Widget loginField(BuildContext context, RootProvider prov) {
    return Container(
      margin: EdgeInsets.only(top: 5.0, left: 20.0, right: 20.0),
      child: TextField(
        //autofocus: true,
        controller: _loginTC,
        textInputAction: TextInputAction.next,
        onSubmitted: (v) {
          FocusScope.of(context).requestFocus(focus);
        },
        decoration: InputDecoration(
          labelText: 'Логин',
          errorText: prov.loginError,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.yellow[800], width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget passwordField(BuildContext context, RootProvider prov) {
    return Container(
      margin: EdgeInsets.only(top: 4.0, left: 20.0, right: 20.0),
      child: TextField(
        focusNode: focus,
        controller: _passTC,
        obscureText: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'Пароль',
          errorText: prov.loginError,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.yellow[800], width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget submitButton(BuildContext ctx, RootProvider prov) {
    // cprint('submitButton ${prov.isSubmitting}');
    Widget contnt;
    Function onPresd;
    if (prov.isSubmitting) {
      contnt = new CircularProgressIndicator(
          valueColor: new AlwaysStoppedAnimation<Color>(Colors.white));
      onPresd = () {};
    } else {
      if (prov.loginSuccess) {
        //cprint('login success');
        new Future.delayed(new Duration(milliseconds: 100), () {
          // cprint('navigate to home');
          Route route = MaterialPageRoute(builder: (cntx) => HomePage());
          new Future.delayed(new Duration(milliseconds: 100), () {
            Navigator.of(ctx).pushReplacement(route);
          });
        });
      }
      contnt = Text(
        'Войти',
        style: TextStyle(color: Colors.white),
      );
      onPresd = () {
        prov.submitLogin(ctx, _loginTC.text, _passTC.text);
      };
    }

    return SizedBox(
      child: RaisedButton(
          onPressed: onPresd,
          child: contnt,
          color: Theme.of(context).primaryColor),
      height: 40.0,
      width: 200.0,
    );
  }

  /* Stream<int> timedCounter(Duration interval, [int maxCount]) async* {
    int i = 0;
    while (true) {
      await Future.delayed(interval);
      yield i++;
      if (i == maxCount) break;
    }
  } */
}
