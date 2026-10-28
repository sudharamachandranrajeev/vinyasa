/// Getting photos ready to send: turned upright, no larger than the AI
/// reads, and re-encoded without their metadata, which can hold where and
/// when they were taken and on what phone.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'vision.dart';

/// [bytes] as an upright JPEG at most [edge] px on its long side, with no
/// EXIF; null when it is not an image this can read.
Uint8List? cleanPhoto(Uint8List bytes, {int edge = 2576}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var out = img.bakeOrientation(decoded);
  final s = fitScale(out.width, out.height, edge: edge);
  if (s < 1) {
    out = img.copyResize(
      out,
      width: (out.width * s).round(),
      height: (out.height * s).round(),
      interpolation: img.Interpolation.average,
    );
  }
  out.exif = img.ExifData();
  return img.encodeJpg(out, quality: 85);
}
