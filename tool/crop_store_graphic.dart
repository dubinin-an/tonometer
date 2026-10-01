import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> arguments) {
  if (arguments.length != 2) {
    throw ArgumentError('Usage: crop_store_graphic <input> <output>');
  }
  final source = img.decodePng(File(arguments[0]).readAsBytesSync());
  if (source == null || source.width < 1024 || source.height < 500) {
    throw StateError('Expected a PNG of at least 1024×500 pixels');
  }
  final result = img.copyCrop(source, x: 0, y: 0, width: 1024, height: 500);
  File(arguments[1]).writeAsBytesSync(img.encodePng(result));
}
