import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCode extends StatefulWidget {
  final String songTimestamp;

  QrCode({@required this.songTimestamp});

  @override
  _QrCodeState createState() => _QrCodeState();
}

class _QrCodeState extends State<QrCode> {
  GlobalKey globalKey = GlobalKey();

  @override
  void initState() {
    print('song timestamp:${widget.songTimestamp}');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            RepaintBoundary(
              key: globalKey,
              child: QrImage(
                  data: widget.songTimestamp,
                  size: 200.0,
                  onError: (ex) {
                    print("[QR] ERROR - $ex");
                  }),
            ),
            Padding(
              padding: EdgeInsets.only(top: 100,bottom: 50),
              child: Text(
                'Scan this QR-Code to play recorded Audio.',
                style: TextStyle(color: Colors.grey, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            // SizedBox(
            //   width: 300.0,
            //   height: 50.0,
            //   child: RaisedButton.icon(
            //     icon: Icon(
            //       Icons.share,
            //       size: 35,
            //     ),
            //     label: Text(
            //       'Share QR-Code',
            //       style: TextStyle(fontSize: 20),
            //     ),
            //     textColor: Colors.white,
            //     color: Color(0xffb4fcce0),
            //     elevation: 10,
            //     shape: RoundedRectangleBorder(
            //         borderRadius: new BorderRadius.circular(30.0)),
            //     onPressed: () async {
            //      _captureAndSharePng();
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureAndSharePng() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext.findRenderObject();
      var image = await boundary.toImage();
      ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await new File('${tempDir.path}/image.png').create();
      await file.writeAsBytes(pngBytes);
      final channel = const MethodChannel('channel:me.alfian.share/share');
      channel.invokeMethod('shareFile', 'image.png');
    } catch (e) {
      print(e.toString());
    }
  }
}
