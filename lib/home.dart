import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:living_check/mlkit_camera_preview.dart';
import 'package:living_check/util/face_painter.dart';

enum TypeDetection { text, faces }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String scannedText = "";
  CustomPaint? _customPaint;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  final _textRecognizer = TextRecognizer();

  TypeDetection typeDetection = TypeDetection.text;

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          MLKitCameraPreview(
            imageCallback: _imageCallback,
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
              child: Text(_getTitle()),
            ),
          ),
          if (_customPaint != null) _customPaint!,
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (scannedText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      scannedText,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: typeDetection == TypeDetection.faces
                              ? () {
                                  setState(() {
                                    typeDetection = TypeDetection.text;
                                  });
                                }
                              : null,
                          child: const Text('Text'),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: typeDetection == TypeDetection.text
                              ? () {
                                  setState(() {
                                    typeDetection = TypeDetection.faces;
                                  });
                                }
                              : null,
                          child: const Text('Faces'),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
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

  Future _processFace(InputImage inputImage) async {
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.inputImageData!.size,
        inputImage.inputImageData!.imageRotation,
      );
      _customPaint = CustomPaint(painter: painter);
      if (faces.isNotEmpty) {
        scannedText = 'Smile: ${faces.first.smilingProbability}';
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

  Future<void> _imageCallback(InputImage image) async {
    switch (typeDetection) {
      case TypeDetection.text:
        await _processText(image);
        break;
      case TypeDetection.faces:
        await _processFace(image);
        break;
    }
  }

  String _getTitle() {
    switch (typeDetection) {
      case TypeDetection.text:
        return 'Scanning text';
      case TypeDetection.faces:
        return 'Scanning faces';
    }
  }
}
