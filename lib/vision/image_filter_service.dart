import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageFilterService {
  /// Load image bytes from file into an img.Image for processing
  static Future<img.Image?> loadFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return img.decodeImage(bytes);
    } catch (e) {
      debugPrint('ImageFilterService.loadFromFile error: $e');
      return null;
    }
  }

  /// Convert processed img.Image back to ui.Image for Flutter display
  static Future<ui.Image> toUiImage(img.Image image) async {
    final png = img.encodePng(image);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(Uint8List.fromList(png), (result) {
      completer.complete(result);
    });
    return completer.future;
  }

  /// Convert img.Image to raw bytes (PNG) for saving
  static Future<Uint8List> toBytes(img.Image image) async {
    return Uint8List.fromList(img.encodePng(image));
  }

  // ─── Filter 1: Inverse / Negative ──────────────────────────────────────────

  /// Inverts every pixel channel: output = 255 - input
  /// Creates photographic negative effect.
  static img.Image applyInverse(img.Image src) {
    final out = src.clone();
    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final pixel = out.getPixel(x, y);
        out.setPixel(
          x,
          y,
          img.ColorRgb8(
            255 - pixel.r.toInt(),
            255 - pixel.g.toInt(),
            255 - pixel.b.toInt(),
          ),
        );
      }
    }
    return out;
  }

  // ─── Filter 2: Histogram Equalization ──────────────────────────────────────

  /// Equalizes grayscale histogram to improve contrast.
  /// Steps:
  ///   1. Convert to grayscale
  ///   2. Build histogram
  ///   3. Compute CDF
  ///   4. Map each pixel to equalized value
  static img.Image applyHistogramEqualization(img.Image src) {
    final gray = img.grayscale(src.clone());

    // Build histogram
    final hist = List<int>.filled(256, 0);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final lum = gray.getPixel(x, y).r.toInt();
        hist[lum]++;
      }
    }

    // Compute CDF (cumulative distribution function)
    final cdf = List<int>.filled(256, 0);
    cdf[0] = hist[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + hist[i];
    }

    // Find minimum non-zero CDF value
    final cdfMin = cdf.firstWhere((v) => v > 0, orElse: () => 1);
    final totalPixels = gray.width * gray.height;

    // Build lookup table
    final lut = List<int>.generate(256, (i) {
      final val = ((cdf[i] - cdfMin) / (totalPixels - cdfMin) * 255).round();
      return val.clamp(0, 255);
    });

    // Apply LUT back to image (output as grayscale RGB)
    final out = img.Image(width: src.width, height: src.height);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final lum = gray.getPixel(x, y).r.toInt();
        final eq = lut[lum];
        out.setPixel(x, y, img.ColorRgb8(eq, eq, eq));
      }
    }
    return out;
  }

  // ─── Filter 3: Lowpass / Gaussian Blur ─────────────────────────────────────

  /// Gaussian blur using a 5x5 kernel.
  /// sigma = 1.0 provides soft smoothing without destroying structure.
  static img.Image applyLowpass(img.Image src, {double sigma = 1.5}) {
    final kernel = _buildGaussianKernel(5, sigma);
    return _convolve(src, kernel, 5);
  }

  // ─── Filter 4: Highpass / Edge Detection ───────────────────────────────────

  /// Sobel edge detection — computes gradient magnitude in X and Y.
  /// Output highlights sharp transitions (cracks, potholes edges).
  static img.Image applyHighpass(img.Image src) {
    // Sobel kernels
    final sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    final sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    final gray = img.grayscale(src.clone());
    final out = img.Image(width: src.width, height: src.height);

    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        double gx = 0, gy = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final lum = gray.getPixel(x + kx, y + ky).r.toDouble();
            gx += lum * sobelX[ky + 1][kx + 1];
            gy += lum * sobelY[ky + 1][kx + 1];
          }
        }

        final magnitude = sqrt(gx * gx + gy * gy).clamp(0, 255).toInt();
        out.setPixel(x, y, img.ColorRgb8(magnitude, magnitude, magnitude));
      }
    }
    return out;
  }

  // ─── Filter 5: Median Filter ────────────────────────────────────────────────

  /// Replaces each pixel with the median of its neighborhood.
  /// Effective at removing salt-and-pepper noise while preserving edges.
  /// [radius] = 1 → 3x3 neighborhood
  static img.Image applyMedianFilter(img.Image src, {int radius = 1}) {
    final out = src.clone();
    final gray = img.grayscale(src.clone());

    for (int y = radius; y < gray.height - radius; y++) {
      for (int x = radius; x < gray.width - radius; x++) {
        final rs = <int>[], gs = <int>[], bs = <int>[];

        for (int ky = -radius; ky <= radius; ky++) {
          for (int kx = -radius; kx <= radius; kx++) {
            final p = src.getPixel(x + kx, y + ky);
            rs.add(p.r.toInt());
            gs.add(p.g.toInt());
            bs.add(p.b.toInt());
          }
        }

        rs.sort();
        gs.sort();
        bs.sort();

        final mid = rs.length ~/ 2;
        out.setPixel(x, y, img.ColorRgb8(rs[mid], gs[mid], bs[mid]));
      }
    }
    return out;
  }

  // ─── Filter 6: Threshold / Binarization ─────────────────────────────────────

  /// Converts image to pure black & white based on a luminance threshold.
  /// Pixels above [threshold] → white (255), below → black (0).
  /// Useful for isolating cracks from road surface.
  static img.Image applyThreshold(img.Image src, {int threshold = 128}) {
    final gray = img.grayscale(src.clone());
    final out = img.Image(width: src.width, height: src.height);

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final lum = gray.getPixel(x, y).r.toInt();
        final val = lum >= threshold ? 255 : 0;
        out.setPixel(x, y, img.ColorRgb8(val, val, val));
      }
    }
    return out;
  }

  // ─── Internal Helpers ───────────────────────────────────────────────────────

  /// Build a normalized Gaussian kernel of [size] x [size]
  static List<double> _buildGaussianKernel(int size, double sigma) {
    final kernel = <double>[];
    final half = size ~/ 2;
    double sum = 0;

    for (int y = -half; y <= half; y++) {
      for (int x = -half; x <= half; x++) {
        final val = exp(-(x * x + y * y) / (2 * sigma * sigma));
        kernel.add(val);
        sum += val;
      }
    }

    return kernel.map((v) => v / sum).toList();
  }

  /// Generic convolution with a flat [kernel] of given [kernelSize]
  static img.Image _convolve(
    img.Image src,
    List<double> kernel,
    int kernelSize,
  ) {
    final out = src.clone();
    final half = kernelSize ~/ 2;

    for (int y = half; y < src.height - half; y++) {
      for (int x = half; x < src.width - half; x++) {
        double r = 0, g = 0, b = 0;
        int ki = 0;

        for (int ky = -half; ky <= half; ky++) {
          for (int kx = -half; kx <= half; kx++) {
            final p = src.getPixel(x + kx, y + ky);
            final w = kernel[ki++];
            r += p.r * w;
            g += p.g * w;
            b += p.b * w;
          }
        }

        out.setPixel(
          x,
          y,
          img.ColorRgb8(
            r.clamp(0, 255).toInt(),
            g.clamp(0, 255).toInt(),
            b.clamp(0, 255).toInt(),
          ),
        );
      }
    }
    return out;
  }
}

/// Enum untuk semua filter yang tersedia
enum ImageFilter {
  original,
  inverse,
  histogramEqualization,
  lowpass,
  highpass,
  medianFilter,
  threshold;

  String get displayName {
    switch (this) {
      case ImageFilter.original:
        return 'Original';
      case ImageFilter.inverse:
        return 'Inverse';
      case ImageFilter.histogramEqualization:
        return 'Hist. Eq.';
      case ImageFilter.lowpass:
        return 'Lowpass';
      case ImageFilter.highpass:
        return 'Highpass';
      case ImageFilter.medianFilter:
        return 'Median';
      case ImageFilter.threshold:
        return 'Threshold';
    }
  }

  String get description {
    switch (this) {
      case ImageFilter.original:
        return 'Foto asli tanpa perubahan';
      case ImageFilter.inverse:
        return 'Negatif foto — membalik nilai piksel';
      case ImageFilter.histogramEqualization:
        return 'Meratakan distribusi intensitas untuk meningkatkan kontras';
      case ImageFilter.lowpass:
        return 'Gaussian blur — menghaluskan derau pada gambar';
      case ImageFilter.highpass:
        return 'Deteksi tepi Sobel — menonjolkan kontur dan retak';
      case ImageFilter.medianFilter:
        return 'Filter median — reduksi derau salt-and-pepper';
      case ImageFilter.threshold:
        return 'Binarisasi — mengubah gambar menjadi hitam-putih';
    }
  }

  IconData get icon {
    switch (this) {
      case ImageFilter.original:
        return Icons.image_outlined;
      case ImageFilter.inverse:
        return Icons.invert_colors;
      case ImageFilter.histogramEqualization:
        return Icons.equalizer;
      case ImageFilter.lowpass:
        return Icons.blur_on;
      case ImageFilter.highpass:
        return Icons.auto_fix_high;
      case ImageFilter.medianFilter:
        return Icons.grain;
      case ImageFilter.threshold:
        return Icons.tonality;
    }
  }
}
