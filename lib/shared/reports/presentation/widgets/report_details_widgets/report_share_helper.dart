import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:ecopin_app/shared/reports/data/models/report_model.dart';
import 'package:ecopin_app/shared/widgets/snackbar_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';

class ReportShareHelper {
  static Future<void> shareReportPhoto({
    required ReportModel report,
    String? photoUrl,
    bool isVideo = false,
  }) async {
    final isRejected =
        report.status.toLowerCase() == 'rejected' ||
        report.validationStatus.toLowerCase() == 'rejected';
    if (isRejected) {
      SnackbarHelper.showError('Rejected reports cannot be shared.');
      return;
    }

    final url = photoUrl ?? report.beforePhotoUrl ?? report.afterPhotoUrl;
    if (url == null || url.isEmpty) {
      SnackbarHelper.showError('No report evidence available to share.');
      return;
    }

    try {
      isVideo =
          isVideo ||
          [
            'mp4',
            'mov',
            'webm',
          ].contains(Uri.parse(url).path.split('.').last.toLowerCase());
      String localFilePath;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final tempDir = await getTemporaryDirectory();
        final ext = url.split('?').first.split('.').last.toLowerCase();
        final validExt = isVideo
            ? (['mp4', 'mov', 'webm'].contains(ext) ? ext : 'mp4')
            : (['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg');
        localFilePath =
            '${tempDir.path}/ecopin_report_${report.id.substring(0, 8)}.$validExt';

        final response = await Dio().get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data == null) {
          throw Exception('Failed to download photo data');
        }
        final file = File(localFilePath);
        await file.writeAsBytes(response.data!);
      } else {
        localFilePath = url;
      }

      final webBaseUrl =
          dotenv.env['WEB_BASE_URL'] ?? 'https://ecopin-web.vercel.app';
      final shareUrl = '$webBaseUrl/reports/${report.id}';

      // Generate Strava/Spotify-style Civic Action Share Card
      String finalSharePath = localFilePath;
      try {
        final tempDir = isVideo ? null : await getTemporaryDirectory();
        final cardPath = isVideo
            ? null
            : await Isolate.run(
                () => _generateShareCard(
                  photoPath: localFilePath,
                  report: report,
                  shareUrl: shareUrl,
                  outputPath:
                      '${tempDir!.path}/ecopin_story_${report.id.substring(0, 8)}.jpg',
                ),
              );
        if (cardPath != null) {
          finalSharePath = cardPath;
        }
      } catch (e) {
        // Fallback to local photo if card generation encounters an issue
      }

      final shareText =
          'EcoPin Citizen Report: "${report.title}" in Pasig City.\n\n'
          'Track resolution progress or report issues in your barangay using the link below.\n\n'
          'Web link: $shareUrl\n\n'
          '#EcoPin #PasigCity #CleanCommunities #CivicAction';

      await Share.shareXFiles(
        [XFile(finalSharePath)],
        text: shareText,
        subject: 'EcoPin Report: ${report.title}',
      );
    } catch (e) {
      SnackbarHelper.showError('Could not share report evidence: $e');
    }
  }

  static Future<String?> _generateShareCard({
    required String photoPath,
    required ReportModel report,
    required String shareUrl,
    required String outputPath,
  }) async {
    final rawBytes = await File(photoPath).readAsBytes();
    var srcPhoto = img.decodeImage(rawBytes);
    if (srcPhoto == null) return null;
    srcPhoto = img.bakeOrientation(srcPhoto);

    // High-resolution 3:4 portrait canvas (1080 x 1440)
    const cardW = 1080;
    const cardH = 1440;
    final card = img.Image(width: cardW, height: cardH);
    img.fill(card, color: img.ColorRgba8(10, 13, 20, 255)); // Obsidian matte

    // 1. Minimal Masthead
    img.drawString(
      card,
      'ECOPIN',
      font: img.arial24,
      x: 56,
      y: 50,
      color: img.ColorRgba8(255, 255, 255, 255),
    );
    img.drawString(
      card,
      '•  PASIG CITY CIVIC ACTION',
      font: img.arial14,
      x: 170,
      y: 58,
      color: img.ColorRgba8(100, 116, 139, 255),
    );

    // Top-right status pill capsule
    final isResolved = report.status.toLowerCase() == 'resolved';
    final pillBg = img.ColorRgba8(18, 24, 38, 255);
    _fillRoundedRect(
      card,
      x1: 820,
      y1: 44,
      x2: 1024,
      y2: 84,
      radius: 20,
      color: pillBg,
    );
    final dotColor = isResolved
        ? img.ColorRgba8(34, 197, 94, 255)
        : img.ColorRgba8(56, 189, 248, 255);
    _fillRoundedRect(
      card,
      x1: 838,
      y1: 60,
      x2: 846,
      y2: 68,
      radius: 4,
      color: dotColor,
    );
    final statusText = isResolved ? 'RESOLVED' : 'VERIFIED REPORT';
    img.drawString(
      card,
      statusText,
      font: img.arial14,
      x: 856,
      y: 56,
      color: isResolved
          ? img.ColorRgba8(34, 197, 94, 255)
          : img.ColorRgba8(226, 232, 240, 255),
    );

    // 2. Hero Photo (Dominates the canvas: 968 x 976 px)
    const photoBoxW = 968;
    const photoBoxH = 976;
    _fillRoundedRect(
      card,
      x1: 56,
      y1: 104,
      x2: 1024,
      y2: 1080,
      radius: 20,
      color: img.ColorRgba8(15, 20, 30, 255),
    );

    var photoResized = img.copyResize(
      srcPhoto,
      width: photoBoxW,
      maintainAspect: true,
    );
    if (photoResized.height > photoBoxH) {
      photoResized = img.copyResize(
        srcPhoto,
        height: photoBoxH,
        maintainAspect: true,
      );
    }
    final px = 56 + ((photoBoxW - photoResized.width) / 2).toInt();
    final py = 104 + ((photoBoxH - photoResized.height) / 2).toInt();
    img.compositeImage(card, photoResized, dstX: px, dstY: py);
    img.drawRect(
      card,
      x1: 56,
      y1: 104,
      x2: 1024,
      y2: 1080,
      color: img.ColorRgba8(31, 41, 55, 220),
    );

    // 3. Bottom Editorial Dispatch
    final category = (report.issueType ?? 'Civic Report').toUpperCase();
    img.drawString(
      card,
      category,
      font: img.arial14,
      x: 56,
      y: 1115,
      color: img.ColorRgba8(56, 189, 248, 255),
    );

    final title = report.title.length > 36
        ? '${report.title.substring(0, 33)}...'
        : report.title;
    img.drawString(
      card,
      title,
      font: img.arial24,
      x: 56,
      y: 1145,
      color: img.ColorRgba8(255, 255, 255, 255),
    );

    final dateStr = DateFormat(
      'MMMM d, yyyy • hh:mm a',
    ).format(report.createdAt.toLocal());
    img.drawString(
      card,
      'Pasig City  •  $dateStr',
      font: img.arial14,
      x: 56,
      y: 1195,
      color: img.ColorRgba8(148, 163, 184, 255),
    );

    final coordsStr =
        '${report.location.latitude.toStringAsFixed(5)}° N, ${report.location.longitude.toStringAsFixed(5)}° E';
    img.drawString(
      card,
      coordsStr,
      font: img.arial14,
      x: 56,
      y: 1225,
      color: img.ColorRgba8(100, 116, 139, 255),
    );

    img.drawString(
      card,
      'Track resolution progress or submit reports in your barangay',
      font: img.arial14,
      x: 56,
      y: 1270,
      color: img.ColorRgba8(148, 163, 184, 255),
    );
    img.drawString(
      card,
      'ecopin-web.vercel.app',
      font: img.arial14,
      x: 56,
      y: 1295,
      color: img.ColorRgba8(96, 165, 250, 255),
    );

    // Right Column: Minimalist Scannable QR Pass Stamp
    const qrCardX1 = 824;
    const qrCardY1 = 1112;
    const qrCardX2 = 1024;
    const qrCardY2 = 1332; // 200 x 220 px
    _fillRoundedRect(
      card,
      x1: qrCardX1,
      y1: qrCardY1,
      x2: qrCardX2,
      y2: qrCardY2,
      radius: 16,
      color: img.ColorRgba8(255, 255, 255, 255),
    );

    final qrCode = QrCode.fromData(
      data: shareUrl,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    final moduleCount = qrImage.moduleCount;
    const qrMargin = 16;
    final qrBoxW = 200 - (qrMargin * 2); // 168px
    final moduleSize = qrBoxW / moduleCount;
    final qx = qrCardX1 + qrMargin;
    final qy = qrCardY1 + qrMargin;

    for (int r = 0; r < moduleCount; r++) {
      for (int c = 0; c < moduleCount; c++) {
        if (qrImage.isDark(r, c)) {
          final mx1 = (qx + c * moduleSize).floor();
          final my1 = (qy + r * moduleSize).floor();
          final mx2 = (qx + (c + 1) * moduleSize).ceil();
          final my2 = (qy + (r + 1) * moduleSize).ceil();
          img.fillRect(
            card,
            x1: mx1,
            y1: my1,
            x2: mx2,
            y2: my2,
            color: img.ColorRgba8(15, 23, 42, 255),
          );
        }
      }
    }

    img.drawString(
      card,
      'SCAN TO VIEW',
      font: img.arial14,
      x: qrCardX1 + ((200 - 92) / 2).toInt(),
      y: qrCardY1 + qrBoxW + qrMargin + 8,
      color: img.ColorRgba8(15, 23, 42, 255),
    );

    // 4. Delicate Footer Hairline
    img.fillRect(
      card,
      x1: 56,
      y1: 1370,
      x2: 1024,
      y2: 1371,
      color: img.ColorRgba8(26, 34, 52, 255),
    );
    img.drawString(
      card,
      'CITIZEN TRANSPARENCY & ENVIRONMENTAL PROTECTION',
      font: img.arial14,
      x: 56,
      y: 1390,
      color: img.ColorRgba8(71, 85, 105, 255),
    );
    img.drawString(
      card,
      'PASIG CITY',
      font: img.arial14,
      x: 935,
      y: 1390,
      color: img.ColorRgba8(71, 85, 105, 255),
    );

    // Save final card image to temp directory
    final cardFile = File(outputPath);
    final jpgBytes = img.encodeJpg(card, quality: 92);
    await cardFile.writeAsBytes(jpgBytes);

    return cardFile.path;
  }

  static void _fillRoundedRect(
    img.Image image, {
    required int x1,
    required int y1,
    required int x2,
    required int y2,
    required int radius,
    required img.Color color,
  }) {
    final r = radius
        .clamp(1, ((x2 - x1) / 3).floor())
        .clamp(1, ((y2 - y1) / 3).floor())
        .toInt();
    for (int y = y1; y <= y2; y++) {
      int dx = 0;
      if (y < y1 + r) {
        final dy = (y1 + r) - y;
        dx = (r - math.sqrt(r * r - dy * dy)).round();
      } else if (y > y2 - r) {
        final dy = y - (y2 - r);
        dx = (r - math.sqrt(r * r - dy * dy)).round();
      }
      final curX1 = (x1 + dx).clamp(0, image.width);
      final curX2 = (x2 - dx).clamp(0, image.width);
      if (curX2 > curX1 && y >= 0 && y < image.height) {
        img.fillRect(
          image,
          x1: curX1,
          y1: y,
          x2: curX2,
          y2: y + 1,
          color: color,
        );
      }
    }
  }
}
