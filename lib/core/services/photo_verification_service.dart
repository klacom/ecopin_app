import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

class PhotoVerificationResult {
  final File file;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime capturedAt;
  final String source; // 'camera' or 'gallery'
  final bool isMocked;
  final String? address;

  PhotoVerificationResult({
    required this.file,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.capturedAt,
    required this.source,
    this.isMocked = false,
    this.address,
  });

  Map<String, dynamic> toTelemetryMap() {
    return {
      'photo_lat': latitude?.toString(),
      'photo_lng': longitude?.toString(),
      'photo_accuracy': accuracy?.toString(),
      'photo_captured_at': capturedAt.toIso8601String(),
      'photo_source': source,
      'is_mocked': isMocked.toString(),
    };
  }
}

class PhotoVerificationService {
  static final Logger _log = Logger('PhotoVerificationService');

  /// Captures current GPS telemetry and burns a TimeMark-style verification banner onto the photo.
  static Future<PhotoVerificationResult> processPhoto({
    required File originalFile,
    required String source, // 'camera' | 'gallery'
    String? knownAddress,
    double? fallbackLat,
    double? fallbackLng,
    String? qrPayload,
  }) async {
    final now = DateTime.now();
    double? lat;
    double? lng;
    double? accuracy;
    bool isMocked = false;

    // 1. If captured live via camera, obtain high-accuracy GPS telemetry
    if (source == 'camera') {
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          lat = position.latitude;
          lng = position.longitude;
          accuracy = position.accuracy;
          isMocked = position.isMocked;
        }
      } catch (e) {
        _log.warning('Could not acquire GPS position during photo capture: $e');
      }
    }

    // 2. Burn TimeMark-style verification watermark onto photo
    File processedFile = originalFile;
    try {
      final stamped = await _burnWatermark(
        file: originalFile,
        lat: lat,
        lng: lng,
        fallbackLat: fallbackLat,
        fallbackLng: fallbackLng,
        accuracy: accuracy,
        timestamp: now,
        address: knownAddress,
        source: source,
        isMocked: isMocked,
        qrPayload: qrPayload,
      );
      if (stamped != null) {
        processedFile = stamped;
      }
    } catch (e) {
      _log.warning('Watermarking failed, using original photo: $e');
    }

    return PhotoVerificationResult(
      file: processedFile,
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      capturedAt: now,
      source: source,
      isMocked: isMocked,
      address: knownAddress,
    );
  }

  /// Draws a clean, high-contrast semi-transparent banner onto the image
  static Future<File?> _burnWatermark({
    required File file,
    required double? lat,
    required double? lng,
    double? fallbackLat,
    double? fallbackLng,
    required double? accuracy,
    required DateTime timestamp,
    String? address,
    required String source,
    bool isMocked = false,
    String? qrPayload,
  }) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    // Orient image upright according to EXIF rotation
    image = img.bakeOrientation(image);

    final width = image.width;
    final height = image.height;

    // Resolution-based sizing
    final isHighRes = width >= 1800;
    final isMediumRes = width >= 1000;

    final fontTime = isHighRes ? img.arial48 : (isMediumRes ? img.arial48 : img.arial24);
    final fontDate = isHighRes ? img.arial24 : (isMediumRes ? img.arial14 : img.arial14);
    final fontAddress = isHighRes ? img.arial24 : (isMediumRes ? img.arial14 : img.arial14);
    final fontDetails = isHighRes ? img.arial14 : img.arial14;

    final paddingX = (width * 0.05).clamp(16, 60).toInt();
    final paddingBottom = (height * 0.03).clamp(10, 40).toInt();

    // Format Date and Time
    final timeStr = DateFormat('hh:mm').format(timestamp);
    final amPmStr = DateFormat('a').format(timestamp).toUpperCase();
    final dayMonthStr = DateFormat('EEE, MMM d').format(timestamp);
    final yearStr = DateFormat('yyyy').format(timestamp);

    final double? displayLat = lat ?? fallbackLat;
    final double? displayLng = lng ?? fallbackLng;
    final bool isVerified = (lat != null && !isMocked);

    final String coordsText;
    if (lat != null && lng != null) {
      coordsText = '${lat.toStringAsFixed(6)} N, ${lng.toStringAsFixed(6)} E (±${(accuracy ?? 0).toStringAsFixed(0)}m)';
    } else if (displayLat != null && displayLng != null) {
      coordsText = '${displayLat.toStringAsFixed(6)} N, ${displayLng.toStringAsFixed(6)} E (Report Pin)';
    } else {
      coordsText = 'Pasig City';
    }

    final detailLine = '$coordsText  •  ${isVerified ? 'Verified On-Site' : 'EcoPin Report'}';

    final availableTextWidth = width - (paddingX * 2);
    final charWidthAddress = isHighRes ? 14 : (isMediumRes ? 9 : 8);
    final maxAddressCharsPerLine = (availableTextWidth / charWidthAddress).floor().clamp(25, 80);

    final rawAddress = (address != null && address.trim().isNotEmpty)
        ? address.trim()
        : 'Pasig City, Metro Manila';

    // Word-wrap address into complete lines without truncating
    final addressWords = rawAddress.split(' ');
    final addressLines = <String>[];
    String currentAddressLine = '';

    for (final word in addressWords) {
      if (currentAddressLine.isEmpty) {
        currentAddressLine = word;
      } else if ((currentAddressLine.length + 1 + word.length) <= maxAddressCharsPerLine) {
        currentAddressLine += ' $word';
      } else {
        addressLines.add(currentAddressLine);
        currentAddressLine = word;
      }
    }
    if (currentAddressLine.isNotEmpty) {
      addressLines.add(currentAddressLine);
    }

    final charWidthDetails = isHighRes ? 8 : 7;
    final maxDetailChars = (availableTextWidth / charWidthDetails).floor();
    String finalDetailLine = detailLine;
    if (finalDetailLine.length > maxDetailChars) {
      finalDetailLine = coordsText;
    }

    // Dynamic vertical stacking so all address lines and time block fit comfortably
    final addressLineHeight = isHighRes ? 30 : (isMediumRes ? 20 : 16);
    final timeBlockHeight = isHighRes ? 50 : (isMediumRes ? 34 : 26);

    final bottomLineY = height - paddingBottom - (isHighRes ? 8 : 4);
    final addressStartY = bottomLineY - (addressLines.length * addressLineHeight);
    final timeBlockY = addressStartY - timeBlockHeight - (isHighRes ? 12 : 8);

    // Dynamic gradient vignette sitting snugly behind watermark content
    final gradientStartY = (timeBlockY - (isHighRes ? 24 : 14)).clamp(0, height);
    final gradientHeight = height - gradientStartY;

    for (int y = gradientStartY; y < height; y++) {
      final double progress = (y - gradientStartY) / gradientHeight;
      final int alpha = (progress * progress * 155).clamp(0, 170).toInt();
      final color = img.ColorRgba8(10, 15, 20, alpha);
      img.fillRect(image, x1: 0, y1: y, x2: width, y2: y + 1, color: color);
    }

    final targetImage = image;
    void drawWithShadow(String text, {required img.BitmapFont font, required int x, required int y, required img.Color color}) {
      img.drawString(targetImage, text, font: font, x: x + 2, y: y + 2, color: img.ColorRgba8(0, 0, 0, 220));
      img.drawString(targetImage, text, font: font, x: x, y: y, color: color);
    }

    // A. Bottom detail line (Coordinates)
    drawWithShadow(
      finalDetailLine,
      font: fontDetails,
      x: paddingX,
      y: bottomLineY,
      color: img.ColorRgba8(203, 213, 225, 255),
    );

    // B. Address lines (Complete, wrapped, no truncation)
    for (int i = 0; i < addressLines.length; i++) {
      drawWithShadow(
        addressLines[i],
        font: fontAddress,
        x: paddingX,
        y: addressStartY + (i * addressLineHeight),
        color: img.ColorRgba8(255, 255, 255, 255),
      );
    }

    // C. Giant Time (09:16)
    drawWithShadow(
      timeStr,
      font: fontTime,
      x: paddingX,
      y: timeBlockY,
      color: img.ColorRgba8(255, 255, 255, 255),
    );

    // Calculate time text width
    final timeCharWidth = isHighRes ? 28 : (isMediumRes ? 28 : 14);
    final timeWidth = timeStr.length * timeCharWidth;

    // AM/PM small text
    final amPmX = paddingX + timeWidth + 4;
    drawWithShadow(
      amPmStr,
      font: fontDate,
      x: amPmX,
      y: timeBlockY + 4,
      color: img.ColorRgba8(255, 255, 255, 240),
    );

    // Vertical Divider Line in EcoPin Civic Blue (#0052CC)
    final dividerX = amPmX + (amPmStr.length * (isHighRes ? 14 : 9)) + (isHighRes ? 14 : 9);
    final dividerHeight = (isHighRes ? 48 : 34);
    final dividerThickness = isHighRes ? 5 : 3;

    // Divider shadow
    img.fillRect(
      image,
      x1: dividerX + 2,
      y1: timeBlockY + 4,
      x2: dividerX + dividerThickness + 2,
      y2: timeBlockY + dividerHeight + 4,
      color: img.ColorRgba8(0, 0, 0, 180),
    );
    // Divider EcoPin Civic Blue
    img.fillRect(
      image,
      x1: dividerX,
      y1: timeBlockY + 2,
      x2: dividerX + dividerThickness,
      y2: timeBlockY + dividerHeight + 2,
      color: img.ColorRgba8(0, 82, 204, 255), // #0052CC
    );

    // Date Block: "Sat, Oct 27" on top, "2026" underneath
    final dateBlockX = dividerX + dividerThickness + (isHighRes ? 14 : 9);
    drawWithShadow(
      dayMonthStr,
      font: fontDate,
      x: dateBlockX,
      y: timeBlockY + 2,
      color: img.ColorRgba8(255, 255, 255, 255),
    );

    drawWithShadow(
      yearStr,
      font: fontDate,
      x: dateBlockX,
      y: timeBlockY + (isHighRes ? 26 : 18),
      color: img.ColorRgba8(255, 255, 255, 255),
    );

    // Save to stamped jpg file
    final stampedPath = p.join(
      file.parent.path,
      'stamped_${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
    );
    final stampedBytes = img.encodeJpg(image, quality: 85);
    final stampedFile = File(stampedPath);
    await stampedFile.writeAsBytes(stampedBytes);

    return stampedFile;
  }
}
