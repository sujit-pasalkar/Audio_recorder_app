import 'package:flutter/material.dart';
import 'package:simple_permissions/simple_permissions.dart';

import 'home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp() {
    print('object');
    getPermission();
  }

  Future<String> getPermission() async {
    try {
      final readExternalStorage = await SimplePermissions.requestPermission(
          Permission.ReadExternalStorage);
      print('result readExternalStorage:$readExternalStorage');

      final writeExternalStorage = await SimplePermissions.requestPermission(
          Permission.WriteExternalStorage);
      print('result writeExternalStorage : $writeExternalStorage');

      final recordAudio =
          await SimplePermissions.requestPermission(Permission.RecordAudio);
      print('result recordAudio : $recordAudio');

       final camera =
          await SimplePermissions.requestPermission(Permission.Camera);
      print('result camera: $camera');

      return "result";
    } catch (e) {
      print('error in getPermission:$e');
      return e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}
