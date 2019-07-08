import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
// import 'package:recording_app/scanner.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'qrCode.dart';
import 'recording.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
// scanner
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController _scrollController = ScrollController();
  List<dynamic> recordings = [];
  Directory directory;
  StorageReference ref;

  // player
  FlutterSound _flutterSound;
  StreamSubscription _playerSubscription;
  // double _dbLevel;
  double slider_current_position = 0.0;
  double max_duration = 1.0;
  bool _isPlaying = false;
  String _playerTxt = '00:00:00';

  @override
  void initState() {
    _flutterSound = new FlutterSound();
    _flutterSound.setSubscriptionDuration(0.01);
    _flutterSound.setDbPeakLevelUpdate(0.8);
    _flutterSound.setDbLevelEnabled(true);
    initializeDateFormatting();
    dir();
    super.initState();
  }

  dir() async {
    directory = await getApplicationDocumentsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Recordings'),
        ),
        body: _isPlaying
            ? Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xffb578de3), Color(0xffb1976d2)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.keyboard_voice,
                            color: Colors.white,
                          ),
                          Text(
                            _playerTxt,
                            style: TextStyle(fontSize: 20, color: Colors.white),
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
                          await _flutterSound.seekToPlayer(value.toInt());
                        },
                        divisions: max_duration.toInt()),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 1.0, left: 60, right: 60, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              print('start');
                              // playRecording();
                            },
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.white),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.blueAccent,
                                size: 30,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              print('pause and resume');
                              pausePlayer();
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.white),
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
                                  shape: BoxShape.circle, color: Colors.white),
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
            : StreamBuilder<QuerySnapshot>(
                stream: Firestore.instance.collection('Recordings').snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError)
                    return Text('Error: ${snapshot.error}');

                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Center(
                          child: CircularProgressIndicator(
                              valueColor: new AlwaysStoppedAnimation<Color>(
                                  Color(0xffb00bae3))));
                    default:
                      return ListView.builder(
                        itemCount: snapshot.data.documents.length,
                        controller: _scrollController,
                        itemBuilder: (context, index) {
                          return Column(
                            children: <Widget>[
                              ListTile(
                                onTap: () async {
                                  print(
                                      '${snapshot.data.documents[index].data}');
                                  print('extenal directory: $directory');
                                  File chk = File(directory.path +
                                      '/${snapshot.data.documents[index].data['timestamp']}.m4a');
                                  if (chk.existsSync()) {
                                    print('file exist: ${chk.path}');
                                    playRecording(chk);
                                  } else {
                                    print('file not exist: ${chk.path}');
                                    try {
                                      await downloadRecording(
                                          chk,
                                          snapshot.data.documents[index]
                                              .data['timestamp']);
                                      print(
                                          '${snapshot.data.documents[index].data['timestamp']}:File downloded succeessfully.');
                                      //now play
                                      playRecording(chk);
                                    } catch (e) {
                                      print('download error:$e');
                                    }
                                  }
                                },
                                leading: Icon(Icons.keyboard_voice),
                                title: Text('Recording ${index + 1}'),
                                subtitle: Text(
                                  '${DateTime.fromMillisecondsSinceEpoch(int.parse(snapshot.data.documents[index].data['timestamp'])).toString()}',
                                  textAlign: TextAlign.left,
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.center_focus_strong),
                                  onPressed: () {
                                    if (_isPlaying) {
                                      stopPlayer();
                                    }
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                QrCode(
                                                    songTimestamp: snapshot
                                                        .data
                                                        .documents[index]
                                                        .data['timestamp'])));
                                  },
                                ),
                              ),
                              Divider(
                                height: 0.0,
                                indent: 60,
                              )
                            ],
                          );
                        },
                      );
                  }
                },
              ),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(left: 25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FloatingActionButton.extended(
                heroTag: "record",
                icon: Icon(
                  Icons.keyboard_voice,
                  size: 30,
                ),
                label: Text('New Record'),
                onPressed: () {
                  print('go to record page');
                  if (_isPlaying) {
                    stopPlayer();
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => Recording()));
                },
              ),
              FloatingActionButton(
                heroTag: "scan",
                child: Icon(
                  Icons.center_focus_strong,
                  size: 40,
                ),
                onPressed: () {
                  print('go to scan page');
                  if (_isPlaying) {
                    stopPlayer();
                  }
                  scan();
                },
              ),
            ],
          ),
        ),
      ),
      onWillPop: _onBackPress,
    );
  }

  Future<bool> _onBackPress() {
    if (_isPlaying) {
      stopPlayer();
    }

    return Future.value(false);
  }

  Future downloadRecording(File file, String timestamp) async {
    Completer _c = new Completer();
    try {
      await file.create(recursive: true);
      print('newFile:created');

      ref = FirebaseStorage.instance
          .ref()
          .child('recordings')
          .child(timestamp + ".m4a");

      final StorageFileDownloadTask downloadTask = ref.writeToFile(file);

      downloadTask.future.then((onData) {
        print(onData.totalByteCount);
      });

      downloadTask.future.whenComplete(() {
        _c.complete(true);
      });
    } catch (e) {
      _c.completeError(e);
    }
    return _c.future;
  }

  void playRecording(File file) async {
    try {
      String path = await _flutterSound.startPlayer(file.path);
      await _flutterSound.setVolume(1.0);
      if (path == 'player is already running.') {
        print('hjhjhj');
      }
      print('startPlayer: $path');

      _playerSubscription = _flutterSound.onPlayerStateChanged.listen((e) {
        if (e != null) {
          slider_current_position = e.currentPosition;
          max_duration = e.duration;

          DateTime date = new DateTime.fromMillisecondsSinceEpoch(
              e.currentPosition.toInt(),
              isUtc: true);
          String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
          // if(){

          // }
          this.setState(() {
            this._isPlaying = true;
            this._playerTxt = txt.substring(0, 8);
          });
        } else {
          // stopPlayer();
          this.setState(() {
            this._isPlaying = false;
          });
        }
      });
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

  // scanner
  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      // setState(() => this.barcode = barcode);
      _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('scanned succeessfull.'),
          duration: Duration(seconds: 1)));
      // play song
      playScannedSong(barcode);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        // setState(() {
        //   this.barcode = 'The user did not grant the camera permission!';
        // });
        _scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text('The user did not grant the camera permission!'),
            duration: Duration(seconds: 1)));
      } else {
        // setState(() => this.barcode = 'Unknown error: $e');
        _scaffoldKey.currentState.showSnackBar(SnackBar(
            content: Text('Unknown error: $e'),
            duration: Duration(seconds: 1)));
      }
    } on FormatException {
      // setState(() => this.barcode =
      //     'null (User returned using the "back"-button before scanning anything. Result)');
      _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
              'User returned using the "back"-button before scanning anything. Result'),
          duration: Duration(seconds: 1)));
    } catch (e) {
      // setState(() => this.barcode = 'Unknown error: $e');
      _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Unknown error: $e'), duration: Duration(seconds: 1)));
    }
  }

  playScannedSong(String timestamp) async {
    try {
      print(timestamp);
      print('extenal directory: $directory');
      File chk = File(directory.path + '/$timestamp.m4a');
      if (chk.existsSync()) {
        print('file exist: ${chk.path}');
        playRecording(chk);
      } else {
        print('file not exist: ${chk.path}');
        try {
          await downloadRecording(chk, timestamp);
          print('$timestamp:File downloded succeessfully.');
          //now play
          playRecording(chk);
        } catch (e) {
          print('download error:$e');
        }
      }
    } catch (e) {
      print('error playScannedSong:$e');
    }
  }
}
