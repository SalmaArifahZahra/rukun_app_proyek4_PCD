// lib/widgets/kk_scanner_overlay.dart

import 'package:flutter/material.dart';
import 'package:rukun_app_proyek4/services/pcd/document_detector_v2.dart';
import 'package:rukun_app_proyek4/services/pcd/realtime_kk_scanner.dart';

class KKScannerOverlay extends StatefulWidget {
  final RealtimeScanResult? scanResult;
  final VoidCallback? onCapture;

  const KKScannerOverlay({super.key, this.scanResult, this.onCapture});

  @override
  State<KKScannerOverlay> createState() => _KKScannerOverlayState();
}

class _KKScannerOverlayState extends State<KKScannerOverlay>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(
        scanResult: widget.scanResult,
        animValue: _pulseController.value,
      ),
      child: _buildStatusBar(),
    );
  }

  Widget _buildStatusBar() {
    final result = widget.scanResult;
    final Color color;
    final String message;

    if (result == null || result.status == RealtimeScanStatus.noDocument) {
      color = Colors.white60;
      message = 'Arahkan ke Kartu Keluarga';
    } else if (result.status == RealtimeScanStatus.lowConfidence) {
      color = Colors.orange;
      message = result.message ?? 'Perbaiki posisi';
    } else if (result.status == RealtimeScanStatus.documentFound) {
      color = Colors.yellow;
      message = 'KK terdeteksi... ${(result.confidence * 100).toInt()}%';
    } else {
      color = Colors.green;
      message = 'Siap! Ambil gambar';
    }

    return Positioned(
      bottom: 100,
      left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

class _OverlayPainter extends CustomPainter {
  final RealtimeScanResult? scanResult;
  final double animValue;

  _OverlayPainter({this.scanResult, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Background gelap dengan lubang di tengah (guide frame)
    final bgPaint = Paint()..color = Colors.black45;

    // Guide rectangle: 85% lebar, 60% tinggi, di tengah
    final guideW = size.width * 0.85;
    final guideH = guideW / 1.4; // Aspect ratio KK landscape
    final guideX = (size.width - guideW) / 2;
    final guideY = (size.height - guideH) / 2;
    final guideRect = Rect.fromLTWH(guideX, guideY, guideW, guideH);

    // Draw overlay dengan hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(guideRect, const Radius.circular(12)));
    canvas.drawPath(path, bgPaint..blendMode = BlendMode.srcOver);

    // Corner indicators
    final cornerColor = _getCornerColor();
    final cornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLen = 20.0;

    // Top-left corner
    canvas.drawLine(Offset(guideX, guideY + cornerLen), Offset(guideX, guideY), cornerPaint);
    canvas.drawLine(Offset(guideX, guideY), Offset(guideX + cornerLen, guideY), cornerPaint);

    // Top-right corner
    canvas.drawLine(Offset(guideX + guideW - cornerLen, guideY), Offset(guideX + guideW, guideY), cornerPaint);
    canvas.drawLine(Offset(guideX + guideW, guideY), Offset(guideX + guideW, guideY + cornerLen), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(Offset(guideX, guideY + guideH - cornerLen), Offset(guideX, guideY + guideH), cornerPaint);
    canvas.drawLine(Offset(guideX, guideY + guideH), Offset(guideX + cornerLen, guideY + guideH), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(Offset(guideX + guideW - cornerLen, guideY + guideH), Offset(guideX + guideW, guideY + guideH), cornerPaint);
    canvas.drawLine(Offset(guideX + guideW, guideY + guideH), Offset(guideX + guideW, guideY + guideH - cornerLen), cornerPaint);

    // Animasi scanning line
    if (scanResult?.status == RealtimeScanStatus.documentFound) {
      final scanY = guideY + guideH * animValue;
      final scanPaint = Paint()
        ..color = Colors.green.withOpacity(0.6)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(guideX, scanY),
        Offset(guideX + guideW, scanY),
        scanPaint,
      );
    }

    // Draw detected quad overlay
    if (scanResult?.quad != null) {
      _drawDetectedQuad(canvas, size, scanResult!.quad!);
    }
  }

  void _drawDetectedQuad(Canvas canvas, Size size, DocumentQuad quad) {
    final scale = Offset(
      size.width / quad.imageWidth,
      size.height / quad.imageHeight,
    );

    final path = Path()
      ..moveTo(quad.topLeft.dx * scale.dx, quad.topLeft.dy * scale.dy)
      ..lineTo(quad.topRight.dx * scale.dx, quad.topRight.dy * scale.dy)
      ..lineTo(quad.bottomRight.dx * scale.dx, quad.bottomRight.dy * scale.dy)
      ..lineTo(quad.bottomLeft.dx * scale.dx, quad.bottomLeft.dy * scale.dy)
      ..close();

    canvas.drawPath(path, Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill);

    canvas.drawPath(path, Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  Color _getCornerColor() {
    switch (scanResult?.status) {
      case RealtimeScanStatus.documentFound: return Colors.yellow;
      case RealtimeScanStatus.readyToCapture: return Colors.green;
      default: return Colors.white;
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.scanResult != scanResult || old.animValue != animValue;
}