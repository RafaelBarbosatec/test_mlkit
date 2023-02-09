import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:living_check/util/frame_painter.dart';
import 'package:living_check/util/functions.dart';
import 'package:living_check/util/image_converter.dart';
import 'package:living_check/widgets/mlkit_camera_preview.dart';

class DocumentImgTest {
  final String text;
  final double sizeFactor;

  const DocumentImgTest(this.text, this.sizeFactor);
}

class DocumentScanPage extends StatefulWidget {
  final List<DocumentImgTest> frontTests;
  final List<DocumentImgTest> backTests;
  const DocumentScanPage({
    super.key,
    this.frontTests = const [
      DocumentImgTest('CARTEIRADEIDENTIDADE', 0.03),
      DocumentImgTest('REPUBLICAFEDERATIVADOBRASIL', 0.029),
    ],
    this.backTests = const [
      DocumentImgTest('VALIDAEMTODOOTERRITORIONACIONAL', 0.029),
      DocumentImgTest('7.116DE29/08/83', 0.029),
    ],
  });

  @override
  State<DocumentScanPage> createState() => _DocumentScanPageState();
}

class _DocumentScanPageState extends State<DocumentScanPage> {
  final _textRecognizer = TextRecognizer();
  String title = 'Frente do documento';

  double percentSizeTextIdentidade = 0.027;

  Rect frameDocumentRect = Rect.zero;
  double camMinSize = 0;
  double camMaxSize = 0;

  Uint8List? _documentFront;
  Uint8List? _documentBack;

  bool capturated = false;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Document Scan"),
      ),
      body: LayoutBuilder(builder: (context, constrant) {
        return Stack(
          fit: StackFit.expand,
          children: [
            MLKitCameraPreview(
              imageCallback: _processText,
              onStart: (value) {
                camMinSize = min(value.width, value.height);
                camMaxSize = max(value.width, value.height);
                double minScreenSize = min(
                  constrant.maxHeight,
                  constrant.maxWidth,
                );

                var faceFrameSize = minScreenSize * 0.85;

                frameDocumentRect = Rect.fromCenter(
                  center: Offset(
                    constrant.maxWidth / 2,
                    constrant.maxHeight / 2,
                  ),
                  width: faceFrameSize,
                  height: faceFrameSize * 1.5,
                );
              },
            ),
            CustomPaint(
              painter: FramePainter(
                frameDocumentRect,
                BorderRadius.circular(6),
                strokeColor: capturated ? Colors.green : Colors.red,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    if (_documentFront != null)
                      Image.memory(
                        _documentFront!,
                        height: 100,
                      ),
                    if (_documentBack != null)
                      Image.memory(
                        _documentBack!,
                        height: 100,
                      )
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future _processText(InputImage inputImage, CameraImage camImage) async {
    capturated = false;
    RecognizedText recognisedText = await _textRecognizer.processImage(
      inputImage,
    );

    if (_documentFront == null) {
      bool tested = _execTests(recognisedText.blocks, widget.frontTests);
      if (tested) {
        capturated = true;
        _documentFront = await convertYUV420toImageColor(
          camImage,
          inputImage.inputImageData!.imageRotation,
        );
        title = 'Verso do documento';
      }
    } else if (_documentBack == null) {
      bool tested = _execTests(recognisedText.blocks, widget.backTests);
      if (tested) {
        capturated = true;
        _documentBack = await convertYUV420toImageColor(
          camImage,
          inputImage.inputImageData!.imageRotation,
        );
        title = 'Tudo certo! Muito Obrigado!';
      }
    }
    setState(() {});
  }

  bool _execTests(List<TextBlock> blocks, List<DocumentImgTest> tests) {
    int passedCount = 0;
    for (TextBlock block in blocks) {
      for (TextLine line in block.lines) {
        for (var test in tests) {
          if (removeDiacritics(line.text.replaceAll(' ', ''))
              .contains(test.text.toUpperCase())) {
            double minSize =
                min(line.boundingBox.width, line.boundingBox.height);
            double percent = minSize / camMinSize;
            if (kDebugMode) {
              print('Test(${test.text}) factorSize: $percent');
            }
            if (percent > test.sizeFactor) {
              passedCount++;
            }
          }
        }
      }
    }

    return passedCount == tests.length;
  }
}
