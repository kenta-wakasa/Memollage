import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.kosugiTextTheme().apply(
          bodyColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double aspectRatio = 1;
  List<Uint8List> images = [];
  final globalKey = GlobalKey();
  final random = Random();
  bool isProcessing = false;

  List<Widget> imageWidgets = [];

  Future<void> pickMultiImage() async {
    final imagePicker = ImagePicker();
    final xFiles = await imagePicker.pickMultiImage(
      maxWidth: 400,
    );
    if (xFiles.isEmpty) {
      return;
    }
    images = await Future.wait(
        xFiles.map((e) async => await e.readAsBytes()).toList());
    generateImageWidgets();
    setState(() {});
  }

  void generateImageWidgets() {
    final windowWidth = MediaQuery.of(context).size.width;
    final tmpList = <Widget>[];

    for (var index = 0; index < 400; index++) {
      final height =
          (random.nextInt(10) * (windowWidth / 32) + (windowWidth / 20))
              .toDouble();
      final width = height * aspectRatio;
      final image = images[random.nextInt(images.length)];
      tmpList.add(Align(
        alignment: Alignment(
          random.nextDouble() * 3 - 1.5,
          random.nextDouble() * 3 - 1.5,
        ),
        child: Transform.rotate(
          angle: pi * (random.nextDouble() * .6 - .3),
          child: SizedBox(
            width: width,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 0),
                  ),
                ],
                border: Border.all(
                  width: 1,
                  color: Colors.black.withOpacity(.8),
                ),
              ),
              child: Image.memory(
                image,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ));
    }
    imageWidgets = tmpList;
    setState(() {});
  }

  void clearImages() {
    images.clear();
    setState(() {});
  }

  Future<void> captureAndShareImage() async {
    try {
      setState(() {
        isProcessing = true;
      });
      final uint8ListPNG = await captureByPNG(globalKey);
      if (uint8ListPNG == null) {
        return;
      }
      await Share.shareXFiles(
        [
          XFile.fromData(
            uint8ListPNG,
            name: 'share.png',
            mimeType: 'image/png',
          )
        ],
        text: '#Memollage',
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Tooltip(
                      message: 'リセット',
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: Colors.pink,
                        ),
                        onPressed: images.isEmpty
                            ? null
                            : () async {
                                final res = await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('画像のリセット'),
                                      content: const Text(
                                          '選択中の画像をリセットしますか？（この操作は戻せません）'),
                                      actions: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: const Text('しない'),
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                          child: const Text('する'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (res == true) {
                                  clearImages();
                                }
                              },
                        child: const Icon(Icons.replay),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  if (images.isNotEmpty)
                    RepaintBoundary(
                      key: globalKey,
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: InkWell(
                          onTap: () {
                            generateImageWidgets();
                          },
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(),
                            child: Stack(
                              fit: StackFit.expand,
                              children: imageWidgets,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    AspectRatio(
                      aspectRatio: aspectRatio,
                      child: InkWell(
                        onTap: pickMultiImage,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(width: 2, color: Colors.white),
                          ),
                          child: const Text('タップして画像を選択'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 64),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    onPressed: images.isEmpty ? null : captureAndShareImage,
                    child: const Text(
                      '画像をシェア',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        if (isProcessing)
          Container(
            color: Colors.white24,
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const CircularProgressIndicator(),
            ),
          ),
      ],
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
  final image = await boundary.toImage(pixelRatio: 6.0);
  final byteDataPNG = await image.toByteData(format: ImageByteFormat.png);
  if (byteDataPNG == null) {
    return null;
  }
  final uint8ListPNG = byteDataPNG.buffer.asUint8List();
  return uint8ListPNG;
}
