import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:living_check/util/image_converter.dart';
import 'package:living_check/widgets/mlkit_camera_preview.dart';

enum TypeDetection { text, faces }

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  String scannedText = "";
  String title = 'Escaneando rosto';
  String description = '';
  CustomPaint? _customPaint;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  final _textRecognizer = TextRecognizer();

  TypeDetection typeDetection = TypeDetection.text;

  double faceFrameSize = 0;
  double faceSizeAccepeted = 400;
  double faceMaxSizeAccepeted = 400;
  Rect centerRect = Rect.zero;

  Uint8List? _normalface;
  Uint8List? _smilerface;

  bool allImagesCapturated = false;

  @override
  void dispose() {
    _faceDetector.close();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Text Recognition example"),
      ),
      body: LayoutBuilder(builder: (context, constrant) {
        return Stack(
          fit: StackFit.expand,
          children: [
            MLKitCameraPreview(
              imageCallback: _processFace,
              cameraLensDirection: CameraLensDirection.front,
              onStart: (value) {
                setState(() {
                  double minSize = min(value.width, value.height);
                  double maxSize = max(value.width, value.height);

                  faceSizeAccepeted = minSize * 0.6;
                  faceMaxSizeAccepeted = faceSizeAccepeted * 1.5;
                  double minScreenSize = min(
                    constrant.maxHeight,
                    constrant.maxWidth,
                  );
                  faceFrameSize = minScreenSize * 0.6;
                  centerRect = Rect.fromCenter(
                    center: Offset(
                      minSize / 2,
                      maxSize / 2,
                    ),
                    width: faceSizeAccepeted / 2,
                    height: faceSizeAccepeted / 2,
                  );
                });
              },
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(description),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: faceFrameSize,
                height: faceFrameSize * 1.4,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(faceFrameSize)),
              ),
            ),
            // if (_customPaint != null) _customPaint!,
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: Column(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       if (scannedText.isNotEmpty)
            //         Container(
            //           padding: const EdgeInsets.all(16),
            //           decoration: BoxDecoration(
            //             color: Colors.white.withOpacity(0.5),
            //             borderRadius: BorderRadius.circular(20),
            //           ),
            //           child: Text(
            //             scannedText,
            //             style: const TextStyle(fontSize: 20),
            //           ),
            //         ),
            //     ],
            //   ),
            // ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    if (_normalface != null)
                      Image.memory(
                        _normalface!,
                        height: 100,
                      ),
                    if (_smilerface != null)
                      Image.memory(
                        _smilerface!,
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

  Future _processText(InputImage inputImage) async {
    RecognizedText recognisedText = await _textRecognizer.processImage(
      inputImage,
    );
    scannedText = "";
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        scannedText = "${scannedText + line.text}\n";
      }
    }
    setState(() {});
  }

  Future _processFace(InputImage inputImage, CameraImage camImage) async {
    if (allImagesCapturated) {
      return;
    }
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      // final painter = FaceDetectorPainter(
      //   faces,
      //   inputImage.inputImageData!.size,
      //   inputImage.inputImageData!.imageRotation,
      // );
      // _customPaint = CustomPaint(painter: painter);
      if (faces.length == 1) {
        var face = faces.first;
        // scannedText = 'Smile: ${faces.first.smilingProbability}';
        double faceWidth = face.boundingBox.size.width;
        bool distanceOk = false;
        bool centerOk = false;
        if (faceWidth > faceSizeAccepeted && faceWidth < faceMaxSizeAccepeted) {
          distanceOk = true;
        }

        if (centerRect.contains(face.boundingBox.center)) {
          centerOk = true;
        }

        if (faceWidth < faceSizeAccepeted) {
          description = 'Aproxime mais o rosto';
        } else if (faceWidth > faceMaxSizeAccepeted) {
          description = 'Afaste mais o rosto';
        } else if (!centerOk) {
          description = 'Centralize seu rosto na marcação';
        } else {
          description = '';
        }

        bool isSmiling = (face.smilingProbability ?? 0.0) > 0.9;

        scannedText =
            'DISTANCIA: ${distanceOk ? 'SIM' : 'NÃO'}\nCENTRO: ${centerOk ? 'SIM' : 'NÃO'}\nSmile: ${faces.first.smilingProbability}';

        if (centerOk && distanceOk) {
          if (_normalface == null) {
            _normalface = await convertYUV420toImageColor(
              camImage,
              inputImage.inputImageData!.imageRotation,
              flipHorizontal: true,
            );
            title = 'Sorria!';
          } else if (_smilerface == null && isSmiling) {
            _smilerface = await convertYUV420toImageColor(
              camImage,
              inputImage.inputImageData!.imageRotation,
              flipHorizontal: true,
            );
            title = 'Tudo pronto! Obrigado!';
            allImagesCapturated = true;
          }
        }
      } else {
        scannedText = '';
      }
    } else {
      scannedText = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        scannedText += 'face: ${face.boundingBox}\n\n';
      }

      _customPaint = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Future<void> _imageCallback(InputImage imag, CameraImage camImg) async {
  //   switch (typeDetection) {
  //     case TypeDetection.text:
  //       await _processText(image);
  //       break;
  //     case TypeDetection.faces:
  //       await _processFace(image,camImg);
  //       break;
  //   }
  // }

}
