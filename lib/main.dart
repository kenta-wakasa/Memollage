import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final images = <File>[];
  final globalKey = GlobalKey();

  Future<void> pickMultiImage() async {
    final imagePicker = ImagePicker();
    final xFiles = await imagePicker.pickMultiImage();
    if (xFiles.isEmpty) {
      return;
    }
    images.clear();
    images.addAll(xFiles.map((e) => File(e.path)).toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              RepaintBoundary(
                key: globalKey,
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  children: images
                      .map(
                        (e) => Image.file(
                          e,
                          fit: BoxFit.cover,
                        ),
                      )
                      .toList(),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final uint8ListPNG = await captureByPNG(globalKey);
                  if (uint8ListPNG == null) {
                    return;
                  }
                  await Share.shareXFiles([
                    XFile.fromData(
                      uint8ListPNG,
                      name: 'share.png',
                      mimeType: 'image/png',
                    )
                  ]);
                },
                child: const Text('Widgetをキャプチャ'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickMultiImage,
      ),
    );
  }
}

/// WidgetをPNG画像としてキャプチャする
/// ```dart
/// RepaintBoundary(
///   key: globalKey,
///   child: 画像化したいWidgetをここに書く
/// )
/// ```
Future<Uint8List?> captureByPNG(GlobalKey globalKey) async {
  final boundary = globalKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    return null;
  }
  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteDataPNG = await image.toByteData(format: ImageByteFormat.png);
  if (byteDataPNG == null) {
    return null;
  }
  final uint8ListPNG = byteDataPNG.buffer.asUint8List();
  return uint8ListPNG;
}
