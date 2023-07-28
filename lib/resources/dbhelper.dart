import 'dart:io';
import 'dart:async';

import 'package:intl/intl.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:carwash/resources/provider.dart';
import 'package:carwash/resources/washModel.dart';
import 'session.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = new DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  DatabaseHelper.internal();

  initDb() async {
    //cprint('initDB is run');

    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "db1.db");
    //bool exists = await databaseExists(path);
    //cprint('db exists $exists');
    //await deleteDatabase(path);
    Database theDb = await openDatabase(path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure);
    return theDb;
  }

  closeDb() {
    _db?.close();
  }

  Future<int> insertTest(String? txt) async {
    DateTime now = DateTime.now();
    int currentTS = (now.millisecondsSinceEpoch / 1000).round();
    if (txt == null) {
      txt = DateFormat.Hms().format(now);
    }
    Map<String, dynamic> data = {
      'name': txt,
      'value': 4,
      'num': 1.4,
      'updated_at': currentTS
    };
    var dbo = await db;
    int res = await dbo.insert("test", data);
    return res;
  }

  Future<List<Map<String, dynamic>>> exportTest(int timestamp) async {
    var dbo = await db;
    var res =
        await dbo.rawQuery("SELECT * FROM test WHERE updated_at > $timestamp");
    return res;
  }

  Future<List<Map<String, dynamic>>> exportWash(int timestamp) async {
    var dbo = await db;
    if (!dbo.isOpen) {
      //cprint('db is not open exportWash');
      sleep(const Duration(seconds: 1));
    }
    var res =
        await dbo.rawQuery("SELECT * FROM wash WHERE updated_at > $timestamp");
    return res;
  }

  Future<int> updateTest() async {
    int currentTS = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    var dbo = await db;
    var res = await dbo.update(
        'test', {'name': 'update nah', 'updated_at': currentTS},
        where: 'id = ?', whereArgs: [1]);
    return res;
  }

  void updateUser(int userId, int inService) async {
    int currentTS = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    var dbo = await db;
    await dbo.update('user', {'in_service': inService, 'updated_at': currentTS},
        where: 'server_id = ?', whereArgs: [userId]);
  }

  Future<void> saveServerIds(String tbl, Map idMap) async {
    var dbo = await db;
    idMap.forEach((id, serverId) async {
      await dbo.update(tbl, {'server_id': serverId},
          where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> addWebTag(List idList) async {
    var dbo = await db;
    String ids = idList.join(',');
    await dbo.rawUpdate("UPDATE wash SET tags=tags||' web ' WHERE id IN($ids)");
  }

  Future<Map<String, dynamic>> insertWash(
      Map<String, dynamic> formData, RootProvider prov) async {
    int ts = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    List<Map> formDataWashers = [];

    formData['started_at'] = ts;
    formData['updated_at'] = ts;
    formData['user_id'] = session.getInt('userId');
    formData['tags'] = session.getString('deviceId');
    List washers = formData['washers'];
    formData.remove('washers');
    washers.forEach((uid) {
      formDataWashers.add(prov.washersMap[int.parse(uid)]!);
    });

    var dbo = await db;
    int washId = await dbo.insert("wash", formData);
    formData['id'] = washId;
    formData['washers'] = formDataWashers;
    formData['category'] = prov.ctgNameMap[int.parse(formData['category_id'])];
    formData['service'] = prov.servNameMap[int.parse(formData['service_id'])];

    Batch batch = dbo.batch();
    batch.update('user', {'in_service': 0});
    washers.forEach((uid) {
      batch.insert("wash_user", {'wash_id': washId, 'user_id': uid});
      batch.rawUpdate(
          'UPDATE user SET in_service = ? WHERE server_id = ?', [1, uid]);
    });
    batch.commit();
    //cprint('wash inserted $washId');

    return formData;
  }

  Future<Map<String, dynamic>> updateWash(
      Map<String, dynamic> formData, RootProvider prov) async {
    int ts = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    formData['updated_at'] = ts;
    formData['updated_by'] = session.getInt('userId');
    formData['tags'] = session.getString('deviceId');

    int washerCount = formData['washers'].length;
    List<String> washers = formData['washers'];
    //there is no washers fields so remove it
    formData.remove('washers');

    var dbo = await db;

    //cprint('update formData $formData');

    //register changes in Upd table
    List<String> oldWashers = [];
    var washerRows =
        await findAll('wash_user', where: 'wash_id=${formData['id']}');
    washerRows.forEach((row) {
      oldWashers.add(row['user_id'].toString());
    });

    var row = await findAll('wash',
        where: 'id=${formData['id']}',
        fields: 'category_id,plate,service_id,phone,marka');
    Map<String, dynamic> oldVals = row[0];

    Batch batch = dbo.batch();

    oldWashers.forEach((e) {
      if (!washers.contains(e)) {
        batch.insert('upd', {
          'wash_id': formData['id'],
          'field': 'wash_use',
          'old_value': prov.washersMap[int.parse(e)]!['name'],
          'new_value': 'удалено',
          'created_by': session.getInt('userId'),
          'created_at': ts,
          'updated_at': ts
        });
      }
    });

    washers.forEach((e) {
      if (!oldWashers.contains(e)) {
        batch.insert('upd', {
          'wash_id': formData['id'],
          'field': 'wash_us',
          'new_value': prov.washersMap[int.parse(e)]!['name'],
          'old_value': 'добавлено',
          'created_by': session.getInt('userId'),
          'created_at': ts,
          'updated_at': ts
        });
      }
    });

    oldVals.forEach((field, oldVal) {
      if (formData.containsKey(field) &&
          formData[field].toString() != oldVal.toString() &&
          formData[field] != '---') {
        //cprint('updating $field ${formData[field]}!=$oldVal');
        batch.insert('upd', {
          'wash_id': formData['id'],
          'field': field,
          'old_value': oldVal,
          'new_value': formData[field],
          'created_by': session.getInt('userId'),
          'created_at': ts,
          'updated_at': ts
        });
      }
    });

    batch
        .update("wash", formData, where: 'id = ?', whereArgs: [formData['id']]);

    batch.delete('wash_user', where: 'wash_id=?', whereArgs: [formData['id']]);
    washers.forEach((uid) {
      batch.insert("wash_user", {'wash_id': formData['id'], 'user_id': uid});
    });

    int fourty = (int.parse(formData['price']) * 0.4).round();
    int eachGets = (fourty / washerCount).round();

    batch.update("wash_user", {'wage': eachGets},
        where: 'wash_id = ?', whereArgs: [formData['id']]);

    await batch.commit();

    /* washers.forEach((uid) {
      dbo.insert(
          "wash_user", {'wash_id': washId, 'user_id': uid});
    }); */
    //cprint('wash updated ${formData['id']}');

    return formData;
  }

  void finishWash(int id, int finishedAt, int duration, int durStatus) async {
    Map<String, dynamic> formData = {};

    formData['finished_at'] = finishedAt;
    formData['updated_at'] = finishedAt;
    formData['tags'] = session.getString('deviceId');
    formData['duration'] = duration;
    formData['duration_status'] = durStatus;

    var dbo = await db;
    dbo.update("wash", formData, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> washPaid(Wash wash) async {
    int ts = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    int fourty = (wash.price * 0.4).round();
    int washerCount = wash.washerIds.length;
    int eachGets = (fourty / washerCount).round();
    var dbo = await db;

    dbo.update("wash",
        {'paid': 1, 'updated_at': ts, 'tags': session.getString('deviceId')},
        where: 'id = ?', whereArgs: [wash.id]);
    dbo.update("wash_user", {'wage': eachGets},
        where: 'wash_id = ?', whereArgs: [wash.id]);
  }

  Future<List<Map<String, dynamic>>> findAllWashes(RootProvider prov) async {
    var dbo = await db;
    if (!dbo.isOpen) {
      //cprint('db is not open findAllWashes');
      sleep(const Duration(seconds: 1));
    }
    String sql = "SELECT * FROM wash WHERE id > 0";
    if (prov.queryPlate != '') {
      sql += " AND plate='${prov.queryPlate}'";
    } else {
      DateTime now = DateTime.now();
      DateTime fromDate = DateTime(now.year, now.month, now.day);
      if (prov.showListFromDate != null) {
        fromDate = DateTime.parse(prov.showListFromDate!);
      }
      int fromTS = (fromDate.millisecondsSinceEpoch / 1000).round();

      DateTime toDate = fromDate.add(Duration(days: 1));
      int toTS = (toDate.millisecondsSinceEpoch / 1000).round();

      sql +=
          " AND started_at >= $fromTS AND started_at < $toTS ORDER BY started_at DESC";
    }
    /* sql += " LIMIT 25";
    if (prov.xCurrentPage > 0) {
      int offset = (prov.xCurrentPage) * 25;
      sql += " OFFSET $offset";
    }
    cprint('currentPagE ${prov.xCurrentPage}, findAll sql $sql'); */
    var res = await dbo.rawQuery(sql);
    return res;
  }

  Future<List<Map<String, dynamic>>> findAllDay(String? date) async {
    var dbo = await db;
    if (!dbo.isOpen) {
      //cprint('db is not open findAllDay');
      sleep(const Duration(seconds: 1));
    }
    String sql =
        "SELECT wash.id,price,paid,wash_user.user_id,wage FROM wash LEFT JOIN wash_user ON wash.id=wash_user.wash_id";
    DateTime now = DateTime.now();
    DateTime fromDate = DateTime(now.year, now.month, now.day);
    if (date != null) {
      fromDate = DateTime.parse(date);
    }
    int fromTS = (fromDate.millisecondsSinceEpoch / 1000).round();

    DateTime toDate = fromDate.add(Duration(days: 1));
    int toTS = (toDate.millisecondsSinceEpoch / 1000).round();

    sql += " WHERE started_at >= $fromTS AND started_at < $toTS";
    sql += " ORDER BY started_at DESC";

    var res = await dbo.rawQuery(sql);

    //cprint('findAllDay res $res');
    return res;
  }

  void deleteOldWashes() {
    DateTime today = new DateTime.now();
    DateTime fourDaysAgo = today.subtract(new Duration(days: 4));
    int toTS = (fourDaysAgo.millisecondsSinceEpoch / 1000).round();
    deleteAll('wash', where: 'started_at < $toTS');
  }

  Future<List<Map<String, dynamic>>> findWashUsers(int washId) async {
    var dbo = await db;
    return await dbo
        .rawQuery("SELECT * FROM wash_user WHERE wash_id = $washId");
  }

  Future<List<Map<String, dynamic>>> standartDuration(Wash wash) async {
    var dbo = await db;
    String sql =
        "SELECT duration FROM `price` WHERE service_id=${wash.serviceId} AND category_id=${wash.categoryId}";
    return await dbo.rawQuery(sql);
  }

  Future<List<Map<String, dynamic>>> findAll(String tbl,
      {String? where, String? fields, int? limit}) async {
    var dbo = await db;
    if (dbo.isOpen) {
      //cprint('db is not open findAll');
      //sleep(const Duration(seconds: 1));

      if (fields == null) {
        fields = '*';
      }
      String sql = "SELECT $fields FROM $tbl";
      if (where != null) {
        sql += " WHERE " + where;
      }
      if (limit != null) {
        sql += " LIMIT $limit";
      }
      var res = await dbo.rawQuery(sql);
      return res;
    }
    return [];
  }

  Future<int?> count(String tbl, {String? where}) async {
    var dbo = await db;
    if (dbo.isOpen) {
      String sql = "SELECT COUNT(*) as cnt FROM $tbl";
      if (where != null) {
        sql += " WHERE " + where;
      }
      List<Map<String, dynamic>> res = await dbo.rawQuery(sql);
      return res[0]['cnt'];
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> findUpd(int washId) async {
    var dbo = await db;
    String sql =
        "SELECT upd.*, user.username FROM upd LEFT JOIN user ON upd.created_by = user.server_id WHERE upd.wash_id=$washId";
    var res = await dbo.rawQuery(sql);
    return res;
  }

  truncate(String tbl) async {
    var dbo = await db;
    await dbo.rawQuery("DELETE FROM $tbl");
  }

  Future<void> import(String tbl, List insMapList) async {
    //cprint('$tbl importing $insMapList');
    var dbo = await db;
    insMapList.forEach((insMap) async {
      Map<String, dynamic> data = prepareData(tbl, insMap);
      int serverId;
      if (insMap['id'] is int) {
        serverId = insMap['id'];
      } else {
        serverId = int.parse(insMap['id']);
      }

      var localId = await checkLocal(tbl, serverId);
      if (localId != 0) {
        await dbo.update(tbl, data, where: 'id = ?', whereArgs: [localId]);
      } else {
        await dbo.insert(tbl, data);
      }
    });
  }

  Map<String, dynamic> prepareData(String tbl, Map insMap) {
    Map<String, dynamic> data = {
      'server_id': insMap['id'],
      'updated_server': insMap['updated_at']
    };
    if (tbl == 'test') {
      data['name'] = insMap['title'];
    } else if (tbl == 'category') {
      data['title'] = insMap['title'];
      data['ctg_num'] = insMap['ctg_num'];
    } else if (tbl == 'price') {
      data['service_id'] = insMap['service_id'];
      data['category_id'] = insMap['category_id'];
      data['price'] = insMap['price'];
      data['duration'] = insMap['duration'];
      data['service'] = insMap['service'];
      data['category'] = insMap['category'];
    } else if (tbl == 'service') {
      data['title'] = insMap['title'];
      data['weight'] = insMap['weight'];
    } else if (tbl == 'user') {
      data['username'] = insMap['username'];
      data['in_service'] = insMap['in_service'];
    }

    return data;
  }

  void importDeleted(List insMapList) async {
    //cprint('deleted importing $insMapList');
    var dbo = await db;
    insMapList.forEach((insMap) async {
      if (insMap['category_id'] != null) {
        await dbo.delete('category',
            where: 'server_id= ?', whereArgs: [insMap['category_id']]);
      } else if (insMap['service_id'] != null) {
        await dbo.delete('service',
            where: 'server_id= ?', whereArgs: [insMap['service_id']]);
      } else if (insMap['price_id'] != null) {
        await dbo.delete('price',
            where: 'server_id= ?', whereArgs: [insMap['price_id']]);
      } else if (insMap['wash_id'] != null) {
        await dbo.delete('wash',
            where: 'server_id= ?', whereArgs: [insMap['wash_id']]);
      }
      insMap['server_id'] = insMap['id'];
      insMap.remove('id');
      await dbo.insert('deleted', insMap);
    });
  }

  void deleteAll(String tbl, {String? where}) async {
    var dbo = await db;
    dbo.delete(tbl, where: where);
  }

  //check if exist
  Future<int> checkLocal(String tbl, int serverId) async {
    var dbo = await db;
    List res = await dbo
        .rawQuery("SELECT id FROM $tbl WHERE server_id=$serverId LIMIT 1");
    if (res.isNotEmpty) {
      //cprint('checkLocal ${res[0]['id']}');
      return res[0]['id'];
    }
    return 0;
  }

  Future<int> getMaxTimestamp(String table) async {
    var dbo = await db;
    if (dbo.isOpen) {
      //cprint('db is not open getMaxTimestamp');
      //sleep(const Duration(seconds: 1));

      String sql;

      sql = "SELECT MAX(updated_server) AS upd_serv FROM $table";
      if (table == 'deleted') {
        sql = "SELECT MAX(server_id) AS upd_serv FROM deleted";
      }

      List<Map<String, dynamic>> result = await dbo.rawQuery(sql);
      if (result.length == 0) {
        //cprint('db result.length is 0');
        return 0;
      }

      //cprint('db $table result max upd: ${result[0]['upd_serv']}');
      if (result[0]['upd_serv'] == null) {
        return 0;
      }
      return result[0]['upd_serv'];
    }
    return 0;
  }

  Future<int> getMaxServerId(String table) async {
    var dbo = await db;
    if (dbo.isOpen) {
      List<Map<String, dynamic>> result =
          await dbo.rawQuery("SELECT MAX(server_id) FROM $table");
      if (result.length == 0) {
        //cprint('db result.length is 0');
        return 0;
      }

      //cprint('db $table result max upd: ${result[0]['upd_serv']}');
      if (result[0]['server_id'] == null) {
        return 0;
      }
      return result[0]['server_id'];
    }
    return 0;
  }

  _onCreate(Database dba, int version) async {
    await dba.transaction((txn) async {
      await txn.execute(
          'CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER NULL, num REAL NULL)');
      await txn.execute('''
      create table wash (
        id integer primary key autoincrement,
        server_id integer null,
        category_id integer not null,
        plate text null,
        user_id integer not null,
        started_at integer not null,
        finished_at integer null,
        updated_at integer null,
        updated_server integer null,
        updated_by integer null,
        duration integer null,
        price integer not null,
        paid integer null,
        service_id integer not null,
        photo text null,
        photo_local text null,
        comment text null,
        duration_status integer null,
        phone text null,
        marka text null,
        tags text null
       )''');
      await txn.execute('''
      create table wash_user (
        id integer primary key autoincrement,
        wash_id integer not null REFERENCES wash(id) ON DELETE CASCADE,
        user_id integer not null,
        wage integer null
       )''');
      await txn.execute('''
      create table category (
        id integer primary key autoincrement,
        server_id integer null,
        title text not null,
        ctg_num integer not null,
        updated_at integer null,
        updated_server integer null
       )''');
      await txn.execute('''
      create table price (
        id integer primary key autoincrement,
        server_id integer null,
        category_id integer null,
        service_id integer null,
        price integer not null,
        duration integer null,
        updated_at integer null,
        updated_server integer null,
        category text null,
        service text null
       )''');
      await txn.execute('''
      create table deleted (
        id integer primary key autoincrement,
        server_id integer null,
        category_id integer null,
        service_id integer null,
        price_id integer null,
        wash_id integer null,
        upd_id integer null,
        synced integer default 0
       )''');
      await txn.execute('''
      create table service (
        id integer primary key autoincrement,
        server_id integer null,
        title text not null,
        weight integer null,
        updated_at integer null,
        updated_server integer null
       )''');
      await txn.execute('''
      create table upd (
        id integer primary key autoincrement,
        server_id integer null,
        wash_id integer not null REFERENCES wash(id) ON DELETE CASCADE,
        created_at integer null,
        created_by integer null,
        field text null,
        old_value text null,
        new_value text null,
        updated_at integer null,
        updated_server integer null
       )''');
      await txn.execute('''
      create table user (
        id integer primary key autoincrement,
        server_id integer null,
        username text not null,
        auth_key text null,
        in_service integer default 1 not null,
        updated_server integer null,
        updated_at integer null
       )''');
      await txn.execute('''
      create table wash_service (
        id integer primary key autoincrement,
        server_id integer null,
        wash_id integer not null REFERENCES wash(id) ON DELETE CASCADE,
        service_id integer not null,
        updated_at integer null,
        updated_server integer null
       )''');
    });
  }

  _onUpgrade(Database dba, int oldVersion, int newVersion) async {
    if (newVersion == 7) {
      await dba.transaction((txn) async {
        await txn.execute('DROP TABLE user');
        await txn.execute('''
      create table user (
        id integer primary key autoincrement,
        server_id integer null,
        username text not null,
        auth_key text null,
        in_service integer default 1 not null,
        updated_server integer null,
        updated_at integer null
       )''');
      });
    }
    if (newVersion == 2) {
      await dba.transaction((txn) async {
        await txn.execute('ALTER TABLE wash ADD tags text null');
      });
    }
  }

  _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  dropDb() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "db1.db");
    await deleteDatabase(path);
  }
}
