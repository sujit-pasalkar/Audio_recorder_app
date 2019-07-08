import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_permissions/simple_permissions.dart';
// import 'package:fluttertoast/fluttertoast.dart';

class Recording extends StatefulWidget {
  @override
  _RecordingState createState() => _RecordingState();
}

class _RecordingState extends State<Recording> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Directory dir;
  String defaultPath;
  StorageReference firebaseStorageRef;
  bool isLoading = false;

  FlutterSound _flutterSound;
  bool _isRecording = false;
  bool _isPlaying = false;
  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';
  StreamSubscription _recorderSubscription;
  StreamSubscription _dbPeakSubscription;
  StreamSubscription _playerSubscription;
  double _dbLevel;
  double slider_current_position = 0.0;
  double max_duration = 1.0;

  @override
  void initState() {
    _flutterSound = new FlutterSound();
    _flutterSound.setSubscriptionDuration(0.01);
    _flutterSound.setDbPeakLevelUpdate(0.8);
    _flutterSound.setDbLevelEnabled(true);
    initializeDateFormatting();
    getDir();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  getDir() async {
    dir = await getApplicationDocumentsDirectory();
    if (File('storage/emulated/0/default.m4a').existsSync()) {
      defaultPath = 'storage/emulated/0/default.m4a';
    } else {
      defaultPath = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              elevation: 0.0,
              backgroundColor: Colors.blueAccent,
            ),
            body: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      color: Colors.blueAccent,
                      width: double.maxFinite,
                      height: (MediaQuery.of(context).size.height / 2) + 30,
                      child: Column(
                        children: <Widget>[
                          SafeArea(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                _recorderTxt,
                                style: TextStyle(
                                    fontSize: 40, color: Colors.white),
                              ),
                            ),
                          ),
                          File('storage/emulated/0/default.m4a').existsSync() &&
                                  !_isRecording
                              ? Container(
                                  margin: EdgeInsets.only(top: 20),
                                  width: double.maxFinite,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        Color(0xffb578de3),
                                        // Color(0xffb4fcce0),
                                        Color(0xffb1976d2)
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Icon(
                                              Icons.keyboard_voice,
                                              color: Colors.white,
                                            ),
                                            Text(
                                              'Last recorded..',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white),
                                              textAlign: TextAlign.center,
                                            ),
                                            Text(
                                              _playerTxt,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.white),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Slider(
                                          value: slider_current_position,
                                          min: 0.0,
                                          max: max_duration,
                                          activeColor: Colors.white,
                                          inactiveColor: Color(0xffb4fcce0),
                                          onChanged: (double value) async {
                                            await _flutterSound
                                                .seekToPlayer(value.toInt());
                                          },
                                          divisions: max_duration.toInt()),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 1.0,
                                            left: 60,
                                            right: 60,
                                            bottom: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: <Widget>[
                                            GestureDetector(
                                              onTap: () {
                                                print('start');
                                                startPlayer();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white),
                                                child: Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.blueAccent,
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: _isPlaying
                                                  ? () {
                                                      print('pause and resume');
                                                      pausePlayer();
                                                    }
                                                  : () {
                                                      startPlayer();
                                                    },
                                              child: Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white),
                                                child: Icon(
                                                  Icons.pause,
                                                  color: Colors.blueAccent,
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                print('stop');
                                                stopPlayer();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white),
                                                child: Icon(
                                                  Icons.stop,
                                                  color: Colors.blueAccent,
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: (MediaQuery.of(context).size.height / 2) - 30,
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 35.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              GestureDetector(
                                onTap: _isRecording
                                    ? () {
                                        stopRecorder();
                                      }
                                    : () async {
                                        if (File(
                                                'storage/emulated/0/default.m4a')
                                            .existsSync()) {
                                          savePreviousAlert();
                                        } else
                                          startRecorder();
                                      },
                                child: Container(
                                  padding: EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blueAccent),
                                  child: Icon(
                                    _isRecording
                                        ? Icons.stop
                                        : Icons.keyboard_voice,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                File('storage/emulated/0/default.m4a').existsSync() &&
                        !_isRecording
                    ? Positioned(
                        left: 10,
                        top: (MediaQuery.of(context).size.height / 2) + 5,
                        child: SizedBox(
                          width: 130.0,
                          height: 50.0,
                          child: RaisedButton.icon(
                            icon: Icon(
                              Icons.add,
                              size: 35,
                            ),
                            label: Text(
                              'Save',
                              style: TextStyle(fontSize: 20),
                            ),
                            textColor: Colors.white,
                            color: Color(0xffb4fcce0),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0)),
                            onPressed: () async {
                              try {
                                await uploadRecordings();
                                setState(() {
                                  isLoading = false;
                                  defaultPath = '';
                                  _playerTxt = '00:00:00';
                                  _recorderTxt = '00:00:00';
                                });
                                Navigator.pop(context);
                              } catch (e) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                          ),
                        ),
                      )
                    : SizedBox(),
                File('storage/emulated/0/default.m4a').existsSync() &&
                        !_isRecording
                    ? Positioned(
                        right: 10,
                        top: (MediaQuery.of(context).size.height / 2) + 5,
                        child: SizedBox(
                          width: 130.0,
                          height: 50.0,
                          child: RaisedButton.icon(
                            icon: Icon(
                              Icons.delete,
                              size: 35,
                            ),
                            label: Text(
                              'Delete',
                              style: TextStyle(fontSize: 20),
                            ),
                            textColor: Colors.white,
                            color: Color(0xffb4fcce0),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0)),
                            onPressed: () {
                              deleteRecordAlert();
                            },
                          ),
                        ),
                      )
                    : SizedBox()
              ],
            ),
          ),
          isLoading
              ? Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : SizedBox()
        ],
      ),
      onWillPop: _onBackPress,
    );
  }

  savePreviousAlert() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Save previous Recording ?'),
            content: Text('save or discard previous recording.',
                style: TextStyle(color: Colors.grey)),
            actions: <Widget>[
              FlatButton(
                child: Text('SAVE',
                    style: TextStyle(
                      color: Color(0xffb00bae3),
                    )),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await uploadRecordings();
                    setState(() {
                      isLoading = false;
                      // defaultPath = '';
                    });
                  } catch (e) {
                    setState(() {
                      isLoading = false;
                    });
                  }
                  startRecorder();
                },
              ),
              FlatButton(
                child: Text('DISCARD',
                    style: TextStyle(
                      color: Color(0xffb00bae3),
                    )),
                onPressed: () async {
                  final writeExternalStorage =
                      await SimplePermissions.checkPermission(
                          Permission.WriteExternalStorage);
                  print('result writeExternalStorage : $writeExternalStorage');

                  if (!writeExternalStorage) {
                    final writeExternalStorage =
                        await SimplePermissions.requestPermission(
                            Permission.WriteExternalStorage);
                    print(
                        'result writeExternalStorage : $writeExternalStorage');
                  } else {
                    File('storage/emulated/0/default.m4a').deleteSync();
                    setState(() {});
                    startRecorder();
                    Navigator.pop(context);
                  }
                },
              )
            ],
          );
        });
  }

  void deleteRecordAlert() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Delete Recording ?'),
            content: Text('This record will be removed permanently.',
                style: TextStyle(color: Colors.grey)),
            actions: <Widget>[
              FlatButton(
                child: Text('CANCEL',
                    style: TextStyle(
                      color: Color(0xffb00bae3),
                    )),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text('REMOVE',
                    style: TextStyle(
                      color: Color(0xffb00bae3),
                    )),
                onPressed: () async {
                  final writeExternalStorage =
                      await SimplePermissions.checkPermission(
                          Permission.WriteExternalStorage);
                  print('result writeExternalStorage : $writeExternalStorage');

                  if (!writeExternalStorage) {
                    final writeExternalStorage =
                        await SimplePermissions.requestPermission(
                            Permission.WriteExternalStorage);
                    print(
                        'result writeExternalStorage : $writeExternalStorage');
                  } else {
                    File('storage/emulated/0/default.m4a').deleteSync();
                    setState(() {
                      _playerTxt = '00:00:00';
                      _recorderTxt = '00:00:00';
                    });
                    Navigator.pop(context);
                  }
                },
              )
            ],
          );
        });
  }

  Future<bool> _onBackPress() {
    if (isLoading) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('please wait..'), duration: Duration(seconds: 1)));
    } else {
      if (_isRecording) {
        stopRecorder();
      }
      if (_isPlaying) {
        stopPlayer();
      }
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  void startRecorder() async {
    try {
      defaultPath = await _flutterSound.startRecorder(null);
      print('startRecorder: $defaultPath');

      _recorderSubscription = _flutterSound.onRecorderStateChanged.listen((e) {
        print('e:${e.currentPosition.toInt()}');
        if (e.currentPosition.toInt().toString().length < 7) {
          DateTime date = DateTime.fromMillisecondsSinceEpoch(
              e.currentPosition.toInt(),
              isUtc: true);
          String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
          print('txt:$txt');
          print(txt.substring(0, 8));

          this.setState(() {
            this._recorderTxt = txt.substring(0, 8);
          });
          print('this._recorderTxt : ${this._recorderTxt}');
        }
      });

      _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Recording started.'), duration: Duration(seconds: 1)));
      //  Fluttertoast.showToast(msg: 'Recording started.');

      _dbPeakSubscription =
          _flutterSound.onRecorderDbPeakChanged.listen((value) {
        print("got update -> $value");
        setState(() {
          this._dbLevel = value;
        });
      });

      this.setState(() {
        this._isRecording = true;
      });
    } catch (e) {
      print('startRecorder error: $e');
    }
  }

  void stopRecorder() async {
    try {
      String result = await _flutterSound.stopRecorder();
      print('stopRecorder: $result');

      if (_recorderSubscription != null) {
        _recorderSubscription.cancel();
        _recorderSubscription = null;
      }
      if (_dbPeakSubscription != null) {
        _dbPeakSubscription.cancel();
        _dbPeakSubscription = null;
      }

      this.setState(() {
        this._isRecording = false;
        // _recorderTxt = '00:00:00';
      });
      _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Recording stoped.'), duration: Duration(seconds: 1)));
      //  Fluttertoast.showToast(msg: 'Recording stopped.');

      print('recorded path: $defaultPath');
    } catch (err) {
      print('stopRecorder error: $err');
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Something went wrong'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future uploadRecordings() async {
    Completer _c = new Completer();
    setState(() {
      isLoading = true;
    });
    try {
      // print('default file: $defaultPath'); //storage/emulated/0/default.m4a
      // print(
      //     'put in :${dir.path}'); //data/user/0/com.example.recording_app/app_flutter

      int timestamp = DateTime.now().millisecondsSinceEpoch;
      File oldFile = File(defaultPath);
      // print('oldFile: ${oldFile.path}');

      File newFile = File('${dir.path}/${timestamp.toString()}.m4a');
      newFile.createSync(recursive: true);
      oldFile.copy(newFile.path);
      oldFile.delete();
      // print('newFile exist: ${newFile.existsSync()}');

      // now upload to firebase storage
      firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('recordings')
          .child('$timestamp.m4a');

      StorageUploadTask uploadTask = firebaseStorageRef.putFile(
        newFile,
        StorageMetadata(
          contentType: 'audio/m4a',
          customMetadata: <String, String>{'file': 'audio'},
        ),
      );

      String firebaseUrl =
          await (await uploadTask.onComplete).ref.getDownloadURL();

      //put in firestore
      var documentReference = Firestore.instance
          .collection('Recordings')
          .document(timestamp.toString());

      Firestore.instance.runTransaction((transactionHandler) async {
        await transactionHandler.set(documentReference,
            {'downloadUrl': firebaseUrl, 'timestamp': timestamp.toString()});
      }).then((onValue) {
        print('added in firestore');
        _c.complete(firebaseUrl);
      });
    } catch (e) {
      _c.completeError(e);
    }
    return _c.future;
  }

  // player
  void startPlayer() async {
    try {
      final recordAudio =
          await SimplePermissions.checkPermission(Permission.RecordAudio);
      print('result writeExternalStorage : $recordAudio');

      if (!recordAudio) {
        final result =
            await SimplePermissions.requestPermission(Permission.RecordAudio);
        print('result writeExternalStorage : $result');
      } else {
        String path = await _flutterSound.startPlayer(null);
        await _flutterSound.setVolume(1.0);
        print('startPlayer: $path');

        _playerSubscription = _flutterSound.onPlayerStateChanged.listen((e) {
          if (e != null) {
            slider_current_position = e.currentPosition;
            max_duration = e.duration;

            DateTime date = new DateTime.fromMillisecondsSinceEpoch(
                e.currentPosition.toInt(),
                isUtc: true);
            String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
            this.setState(() {
              this._isPlaying = true;
              this._playerTxt = txt.substring(0, 8);
            });
          } else {
            setState(() {
              this._isPlaying = true;
            });
          }
        });
      }
    } catch (err) {
      print('start player error: $err');
      stopPlayer();
    }
  }

  void stopPlayer() async {
    try {
      String result = await _flutterSound.stopPlayer();
      print('stopPlayer: $result');
      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }

      this.setState(() {
        this._isPlaying = false;
      });
    } catch (err) {
      print('error: $err');
    }
  }

  void pausePlayer() async {
    String result = await _flutterSound.pausePlayer();
    print('pausePlayer: $result');
  }

  void resumePlayer() async {
    String result = await _flutterSound.resumePlayer();
    print('resumePlayer: $result');
  }

  void seekToPlayer(int milliSecs) async {
    String result = await _flutterSound.seekToPlayer(milliSecs);
    print('seekToPlayer: $result');
  }
}
