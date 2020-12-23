import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:carwash/resources/provider.dart';
import 'package:carwash/resources/washModel.dart';
//import 'washView.dart';
import 'package:carwash/resources/session.dart';
import 'package:carwash/resources/endpoints.dart';

class WashForm extends StatefulWidget {
  final int id;
  WashForm(this.id);

  @override
  _WashFormState createState() => _WashFormState();
}

class _WashFormState extends State<WashForm> {
  RootProvider prov;
  final TextEditingController _plateTC = new TextEditingController();
  final TextEditingController _commentTC = new TextEditingController();
  final TextEditingController _phoneTC = new TextEditingController();
  final TextEditingController _markaTC = new TextEditingController();
  Wash wash;
  int id;
  final picker = ImagePicker();
  String saveBtnText = 'Начать';
  String mode = 'insert';
  String appBarTitle = 'Новая мойка';
  bool canEdit = true;
  FocusNode plateFocus;
  FocusNode phoneFocus;
  FocusNode markaFocus;

  @override
  void initState() {
    super.initState();
    prov = Provider.of<RootProvider>(context, listen: false);
    prov.clearFormMap();
    //prov.populateFromDb(true);
    plateFocus = FocusNode();
    phoneFocus = FocusNode();
    markaFocus = FocusNode();

    if (widget.id != null) {
      mode = 'update';
      id = widget.id;
      wash = prov.washesMap[id];
      _plateTC.text = wash.plate;
      _commentTC.text = wash.comment;
      _phoneTC.text = wash.phone;
      _markaTC.text = wash.marka;
      saveBtnText = 'Сохранить';
      appBarTitle = 'Мойка ID $id ред.';
      prov.washFormMap['category_id'] = wash.categoryId.toString();
      prov.washFormMap['service_id'] = wash.serviceId.toString();
      //cprint('washForm washerIds ${wash.washerIds}');
      prov.updateWashers = wash.washerIds;
      prov.washFormMap['id'] = id;
      prov.formPriceShow = wash.price.toString();

      //not needed if update is to server
      prov.washFormMap['started_at'] = wash.startedAt;
      prov.washFormMap['plate'] = wash.plate;

      int currentTS = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      double passedMinutes = (currentTS - wash.startedAt) / 60;
      if (passedMinutes > 360) {
        canEdit = false; //can edit only withing 6 hours after start
        //cprint('passed $passedMinutes, cur $currentTS, start ${wash.startedAt}');
      } else {
        cprint('can edit');
      }
    } else {
      prov.washFormMap['washers'] = <String>[];
      prov.activeWashers.forEach((am) {
        if (am['service_num'] == '1') {
          prov.washFormMap['washers'].add(am['user_id']);
        }
      });
    }
  }

  @override
  void dispose() {
    plateFocus.dispose();
    phoneFocus.dispose();
    markaFocus.dispose();
    _plateTC.clear();
    _commentTC.clear();
    _phoneTC.clear();
    _markaTC.clear();

    super.dispose();
  }

  Widget build(BuildContext context) {
    if (id == null) {
      //executed once after build is complete, only in create mode
      WidgetsBinding.instance
          .addPostFrameCallback((_) => plateFocus.requestFocus());
    }

    return myScaffold(context, widget.id);
  }

  Widget myScaffold(BuildContext context, int id) {
    return new WillPopScope(
      child: new Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            actions: [Center(child: showPrice(prov)), SizedBox(width: 8.0)],
          ),
          body: theForm(context, id)),
      onWillPop: () async {
        return true;
      },
    );
  }

  Widget ctgRadioList(BuildContext context, RootProvider prov) {
    String inival;
    if (prov.washFormMap.containsKey('category_id')) {
      inival = prov.washFormMap['category_id'];
    }
    List<ListTileTheme> ctgItems = [];
    prov.categories.forEach((map) {
      ctgItems.add(
        ListTileTheme(
          contentPadding: EdgeInsets.all(0),
          child: RadioListTile<String>(
            dense: true,
            title: Text(map['title']),
            value: map['id'],
            groupValue: inival,
            onChanged: canEdit
                ? (String value) {
                    prov.formCtg(value);
                    FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus &&
                        currentFocus.focusedChild != null) {
                      //currentFocus.focusedChild.unfocus();
                      FocusManager.instance.primaryFocus.unfocus();
                    }
                  }
                : null,
          ),
        ),
      );
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ctgItems,
    );
  }

//not used
  Widget ctgDropList(RootProvider prov) {
    List<DropdownMenuItem<String>> ctgItems = [];
    prov.categories.forEach((map) {
      ctgItems.add(DropdownMenuItem<String>(
        value: map['server_id'],
        child: Padding(
          padding: EdgeInsets.only(left: 8.0, right: 8.0),
          child: new Text(map['title']),
        ),
      ));
    });

    String inival;
    if (prov.washFormMap.containsKey('category_id')) {
      inival = prov.washFormMap['category_id'];
    }
    return DropdownButton<String>(
      items: ctgItems,
      hint: const Text('Категория'),
      isExpanded: true,
      /* decoration: InputDecoration(
        labelText: 'Категория',
      ), */
      onChanged: (ctgId) {
        prov.formCtg(ctgId);
      },
      value: inival,
    );
  }

  Widget serviceRadioList(BuildContext context, RootProvider prov) {
    cprint('washFormMap ${prov.washFormMap}');
    String inival;
    if (prov.washFormMap.containsKey('service_id')) {
      inival = prov.washFormMap['service_id'];
    }
    List<ListTileTheme> ctgItems = [];
    prov.services.forEach((map) {
      if (map['parent_id'] == null && map['only_secondary'] == '0') {
        ctgItems.add(
          ListTileTheme(
            contentPadding: EdgeInsets.all(0),
            child: RadioListTile<String>(
              dense: true,
              title: Text(map['title']),
              value: map['id'],
              groupValue: inival,
              onChanged: canEdit
                  ? (String value) {
                      prov.formService2(value);
                      FocusScopeNode currentFocus = FocusScope.of(context);
                      if (!currentFocus.hasPrimaryFocus &&
                          currentFocus.focusedChild != null) {
                        //currentFocus.focusedChild.unfocus();
                        FocusManager.instance.primaryFocus.unfocus();
                      }
                    }
                  : null,
            ),
          ),
        );
      }
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ctgItems,
    );
  }

//not used
  List<Widget> serviceCheckBoxList(RootProvider prov, List<Widget> widList) {
    prov.services.forEach((servMap) {
      var servChange = (bool value) {
        prov.formService(servMap['id'], value);
      };
      if (servMap['id'] == '1') {
        if (prov.selectedServices
            .any((item) => ['2', '3', '4'].contains(item))) {
          servChange = null;
        }
      } else if (servMap['id'] == '2') {
        if (prov.selectedServices
            .any((item) => ['1', '3', '4'].contains(item))) {
          servChange = null;
        }
      } else if (servMap['id'] == '3') {
        if (prov.selectedServices.any((item) => ['1', '2'].contains(item))) {
          servChange = null;
        }
      } else if (servMap['id'] == '4') {
        if (prov.selectedServices.any((item) => ['1', '2'].contains(item))) {
          servChange = null;
        }
      }

      widList.add(
        ListTileTheme(
          contentPadding: EdgeInsets.all(0),
          child: CheckboxListTile(
            dense: true,
            title: new Text(servMap['title']),
            contentPadding: EdgeInsets.all(0.0),
            controlAffinity: ListTileControlAffinity.leading,
            value: prov.selectedServices.contains(servMap['id']),
            onChanged: servChange,
          ),
        ),
      );
    });

    return widList;
  }

  Widget showPrice(RootProvider cons) {
    return Selector<RootProvider, String>(
        selector: (context, prov) => prov.formPriceShow,
        builder: (context, price, child) {
          //cprint('showPrice build');
          if (prov.formPriceShow != null) {
            /* return Container(
        child: Chip(
          label: Text('${prov.formPriceShow} c',
              style: TextStyle(fontSize: 18.0, color: Colors.white)),
          backgroundColor: Colors.blue,
          //padding: EdgeInsets.all(20),
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.0),
      ); */
            return Text('${prov.formPriceShow} c',
                style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow));
          }
          return Container(width: 0.0, height: 0.0);
        });
  }

  void getImage(RootProvider prov) async {
    //cprint('washForm getImage start');
    final pickedFile = await picker.getImage(
        source: ImageSource.camera, maxHeight: 1000.0, maxWidth: 1000.0);
    //cprint('washForm getImage finish');
    //prov.setCameraImg(pickedFile.path);
    //File fixedFile = await fixExifRotation(pickedFile.path);
    //prov.setCameraImg2(fixedFile);

    //cprint('washForm getImageAndSave start');
    File fixedFile = await getImageAndSave(pickedFile.path);
    //cprint('washForm getImageAndSave finish');
    prov.setCameraImg(fixedFile.path);
  }

  Future getImageAndSave(String path) async {
    File image = await FlutterExifRotation.rotateAndSaveImage(path: path);
    return image;
  }

  Widget theForm(BuildContext context, int id) {
    return Consumer<RootProvider>(builder: (context, prov, child) {
      if (prov.categories == null ||
          prov.services == null ||
          prov.washers == null ||
          prov.prices == null) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
      List<Widget> widList = [
        TextField(
          //autofocus: true,
          focusNode: plateFocus,
          controller: _plateTC,
          enabled: canEdit ? true : false,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            UpperCaseTextFormatter(),
          ],
          decoration: InputDecoration(labelText: 'Гос номер'),
          onChanged: (v) {
            prov.washFormMap['plate'] = v;
          },
          onSubmitted: (v) {
            FocusScope.of(context).requestFocus(markaFocus);
          },
        ),
        SizedBox(height: 6.0),
        TextField(
          decoration: InputDecoration(labelText: 'Марка'),
          controller: _markaTC,
          focusNode: markaFocus,
          textInputAction: TextInputAction.next,
          enabled: canEdit ? true : false,
          onChanged: (v) {
            prov.washFormMap['marka'] = v;
          },
          onSubmitted: (v) {
            FocusScope.of(context).requestFocus(phoneFocus);
          },
        ),
        SizedBox(height: 6.0),
        TextField(
          decoration: InputDecoration(labelText: 'Телефон'),
          controller: _phoneTC,
          focusNode: phoneFocus,
          enabled: canEdit ? true : false,
          keyboardType: TextInputType.phone,
          onChanged: (v) {
            prov.washFormMap['phone'] = v;
          },
        ),
        SizedBox(height: 12.0),
        //showPrice(prov)
      ];

//#region Photos
      List<Widget> photosList = [];
      if (wash != null && wash.photo != null) {
        var photos = wash.photo.split(';');
        photos.forEach((path) {
          photosList.add(CachedNetworkImage(
              imageUrl: Endpoints.baseUrl + path, fit: BoxFit.fitHeight));
          photosList.add(SizedBox(width: 3.0));
        });
      }
      if (wash != null && wash.photoLocal != null) {
        var photos = wash.photoLocal.split(';');
        photos.forEach((path) {
          photosList.add(Image.file(File(path), fit: BoxFit.fitHeight));
          photosList.add(SizedBox(width: 3.0));
        });
      }
      if (prov.cameraImgs.isNotEmpty) {
        prov.cameraImgs.forEach((path) {
          photosList.add(Image.file(File(path), fit: BoxFit.fitHeight));
          photosList.add(SizedBox(width: 3.0));
        });
      }

      if (photosList.isNotEmpty) {
        widList.add(
          Container(
            child: Row(children: photosList),
            height: 100.0,
          ),
        );
        widList.add(SizedBox(
          height: 6.0,
        ));
      }
//#endregion

      widList.add(RaisedButton.icon(
        icon: Icon(Icons.camera_alt),
        label: Text('Камера'),
        onPressed: () {
          getImage(prov);
        },
      ));
      widList.add(SizedBox(
        height: 6.0,
      ));
      widList.add(Container(
        child: Text('Категория', style: TextStyle(color: Colors.blue)),
        padding: EdgeInsets.only(top: 16.0),
      ));
      widList.add(ctgRadioList(context, prov));

      widList.add(Container(
        child: Text('Вид услуги', style: TextStyle(color: Colors.blue)),
        padding: EdgeInsets.only(top: 16.0),
      ));

      widList.add(serviceRadioList(context, prov));
      //widList = serviceCheckBoxList(prov, widList);

      widList.add(Container(
        child: Text('Персонал', style: TextStyle(color: Colors.blue)),
        padding: EdgeInsets.only(top: 16.0),
      ));
      prov.washers.forEach((map) {
        bool washerBool = false;
        if (prov.washFormMap.containsKey('washers') &&
            prov.washFormMap['washers'].contains(map['id'])) {
          washerBool = true;
        }
        /* if (mode == 'insert') {
          //washerBool =prov.selectedWashers.contains(map['server_id'].toString());
          prov.activeWashers.forEach((am) {
            if (am['user_id'] == map['id'] && am['service_num'] == '1') {
              washerBool = true;
            }
          });
        } else {
          if (prov.updateWashers == null) {
            washerBool = false;
          } else {
            washerBool =
                prov.updateWashers.contains(map['server_id'].toString());
          }
        } */
        widList.add(
          ListTileTheme(
            contentPadding: EdgeInsets.all(0),
            child: CheckboxListTile(
              dense: true,
              title: new Text(map['username']),
              controlAffinity: ListTileControlAffinity.leading,
              value: washerBool,
              onChanged: canEdit
                  ? (bool value) {
                      prov.formWasher(map['id'], value);
                    }
                  : null,
            ),
          ),
        );
      });

      widList.add(TextField(
        decoration: InputDecoration(labelText: 'Коммент'),
        controller: _commentTC,
        onChanged: (v) {
          prov.washFormMap['comment'] = v;
        },
      ));

      widList.add(SizedBox(
        height: 12.0,
      ));

      Widget btnContent =
          Text(saveBtnText, style: TextStyle(color: Colors.white));
      if (prov.isSubmitting) {
        btnContent = new CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.white));
      }

      if (prov.washFormError != "") {
        widList
            .add(Text(prov.washFormError, style: TextStyle(color: Colors.red)));
      }

      widList.add(FlatButton(
        child: btnContent,
        padding: EdgeInsets.symmetric(vertical: 6.0),
        color: Colors.green,
        onPressed: () {
          Future<int> subm = prov.submit(mode);
          subm.then((id) {
            if (id != null) {
              new Future.delayed(new Duration(milliseconds: 100), () {
                //print('navigate to home');
                /* Route route = MaterialPageRoute(
                    maintainState: false, builder: (cntx) => WashView(id)); */

                //Navigator.of(context).pushReplacement(route);
                if (mode == 'insert') {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } else {
                  Navigator.of(context).pop();
                }
              });
            }
          });
        },
      ));
      return ListView(
        children: widList,
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      );
    });
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text?.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
