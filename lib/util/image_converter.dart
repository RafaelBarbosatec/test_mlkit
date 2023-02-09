import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;

const shift = (0xFF << 24);
Future<Uint8List?> convertYUV420toImageColor(
    CameraImage image, InputImageRotation imageRotation,
    {bool flipHorizontal = false}) async {
  try {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    // imgLib -> Image package from https://pub.dartlang.org/packages/image
    var img = imglib.Image(width, height); // Create Image buffer

    // Fill image buffer with plane[0] from YUV420_888
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        img.data[index] = shift | (b << 16) | (g << 8) | r;
      }
    }

    imglib.PngEncoder pngEncoder = imglib.PngEncoder(level: 0, filter: 0);

    switch (imageRotation) {
      case InputImageRotation.rotation0deg:
        break;
      case InputImageRotation.rotation90deg:
        img = imglib.copyRotate(img, 90);
        break;
      case InputImageRotation.rotation180deg:
        img = imglib.copyRotate(img, 180);
        break;
      case InputImageRotation.rotation270deg:
        img = imglib.copyRotate(img, 270);
        break;
    }

    if (flipHorizontal) {
      img = imglib.flipHorizontal(img);
    }
    List<int> png = pngEncoder.encodeImage(img);
    // muteYUVProcessing = false;
    return Uint8List.fromList(png);
  } catch (e) {
    if (kDebugMode) {
      print(">>>>>>>>>>>> ERROR:$e");
    }
  }
  return null;
}
