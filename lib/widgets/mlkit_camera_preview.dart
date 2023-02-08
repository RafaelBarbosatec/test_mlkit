import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

typedef AsyncInputImageCallback = Future<void> Function(InputImage image,CameraImage camImg);

class MLKitCameraPreview extends StatefulWidget {
  final AsyncInputImageCallback imageCallback;
  final Duration interval;
  final CameraLensDirection cameraLensDirection;
  final ValueChanged<Size>? onStart;
  const MLKitCameraPreview({
    super.key,
    this.interval = const Duration(seconds: 1),
    required this.imageCallback,
    this.cameraLensDirection = CameraLensDirection.back,
    this.onStart,
  });

  @override
  State<MLKitCameraPreview> createState() => _MLKitCamerapreviewState();
}

class _MLKitCamerapreviewState extends State<MLKitCameraPreview> {
  CameraController? controller;

  bool cameraInitializaded = false;
  bool processingImage = false;
  CameraDescription? cameraSelected;
  int indexCamera = 1;

  List<CameraDescription> cameras = [];

  @override
  void initState() {
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraint) {
        return Stack(
          children: [
            cameraInitializaded ? _buildCameraPreview(constraint) : Container(),
          ],
        );
      },
    );
  }

  void _initCamera() async {
    cameras = await availableCameras();
    try {
      cameraSelected = cameras.firstWhere(
        (element) => element.lensDirection == widget.cameraLensDirection,
      );
      // ignore: empty_catches
    } catch (e) {}
    if (cameraSelected != null) {
      controller = CameraController(cameraSelected!, ResolutionPreset.max);

      controller?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          cameraInitializaded = true;
        });
        _initImageStream(cameraSelected!);
        widget.onStart?.call(controller?.value.previewSize ?? Size.zero);
      }).catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              // Handle access errors here.
              break;
            default:
              // Handle other errors here.
              break;
          }
        }
      });
    }
  }

  void _initImageStream(CameraDescription cameraDescription) {
    controller?.startImageStream((image) {
      if (!processingImage) {
        _processImage(image, cameraDescription);
      }
    });
  }

  void _processImage(CameraImage image, CameraDescription camera) async {
    if (controller != null) {
      processingImage = true;
      var inputImage = _getInputImage(image, camera);
      if (inputImage != null) {
        await widget.imageCallback(inputImage,image);
      }
      await Future.delayed(widget.interval);
      processingImage = false;
    }
  }

  InputImage? _getInputImage(CameraImage image, CameraDescription camera) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final imageRotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (imageRotation == null) return null;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return null;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  Widget _buildCameraPreview(BoxConstraints constraint) {
    final scale =
        1 / (controller!.value.aspectRatio * constraint.biggest.aspectRatio);

    return ClipRect(
      clipper: _MediaSizeClipper(constraint.biggest),
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: CameraPreview(controller!),
        ),
      ),
    );
  }

  void _disposeController() async {
    await controller?.stopImageStream();
    await controller?.dispose();
    controller = null;
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
