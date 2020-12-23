import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:carwash/resources/session.dart';
import 'package:carwash/resources/washModel.dart';
import 'package:carwash/resources/dbhelper.dart';
import 'endpoints.dart';
//import 'package:flushbar/flushbar.dart';

class RootProvider with ChangeNotifier {
  int value = 0;
  BuildContext rcontext;
  int navIndex = 0, xPageCount, xTotalCount = 0, xCurrentPage = 0;
  Map<String, dynamic> washFormMap = {'washers': []},
      subserv2Map = {'washers': []},
      addServMap = {'washers': []};
  Map<int, Wash> washesMap = {};
  List categories,
      washers,
      services,
      activeWashers, //it's List<Map<String, String>>
      discounts; //List<Map<String, String>>
  List prices; //it's List<Map<String, dynamic>>
  Map<int, String> ctgNameMap = {}, servNameMap = {};
  Map<int, Map> washersMap = {};
  final DatabaseHelper db = DatabaseHelper();
  StreamController<Map> mapStrmCtrl = StreamController<Map>.broadcast();

  /*
   * selectedWashers is used in create, washes who are 'in_service' will be populated and will be preselected
   * updateWashers is used in update
   * selectedServices is not used
   */
  List<String> selectedServices = [], selectedWashers = [], updateWashers = [];

  bool isSubmitting = false, loginSuccess = false, isLoading = true;
  String loginError, washFormError = "";
  Timer timer;
  String formPriceShow;
  List<String> cameraImgs;
  List analyticsList;
  String showListFromDate;
  bool fabVisible = true;
  String today;
  String version; //app version
  String queryPlate = "";

  void closeStreams() {
    db.closeDb();
    mapStrmCtrl.close();
  }

  void sinkMap(Map val) {
    if (!mapStrmCtrl.isClosed && mapStrmCtrl.hasListener) {
      mapStrmCtrl.sink.add(val);
    }
  }

  void plateQueryRequest(String plate) async {
    queryPlate = plate;
    bool result = await DataConnectionChecker().hasConnection;
    if (result && plate.length > 0) {
      requestList();
    } else {
      requestListFromDb();
    }
  }

  void setCameraImg(path) {
    cameraImgs.add(path);
    notifyListeners();
  }

  void increment() {
    value += 1;
    notifyListeners();
  }

  void setContext(BuildContext cntx) {
    if (rcontext == null) {
      rcontext = cntx;
    }
  }

  BuildContext getContext() {
    return rcontext;
  }

  void setNavIndex(int index) {
    navIndex = index;
    if ((showListFromDate == null || showListFromDate == today) &&
        navIndex == 0) {
      fabVisible = true;
    } else {
      fabVisible = false;
    }
    /* if (index == 1) {
      cprint('formRequests');
      formRequests();
    } */
    notifyListeners();
  }

  void clearFormMap() {
    washFormMap = {'washers': []};
    updateWashers = [];
    cameraImgs = [];
    formPriceShow = null;
  }

  void requestList() async {
    //cprint('requestList');
    //String authKey = session.getString('authKey');
    try {
      isLoading = true;
      //cprint('showListFromDate $showListFromDate');
      Response response = await Dio().get(Endpoints.washes, queryParameters: {
        'page': (xCurrentPage + 1),
        'date': showListFromDate,
        'plate': queryPlate
      }
          //options: Options(headers: {'Authorization': "Bearer $authKey"}),
          );
      response.headers.forEach((name, values) {
        if (name == 'x-pagination-page-count') {
          xPageCount = int.parse(values[0]);
        } else if (name == 'x-pagination-current-page') {
          xCurrentPage = int.parse(values[0]);
        } else if (name == 'x-pagination-total-count') {
          xTotalCount = int.parse(values[0]);
        }
      });
      //cprint('xpages count:$xPageCount, current: $xCurrentPage');
      if (response.data.isEmpty) {
        washesMap = {};
      } else {
        response.data.forEach((wmap) {
          washesMap[wmap['id']] = new Wash.fromJson(wmap);
        });
      }
      isLoading = false;
      notifyListeners();
    } on DioError catch (e) {
      cprint('Error requestList: $e');
    }
  }

  void submitLogin(BuildContext ctx, String login, String pass) {
    loginError = null;
    isSubmitting = true;
    notifyListeners();
    auth(ctx, login, pass);
  }

  void auth(BuildContext ctx, String username, String password) async {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    try {
      Response response = await Dio().post(Endpoints.login,
          options: Options(headers: {'Authorization': basicAuth}));
      Map<String, dynamic> resp = response.data;

      //cprint('logged in $resp');
      if (resp != null && resp.containsKey('id')) {
        sessionSaveAuth(resp);
        loginSuccess = true;
      } else {
        loginError = 'Неверный логин или пароль';
      }
      isSubmitting = false;
      notifyListeners();
    } catch (e) {
      if (e.response != null && e.response.statusCode == 401) {
        loginError = 'Неверный логин или пароль';
        isSubmitting = false;
        notifyListeners();
      } else {
        print(e);
        // Something happened in setting up or sending the request that triggered an Error
        cprint('Error request: ${e.request.headers}');
        cprint('Error message: ${e.message}');
      }
    }
  }

  Future<void> formRequests() async {
    bool result = await DataConnectionChecker().hasConnection;
    if (result) {
      //requestDeleteds();
      requestCategories();
      requestServices();
      requestWashers();
      requestPrices();
      requestActiveWashers();
      requestDiscounts();
    }

    /* if (categories == null) {
      requestCategories();
    }
    if (services == null) {
      requestServices();
    }
    if (washers == null) {
      requestWashers();
    }
    if (prices == null) {
      requestPrices();
    } */
  }

  Future<void> requestServices() async {
    //int ts = await db.getMaxTimestamp('service');
    try {
      Response response = await Dio().get(
        Endpoints.services, /* queryParameters: {'updated_at': ts} */
      );
      //cprint('serv resp: ${response.data}');
      cprint('serv resp: ${response.data.length}');
      if (response.data != null && response.data.isNotEmpty) {
        //await db.import('service', response.data);
        populateServices(response.data);
      }
      //services = response.data;
      //notifyListeners();
    } on DioError catch (e) {
      cprint('Error requestServices: $e');
    }
  }

  Future<void> requestCategories() async {
    //int ts = await db.getMaxTimestamp('category');
    try {
      Response response = await Dio().get(
        Endpoints.categories, /* queryParameters: {'updated_at': ts} */
      );
      //cprint('ctg resp: ${response.data}');
      cprint('ctg resp: ${response.data.length}');
      if (response.data != null && response.data.isNotEmpty) {
        //await db.import('category', response.data);
        populateCategories(response.data);
        //populateFromDb();
      }
    } on DioError catch (e) {
      cprint('Error requestCategories: $e');
    }
  }

  Future<void> requestWashers() async {
    //int ts = await db.getMaxTimestamp('user');
    try {
      Response response = await Dio().get(
        Endpoints.washers, /* queryParameters: {'updated_at': ts} */
      );
      //cprint('washers resp: ${response.data}');
      //cprint('washers resp: ${response.data.length}');
      if (response.data != null && response.data.isNotEmpty) {
        //await db.import('user', response.data);
        populateWashers(response.data);
      }
      /* washers = response.data;
      washers.forEach((map) {
        if (map['in_service'] == '1') {
          selectedWashers.add(map['id']);
        }
      });
      notifyListeners(); */
    } on DioError catch (e) {
      cprint('Error requestWashers: $e');
    }
  }

  Future<void> requestActiveWashers() async {
    //int ts = await db.getMaxTimestamp('user');
    try {
      Response response = await Dio().get(Endpoints.wash + '/actives');
      //cprint('active washers resp: ${response.data}');
      if (response.data != null && response.data.isNotEmpty) {
        //await db.import('user', response.data);
        activeWashers = response.data;
      }
    } on DioError catch (e) {
      cprint('Error requestActiveWashers: $e');
    }
  }

  Future<void> requestDiscounts() async {
    //int ts = await db.getMaxTimestamp('user');
    try {
      Response response = await Dio().get(Endpoints.wash + '/discounts');
      //cprint('active washers resp: ${response.data}');
      if (response.data != null && response.data.isNotEmpty) {
        //await db.import('user', response.data);
        discounts = response.data;
      }
    } on DioError catch (e) {
      cprint('Error requestDiscounts: $e');
    }
  }

  Future<void> requestDeleteds() async {
    int lastId = await db.getMaxTimestamp('deleted');
    try {
      Response response = await Dio()
          .get(Endpoints.deleted, queryParameters: {'last_id': lastId});
      //cprint('resp: ${response.data}');
      if (response.data != null && response.data.isNotEmpty) {
        db.importDeleted(response.data);
      }
    } on DioError catch (e) {
      cprint('Error requestDeletedss: $e');
    }
  }

  Future<void> requestPrices() async {
    //int ts = await db.getMaxTimestamp('price');
    try {
      Response response = await Dio().get(
        Endpoints.prices, /* queryParameters: {'updated_at': ts} */
      );
      //cprint('price resp: ${response.data}');
      cprint('price resp: ${response.data.length}');
      if (response.data != null && response.data.isNotEmpty) {
        //await db.import('price', response.data);
        prices = response.data;
      }
      //notifyListeners();
    } on DioError catch (e) {
      cprint('Error requestPrices: $e');
    }
  }

//not used
  void formService(String id, bool add) {
    if (add) {
      selectedServices.add(id);
    } else {
      selectedServices.remove(id);
    }
    notifyListeners();
  }

  void formService2(String id) {
    washFormMap['service_id'] = id;
    setFormPriceShow();
    notifyListeners();
  }

  void setFormPriceShow() {
    if (washFormMap.containsKey('service_id') &&
        washFormMap.containsKey('category_id')) {
      prices.forEach((priceMap) {
        if (priceMap['service_id'].toString() == washFormMap['service_id'] &&
            priceMap['category_id'].toString() == washFormMap['category_id']) {
          formPriceShow = priceMap['price'].toString();
          //cprint('setting fp is good $formPriceShow');
        }
      });
    }
  }

  void addServSelect(String field, String id) {
    addServMap[field] = id;
    notifyListeners();
  }

//only one map is actual at once. Just used common method.
  void formWasher(String id, bool add) {
    if (add) {
      if (!washFormMap.containsKey('washers')) {
        washFormMap['washers'] = <String>[];
      }
      washFormMap['washers'].add(id);
      subserv2Map['washers'].add(id);
      addServMap['washers'].add(id);
    } else {
      washFormMap['washers'].remove(id);
      subserv2Map['washers'].remove(id);
      addServMap['washers'].remove(id);
    }
    /* if (mode == 'insert') {
      if (add) {
        selectedWashers.add(id);
      } else {
        selectedWashers.remove(id);
      }
    } else {
      if (add) {
        updateWashers.add(id);
      } else {
        updateWashers.remove(id);
      }
    } */
    notifyListeners();
  }

  void changeWasherStatusDb(int userId, bool isChecked) async {
    try {
      int inService = 0;
      String idStr = userId.toString();
      if (isChecked) {
        inService = 1;
        if (!selectedWashers.contains(idStr)) {
          selectedWashers.add(idStr);
        }
      } else {
        selectedWashers.remove(idStr);
      }
      /* List washersCopy = []..addAll(washers);
      washersCopy[index]['in_service'] = inService;
      washers = washersCopy; */
      db.updateUser(userId, inService);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  void changeWasherStatus(String id, bool value) async {
    try {
      String authKey = session.getString('authKey');
      Response response = await Dio().post(
        Endpoints.washer,
        data: {'id': id, 'val': value},
        options: Options(headers: {'Authorization': "Bearer $authKey"}),
      );
      List resp = response.data;
      //cprint('resp: ${response.data}');
      if (resp != null) {
        washers = resp;
        selectedWashers = [];
        washers.forEach((map) {
          if (map['in_service'] == '1') {
            selectedWashers.add(map['id']);
          }
        });
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  void finishWash(Wash wash) async {
    int ts = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    int duration = ts - wash.startedAt;
    int durStatus = 0;

    var row = await db.standartDuration(wash);
    int standartDuration = row[0]['duration'] * 60; //minutes to seconds
    if (duration > (standartDuration + 60)) {
      durStatus = 2;
    } else if ((standartDuration - duration) / standartDuration >= 0.2) {
      durStatus = 1;
    } //if 20% or more faster
    db.finishWash(wash.id, ts, duration, durStatus);
    wash.finishedAt = ts;
    wash.durationStatus = durStatus;
    wash.setTimes = wash;
    wash.duration = duration;
    washesMap[wash.id] = wash;
    notifyListeners();
    //cprint('duration $duration status $durStatus');
  }

  void requestWash(int id) async {
    try {
      String authKey = session.getString('authKey');
      Response response = await Dio().get(Endpoints.wash + '/$id',
          options: Options(headers: {'Authorization': "Bearer $authKey"}));
      var resp = response.data; //Map<String<dynamic>
      //cprint('requestWash resp: ${response.data}');
      if (resp != null) {
        washesMap[resp['id']] = new Wash.fromJson(resp);
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  void requestFinish(int washId, int washServiceId) async {
    try {
      sinkMap({'finish': true});
      String authKey = session.getString('authKey');
      Response response = await Dio().post(Endpoints.finish,
          data: {'id': washServiceId},
          options: Options(headers: {'Authorization': "Bearer $authKey"}));
      var resp = response.data; //bool
      sinkMap({'finish': false});
      cprint('requestFinish resp: ${response.data}');
      if (resp) {
        requestWash(washId);
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> requestAddService(int washId) async {
    try {
      sinkMap({'addService': true});
      String authKey = session.getString('authKey');
      Response response = await Dio().post(Endpoints.wash + '/addservice',
          data: addServMap,
          options: Options(headers: {'Authorization': "Bearer $authKey"}));
      var resp = response.data; //bool
      sinkMap({'addService': false});
      cprint('requestAddService resp: ${response.data}');
      if (resp == true) {
        requestWash(washId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  void startSecond(int washId, int washServiceId) async {
    sinkMap({'second': true});
    try {
      Response response = await Dio().post(Endpoints.wash + '/start',
          data: {'id': washServiceId, 'washers': subserv2Map['washers']});
      var resp = response.data;
      cprint('startSecond $resp');
      requestWash(washId);
      notifyListeners();
    } catch (e) {
      print(e);
      sinkMap({'second': false});
    }
    sinkMap({'second': false});
  }

  void washPaid(Wash wash) async {
    await db.washPaid(wash);
    washesMap[wash.id].setPaid = 1;
    notifyListeners();
  }

  void requestPaid(int id) async {
    sinkMap({'paid': true});
    try {
      String authKey = session.getString('authKey');
      Response response = await Dio().post(Endpoints.paid,
          data: {'id': id},
          options: Options(headers: {'Authorization': "Bearer $authKey"}));
      sinkMap({'paid': false});
      // cprint('resp: ${response.data}');
      if (response.data) {
        washesMap[id].setPaid = 1;
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  void setDay(String day) {
    washesMap = {};
    xCurrentPage = 0;
    showListFromDate = day;
    if (day != today || navIndex != 0) {
      fabVisible = false;
    } else {
      fabVisible = true;
    }
    isLoading = true;
    notifyListeners();
    requestAllday();
  }

  void requestAllday() async {
    //cprint('requestAllday $showListFromDate');
    List<Map<String, dynamic>> rows = await db.findAllDay(showListFromDate);
    if (rows.isNotEmpty) {
      Map<int, Map> washMap = {};
      if (washersMap.isEmpty) {
        await populateFromDb(false);
      }
      rows.forEach((row) {
        Map washer = {
          'id': row['user_id'],
          'name': washersMap[row['user_id']]['name'],
          'wage': row['wage']
        };
        if (washMap.containsKey(row['id'])) {
          washMap[row['id']]['washers'].add(washer);
        } else {
          washMap[row['id']] = {
            'id': row['id'],
            'price': row['price'],
            'paid': row['paid'],
            'washers': [washer]
          };
        }
      });
      analyticsList = [];
      washMap.forEach((id, wash) => analyticsList.add(wash));
      notifyListeners();
    }
  }

  void requestAlldayServer() async {
    try {
      String authKey = session.getString('authKey');
      Response response = await Dio().get(Endpoints.allday,
          queryParameters: {'date': showListFromDate},
          options: Options(headers: {'Authorization': "Bearer $authKey"}));
      analyticsList = response.data;
      notifyListeners();
      //cprint('resp: $response.data');
    } catch (e) {
      print(e);
    }
  }

  void requestListFromDb({bool cont}) async {
    //cprint('requestListFromDb');
    isLoading = true;
    await populateFromDb(true);

    if (cont != null && cont) {
      xCurrentPage++;
    }

    var response = await db.findAllWashes(this);
    xTotalCount = response.length;
    //xPageCount = (xTotalCount / 25).ceil();
    xPageCount = 1;

    if (cont == null || !cont) {
      washesMap = {};
    }
    if (response.isEmpty) {
      washesMap = {};
    } else {
      response.forEach((wmap) {
        //cprint('wash id ${wmap['id']}');
        Map<String, dynamic> rowMap = new Map<String, dynamic>.from(wmap);
        rowMap['category'] = ctgNameMap[wmap['category_id']];
        rowMap['service'] = servNameMap[wmap['service_id']];
        washesMap[wmap['id']] = new Wash.fromJson(rowMap);
      });
    }
    isLoading = false;
    notifyListeners();
  }

  void deleteOldWashesLocal() {
    db.deleteOldWashes();
  }

  void formCtg(String id) {
    washFormMap['category_id'] = id;
    setFormPriceShow();
    notifyListeners();
  }

  Future<String> getVersionNumber() async {
    if (kIsWeb) {
      return ""; //package_info doesn't work on web
    }
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Widget versionInfo() {
    return FutureBuilder(
        future: getVersionNumber(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) => Text(
              snapshot.hasData ? snapshot.data : "",
            ) // The widget using the data
        );
  }

  Future<void> exportWash() async {
    bool hasConnection = await DataConnectionChecker().hasConnection;
    if (!hasConnection) {
      return;
    }

    //delete server deletes first, otherwise they get exported and created new at server
    await requestDeleteds();

    //ask server for latest updated timestamp to know from which row to export
    /* Response response = await Dio().get(
      Endpoints.lastapi,
      queryParameters: {'tbl': 'wash'},
    );
    var ts = response.data;
    if (ts == null) {
      ts = 0;
    } */

    String authKey = session.getString('authKey');

    //var rows = await db.findAll('wash', where: 'updated_at > $ts', limit: 10);
    var rows =
        await db.findAll('wash', where: "tags NOT LIKE '%web%'", limit: 10);
    if (rows != null && rows.length > 0) {
      List formList = [];
      List idList = [];
      for (Map row in rows) {
        idList.add(row['id']);
        //cprint('wash export row $row');
        Map<String, dynamic> formMap = Map.from(row);
        if (formMap['photo_local'] != null) {
          List<String> apimages = [];
          formMap['photo_local'].split(';').forEach((path) {
            apimages.add(base64Encode(File(path).readAsBytesSync()));
          });
          formMap['apimages'] = apimages;
        }

        formMap['wash_user_api'] =
            await db.findAll('wash_user', where: 'wash_id=${formMap['id']}');
        formMap['upd_api'] =
            await db.findAll('upd', where: 'wash_id=${formMap['id']}');

        formList.add(formMap);
      }

      try {
        Response response = await Dio().post(Endpoints.import,
            data: {'tbl': 'wash', 'rows': formList},
            options: Options(headers: {'Authorization': "Bearer $authKey"}));
        //cprint('wash export resp: ${response.data}');
        if (response.data != null) {
          await db.saveServerIds('wash', response.data);
          await db.addWebTag(idList);
        }
      } on DioError catch (e) {
        cprint('Error message: $e');
        if (e.response != null) {
          cprint('Error resp.data: ${e.response.data}');
          cprint('Error resp.statusCode: ${e.response.statusCode}');
          cprint('Error resp.headers: ${e.response.headers}');
          cprint('Error resp.request: ${e.response.request}');
        } else {
          // Something happened in setting up or sending the request that triggered an Error
          cprint('Error request: ${e.request.headers}');
          cprint('Error message: ${e.message}');
        }
      }
    } else {
      //cprint('wash export no greater than $ts');
    }
  }

  void export(String tbl) async {
    //ask server for latest updated timestamp to know from which row to export
    Response response = await Dio().get(
      Endpoints.lastapi,
      queryParameters: {'tbl': tbl},
    );
    var ts = response.data;
    if (ts == null) {
      ts = 0;
    }
    // cprint('export ts $ts');

    /* var result = await db.exportTest(ts);
    if (result != null && result.length > 0) {
      cprint('exporting: $result');
      Response response = await Dio().post(
        Endpoints.import,
        data: {'tbl': tbl, 'rows': result},
      );
      cprint('export resp ${response.data}');
      Map resp = response.data;
      if (resp != null && resp.isNotEmpty) {
        db.saveTestIds(resp);
      }
    } */
  }

  void import(String tbl) async {
    bool hasConnection = await DataConnectionChecker().hasConnection;
    if (!hasConnection) {
      return;
    }

    //ts is latest update_server to tell server from which rows to send
    var ts = await db.getMaxTimestamp(tbl);
    String authKey = session.getString('authKey');

    Response response = await Dio().get(Endpoints.export,
        queryParameters: {'tbl': tbl, 'updated_at': ts},
        options: Options(headers: {'Authorization': 'Bearer $authKey'}));
    var resp = response.data;
    //cprint('imp resp $resp');
    if (resp != null && resp.length > 0) {
      db.import(tbl, resp);
    }
  }

  void importWash() async {
    bool hasConnection = await DataConnectionChecker().hasConnection;
    if (!hasConnection) {
      return;
    }

    //ts is latest update_server to tell server from which rows to send
    //int ts = await db.getMaxTimestamp('wash');
    //int lastServeId = await db.getMaxServerId('wash');
    String authKey = session.getString('authKey');
    String deviceId = session.getString('deviceId');

    //when new version of app installed, server tags should be reset for this device
    bool reset = false;
    int washCount = await db.count('wash');
    if (washCount == 0) {
      reset = true;
    }

    var resp;
    try {
      //cprint('importWash $deviceId');
      Response response = await Dio().get(Endpoints.export,
          queryParameters: {
            'tbl': 'wash',
            'device_id': deviceId,
            'reset': reset
            //'updated_at': ts,
            //'server_id': lastServeId
          },
          options: Options(headers: {'Authorization': 'Bearer $authKey'}));
      resp = response.data;
    } on DioError catch (e) {
      cprint('importWash Error message: $e');
      if (e.response != null) {
        cprint('Error resp.data: ${e.response.data}');
        cprint('Error resp.statusCode: ${e.response.statusCode}');
        cprint('Error resp.headers: ${e.response.headers}');
        cprint('Error resp.request: ${e.response.request}');
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        cprint('Error request: ${e.request.headers}');
        cprint('Error message: ${e.message}');
      }
    }

    //cprint('imp resp $resp');
    var dbo = await db.db;
    if (resp != null && resp.length > 0) {
      for (Map wash in resp) {
        wash['server_id'] = wash['id'];
        wash['updated_server'] = wash['updated_at'];
        List washers = wash['washers'];
        List updates = wash['updates'];
        wash.remove('id');
        wash.remove('updated_at');
        wash.remove('updated_api');
        wash.remove('category');
        wash.remove('service');
        wash.remove('washers');
        wash.remove('updates');
        int localId = await db.checkLocal('wash', wash['server_id']);
        if (localId == 0) {
          localId = await dbo.insert('wash', wash);
        } else {
          await dbo.update('wash', wash, where: 'id = ?', whereArgs: [localId]);
        }
        Batch batch = dbo.batch();
        batch.delete('wash_user', where: 'wash_id=?', whereArgs: [localId]);
        washers.forEach((wshr) {
          batch.insert("wash_user", {
            'wash_id': localId,
            'user_id': wshr['id'],
            'wage': wshr['wage']
          });
        });
        updates.forEach((upd) {
          batch.insert('upd', {
            'wash_id': localId,
            'field': upd['field'],
            'old_value': upd['old_value'],
            'new_value': upd['new_value'],
            'created_by': upd['created_by'],
            'created_at': upd['created_at'],
            'updated_server': upd['updated_at']
          });
        });
        await batch.commit();
      }
      requestListFromDb();
    }
  }

  void populateCategories(List src) {
    categories = src;
    categories.forEach((ctgMap) {
      var severId;
      if (ctgMap.containsKey('server_id')) {
        severId = ctgMap['server_id'];
      } else {
        severId = ctgMap['id'];
      }
      if (severId is String) {
        severId = int.parse(severId);
      }
      ctgNameMap[severId] = ctgMap['title'];
    });
  }

  void populateServices(List src) {
    services = src;
    services.forEach((srvMap) {
      /* var severId;
      if (srvMap.containsKey('server_id')) {
        severId = srvMap['server_id'];
      } else {
        severId = srvMap['id'];
      }
      if (severId is String) {
        severId = int.parse(severId);
      }
      servNameMap[severId] = srvMap['title']; */
    });
  }

  void populateWashers(List src) {
    washers = src;
    washers.forEach((map) {
      var severId;
      if (map.containsKey('server_id')) {
        severId = map['server_id'];
      } else {
        severId = map['id'];
      }

      if (severId is String) {
        severId = int.parse(severId);
      }
      washersMap[severId] = {
        'id': severId,
        'name': map['username'],
        'wage': null
      };
      if (map['in_service'] == 1) {
        selectedWashers.add(map['server_id'].toString());
      }
    });
  }

  Future<void> populateFromDb(bool notify) async {
    bool isPopulated = false;
    if (categories == null ||
        categories.isEmpty ||
        ctgNameMap == null ||
        ctgNameMap.isEmpty) {
      //cprint('populateFromDb findall category');
      List dbCtgs = await db.findAll('category');
      populateCategories(dbCtgs);
      isPopulated = true;
    }
    if (services == null ||
        services.isEmpty ||
        servNameMap == null ||
        servNameMap.isEmpty) {
      //cprint('populateFromDb findall service');
      List dbSrv = await db.findAll('service');
      populateServices(dbSrv);
      isPopulated = true;
    }
    if (prices == null) {
      //cprint('populateFromDb findall price');
      prices = await db.findAll('price');
      isPopulated = true;
    }
    if (washers == null || washersMap.isEmpty) {
      //cprint('populateFromDb findall user');
      List src = await db.findAll('user');
      populateWashers(src);
      isPopulated = true;
    }

    if (isPopulated && notify) {
      Future.delayed(Duration.zero);
      notifyListeners();
    }
  }

  Future<int> submit(String mode) async {
    bool good = true;
    washFormError = "";
    String authKey = session.getString('authKey');
    if (!washFormMap.containsKey('category_id')) {
      washFormError += 'Выберите категорию \n';
      good = false;
    }
    if (!washFormMap.containsKey('service_id')) {
      washFormError += 'Выберите услугу \n';
      good = false;
    }
    /* if (selectedServices.length > 0) {
      for (int i = 0; i < selectedServices.length; i++) {
        washFormMap['services[$i]'] = selectedServices[i];
      }
    } else {
      washFormError += 'Выберите услугу ';
      good = false;
    } */
    /* if (mode == 'insert' && selectedWashers.length > 0) {
      for (int i = 0; i < selectedWashers.length; i++) {
        //washFormMap['washers[$i]'] = selectedWashers[i];
      }
      washFormMap['washers'] = selectedWashers;
    } else if (mode == 'update' && updateWashers.length > 0) {
      for (int i = 0; i < updateWashers.length; i++) {
        //washFormMap['washers[$i]'] = updateWashers[i];
      }
      washFormMap['washers'] = updateWashers;
    } */
    if (washFormMap['washers'].length == 0) {
      washFormError += 'Выберите персонал ';
      good = false;
    }
    if (cameraImgs.isNotEmpty) {
      int i = 0;
      cameraImgs.forEach((path) {
        washFormMap['apimages[$i]'] =
            base64Encode(File(path).readAsBytesSync());
        i++;
      });
    }
    if (good) {
      //cprint('submit $washFormMap');
      Response response;
      Map<String, dynamic> dbData;
      try {
        isSubmitting = true;
        notifyListeners();
        bool isInsert = true;
        washFormMap['price'] = formPriceShow;
        if (washFormMap.containsKey('id') && washFormMap['id'] != null) {
          isInsert = false;
          response = await Dio().put(
            Endpoints.washes + '/${washFormMap['id']}',
            data: washFormMap,
            options: Options(
                headers: {'Authorization': "Bearer $authKey"},
                contentType: Headers.formUrlEncodedContentType),
          );
        } else {
          cprint('formData $washFormMap');
          FormData formData = new FormData.fromMap(washFormMap);
          response = await Dio().post(Endpoints.washes,
              data: formData,
              options: Options(headers: {'Authorization': "Bearer $authKey"}));
        }

        //cprint('resp: ${response.data}');

        if (isInsert) {
          //prepend to map on create
          Map<int, Wash> washesMapNew = {
            response.data['id']: new Wash.fromJson(response.data)
          };
          washesMap.forEach((k, v) {
            washesMapNew[k] = v;
          });
          washesMap
            ..clear()
            ..addAll(washesMapNew);
          xTotalCount++;
        } else {
          //just append with populating needed data
          washesMap[response.data['id']] = new Wash.fromJson(dbData);
        }

        isSubmitting = false;
        //showListFromDate = null;
        //setNavIndex(0);
        clearFormMap();
        //selectedServices = [];
        notifyListeners();
        return response.data['id'];
      } on DioError catch (e) {
        cprint('Error message: $e');
        if (e.response != null) {
          cprint('Error resp.data: ${e.response.data}');
          cprint('Error resp.statusCode: ${e.response.statusCode}');
          cprint('Error resp.headers: ${e.response.headers}');
          cprint('Error resp.request: ${e.response.request}');
        } else {
          // Something happened in setting up or sending the request that triggered an Error
          cprint('Error request: ${e.request.headers}');
          cprint('Error message: ${e.message}');
        }
      }
    } else {
      // cprint('submit not good');
      notifyListeners();
    }
    return null;
  }

  Future<int> submitDb(String mode) async {
    bool good = true;
    washFormError = "";
    if (!washFormMap.containsKey('category_id')) {
      washFormError += 'Выберите категорию \n';
      good = false;
    }
    if (!washFormMap.containsKey('service_id')) {
      washFormError += 'Выберите услугу \n';
      good = false;
    }
    if (mode == 'insert' && cameraImgs.isEmpty) {
      washFormError += 'Добавьте фото \n';
      good = false;
    }
    if (mode == 'insert' && selectedWashers.length > 0) {
      washFormMap['washers'] = selectedWashers;
    } else if (mode == 'update' && updateWashers.length > 0) {
      washFormMap['washers'] = updateWashers;
    } else {
      washFormError += 'Выберите персонал ';
      good = false;
    }
    if (cameraImgs.isNotEmpty) {
      washFormMap['photo_local'] = cameraImgs.join(';');
    }
    if (good) {
      //cprint('submit $washFormMap');
      Map<String, dynamic> dbData;
      isSubmitting = true;
      notifyListeners();
      bool isInsert = true;
      washFormMap['price'] = formPriceShow;
      if (washFormMap.containsKey('id') && washFormMap['id'] != null) {
        isInsert = false;
        dbData = await db.updateWash(washFormMap, this);
      } else {
        //cprint('formData $washFormMap');
        dbData = await db.insertWash(washFormMap, this);
      }

      //cprint('resp: ${response.data}');

      if (isInsert) {
        //prepend to map on create
        Map<int, Wash> washesMapNew = {dbData['id']: new Wash.fromJson(dbData)};
        washesMap.forEach((k, v) {
          washesMapNew[k] = v;
        });
        washesMap
          ..clear()
          ..addAll(washesMapNew);
        xTotalCount++;
      } else {
        //just append with populating needed data

        //get the row, becuse dbData doesn't contain all the data
        var washRow = await db.findAll('wash', where: 'id=${dbData['id']}');
        dbData = Map.from(washRow[0]);
        int ctgId = dbData['category_id'] is String
            ? int.parse(dbData['category_id'])
            : dbData['category_id'];
        int servId = dbData['service_id'] is String
            ? int.parse(dbData['service_id'])
            : dbData['service_id'];
        dbData['category'] = ctgNameMap[ctgId];
        dbData['service'] = servNameMap[servId];
        washesMap[dbData['id']] = new Wash.fromJson(dbData);
      }

      isSubmitting = false;
      clearFormMap();
      notifyListeners();
      return dbData['id'];
    } else {
      // cprint('submit not good');
      notifyListeners();
    }
    return null;
  }
}
