import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final source = File('assets/logo_howe_splash_android12.png');
  final output = File('assets/logo_howe_ios.png');
  final decoded = img.decodePng(source.readAsBytesSync());
  if (decoded == null) {
    throw StateError('Gagal membaca ${source.path}');
  }

  const backgroundRed = 0x1A;
  const backgroundGreen = 0x37;
  const backgroundBlue = 0x4D;
  final flattened = img.Image(
    width: decoded.width,
    height: decoded.height,
    numChannels: 3,
  );

  for (var y = 0; y < decoded.height; y++) {
    for (var x = 0; x < decoded.width; x++) {
      final alpha = decoded.getPixel(x, y).a.toInt();
      final inverseAlpha = 255 - alpha;
      flattened.setPixelRgb(
        x,
        y,
        ((alpha * 255) + (inverseAlpha * backgroundRed)) ~/ 255,
        ((alpha * 255) + (inverseAlpha * backgroundGreen)) ~/ 255,
        ((alpha * 255) + (inverseAlpha * backgroundBlue)) ~/ 255,
      );
    }
  }

  output.writeAsBytesSync(img.encodePng(flattened));
}
