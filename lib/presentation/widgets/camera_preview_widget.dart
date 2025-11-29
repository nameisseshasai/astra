import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Widget displaying the camera preview with overlay effects
class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final bool isAnalyzing;
  final bool hasDanger;
  final int dangerLevel;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.isAnalyzing = false,
    this.hasDanger = false,
    this.dangerLevel = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return _buildPlaceholder();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CameraPreview(controller!),
        ),

        // Scanning overlay
        if (isAnalyzing) _buildScanningOverlay(),

        // Danger border overlay
        if (hasDanger) _buildDangerOverlay(),

        // Corner brackets
        _buildCornerBrackets(),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AstraTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AstraTheme.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: AstraTheme.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: TextStyle(color: AstraTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AstraTheme.primaryColor.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          // Scanning line animation
          Positioned.fill(child: _ScanningLine()),
        ],
      ),
    );
  }

  Widget _buildDangerOverlay() {
    final color = AstraTheme.getDangerColor(dangerLevel);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBrackets() {
    return CustomPaint(
      painter: CornerBracketsPainter(
        color: hasDanger
            ? AstraTheme.getDangerColor(dangerLevel)
            : AstraTheme.primaryColor,
        strokeWidth: 4,
        bracketLength: 40,
        cornerRadius: 24,
      ),
    );
  }
}

/// Animated scanning line widget
class _ScanningLine extends StatefulWidget {
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FractionallySizedBox(
          alignment: Alignment(0, (_animation.value * 2) - 1),
          heightFactor: 0.02,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AstraTheme.primaryColor.withValues(alpha: 0),
                  AstraTheme.primaryColor.withValues(alpha: 0.8),
                  AstraTheme.primaryColor.withValues(alpha: 0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AstraTheme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for corner brackets
class CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double bracketLength;
  final double cornerRadius;

  CornerBracketsPainter({
    required this.color,
    required this.strokeWidth,
    required this.bracketLength,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final offset = cornerRadius;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(offset, bracketLength)
        ..lineTo(offset, offset)
        ..lineTo(bracketLength, offset),
      paint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketLength, offset)
        ..lineTo(size.width - offset, offset)
        ..lineTo(size.width - offset, bracketLength),
      paint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(offset, size.height - bracketLength)
        ..lineTo(offset, size.height - offset)
        ..lineTo(bracketLength, size.height - offset),
      paint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketLength, size.height - offset)
        ..lineTo(size.width - offset, size.height - offset)
        ..lineTo(size.width - offset, size.height - bracketLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornerBracketsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
