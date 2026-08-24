// One-off icon generator — plain Dart script (run via `dart run`, not the
// Flutter app or test runner). Uses the `image` package (already a project
// dependency) to draw the icon and encode it to PNG directly, with no
// Flutter engine involved.
//
// Usage: dart run tool/generate_app_icon.dart
//
// Produces:
//   assets/icon/app_icon.png            — full icon (gradient + glyph),
//                                          used for iOS/legacy Android/web.
//   assets/icon/app_icon_foreground.png — glyph only, transparent
//                                          background, inset within the
//                                          Android adaptive-icon safe zone.
import 'dart:io';

import 'package:image/image.dart' as img;

const _accentMint = [0x6E, 0xE7, 0xB7];
const _primaryEmerald = [0x10, 0xB9, 0x81];
const _secondaryEmerald = [0x05, 0x96, 0x69];
const _white = [0xFF, 0xFF, 0xFF];

const _size = 1024;

void main() {
  final full = img.Image(width: _size, height: _size, numChannels: 4);
  _paintGradientBackground(full);
  _drawBinGlyph(full, scale: 1.0);
  _writePng(full, 'assets/icon/app_icon.png');

  final foreground = img.Image(width: _size, height: _size, numChannels: 4);
  // Transparent background (Image starts fully zeroed/transparent already).
  // Smaller scale keeps the glyph within Android's ~66% adaptive-icon safe
  // zone, since Android crops/animates this layer independently.
  _drawBinGlyph(foreground, scale: 0.78);
  _writePng(foreground, 'assets/icon/app_icon_foreground.png');
}

void _writePng(img.Image image, String path) {
  final file = File(path);
  file.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  // ignore: avoid_print
  print('Wrote $path');
}

void _paintGradientBackground(img.Image image) {
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final t = ((x + y) / (2 * _size)).clamp(0.0, 1.0);
      List<int> c1, c2;
      double localT;
      if (t < 0.55) {
        c1 = _accentMint;
        c2 = _primaryEmerald;
        localT = t / 0.55;
      } else {
        c1 = _primaryEmerald;
        c2 = _secondaryEmerald;
        localT = (t - 0.55) / 0.45;
      }
      final r = (c1[0] + (c2[0] - c1[0]) * localT).round();
      final g = (c1[1] + (c2[1] - c1[1]) * localT).round();
      final b = (c1[2] + (c2[2] - c1[2]) * localT).round();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

/// A simple flat "waste bin" silhouette (handle + lid + tapered body),
/// centered on the canvas. [scale] shrinks the whole glyph around the
/// canvas center without moving it, so the same layout works both for the
/// full icon and the smaller, safe-zone-inset adaptive-icon foreground.
void _drawBinGlyph(img.Image image, {required double scale}) {
  const cx = _size / 2;
  const cy = _size / 2;
  final color = img.ColorRgba8(_white[0], _white[1], _white[2], 255);

  img.Point p(double x, double y) => img.Point(
        cx + (x - cx) * scale,
        cy + (y - cy) * scale,
      );

  // Handle (small rect above the lid).
  img.fillPolygon(image, color: color, vertices: [
    p(452, 300),
    p(572, 300),
    p(572, 340),
    p(452, 340),
  ]);

  // Lid (wide rect).
  img.fillPolygon(image, color: color, vertices: [
    p(252, 340),
    p(772, 340),
    p(772, 392),
    p(252, 392),
  ]);

  // Body (tapered trapezoid).
  img.fillPolygon(image, color: color, vertices: [
    p(297, 410),
    p(757, 410),
    p(692, 742),
    p(332, 742),
  ]);
}
