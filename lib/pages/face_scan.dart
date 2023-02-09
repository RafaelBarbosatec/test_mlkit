import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:living_check/util/frame_painter.dart';
import 'package:living_check/util/image_converter.dart';
import 'package:living_check/widgets/mlkit_camera_preview.dart';

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  String scannedText = "";
  String title = 'Escaneando rosto';
  String description = '';
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
    ),
  );

  double faceFrameSize = 0;
  double faceSizeAccepeted = 400;
  double faceMaxSizeAccepeted = 400;
  Rect centerPositionFaceRect = Rect.zero;
  Rect frameFaceRect = Rect.zero;

  Uint8List? _normalface;
  Uint8List? _smilerface;

  bool allImagesCapturated = false;

  bool distanceOk = false;
  bool centerOk = false;

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Face Scan"),
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
                  centerPositionFaceRect = Rect.fromCenter(
                    center: Offset(
                      minSize / 2,
                      maxSize / 2,
                    ),
                    width: faceSizeAccepeted / 2,
                    height: faceSizeAccepeted / 2,
                  );

                  frameFaceRect = Rect.fromCenter(
                    center: Offset(
                      constrant.maxWidth / 2,
                      constrant.maxHeight / 2,
                    ),
                    width: faceFrameSize,
                    height: faceFrameSize * 1.4,
                  );
                });
              },
            ),
            CustomPaint(
              painter: FramePainter(
                frameFaceRect,
                BorderRadius.circular(faceFrameSize),
                strokeColor: distanceOk && centerOk ? Colors.green : Colors.red,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(),
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 100),
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
        distanceOk = false;
        centerOk = false;
        if (faceWidth > faceSizeAccepeted && faceWidth < faceMaxSizeAccepeted) {
          distanceOk = true;
        }

        if (centerPositionFaceRect.contains(face.boundingBox.center)) {
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
    }
    if (mounted) {
      setState(() {});
    }
  }
}
