import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:living_check/widgets/mlkit_camera_preview.dart';

class DocumentScanPage extends StatefulWidget {
  const DocumentScanPage({super.key});

  @override
  State<DocumentScanPage> createState() => _DocumentScanPageState();
}

class _DocumentScanPageState extends State<DocumentScanPage> {
  final _textRecognizer = TextRecognizer();
  String scannedText = '';

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Document Scan"),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MLKitCameraPreview(
            imageCallback: _processText,
          ),
          Text(scannedText),
        ],
      ),
    );
  }

  Future _processText(InputImage inputImage, CameraImage camImage) async {
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
}
