import 'package:flutter/material.dart';
import '../models/signal_type.dart';
import '../models/signal_generator.dart';
import '../models/signal_parameters.dart';
import '../theme/app_theme.dart';

class WaveformPainter extends CustomPainter {
  final SignalType signalType;
  final SignalParameters parameters;
  final Color waveColor;
  final double animationValue;

  WaveformPainter({
    required this.signalType,
    required this.parameters,
    required this.waveColor,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw glow effect
    final glowPaint = Paint()
      ..color = waveColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Grid
    _drawGrid(canvas, size);

    // Generate samples
    final samples = SignalGenerator.generateSamples(
      signalType,
      parameters,
      sampleCount: 360,
    );

    // Create path
    final path = Path();
    final glowPath = Path();
    
    final centerY = size.height / 2;
    final scaleY = (size.height * 0.35) / parameters.amplitude;
    
    for (int i = 0; i < samples.length; i++) {
      final x = (i / samples.length) * size.width;
      final y = centerY - (samples[i] * scaleY);
      
      if (i == 0) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }

    // Draw glow
    canvas.drawPath(glowPath, glowPaint);
    
    // Draw waveform
    canvas.drawPath(path, paint);

    // Draw animated point
    final animatedIndex = (animationValue * samples.length).toInt() % samples.length;
    final pointX = (animatedIndex / samples.length) * size.width;
    final pointY = centerY - (samples[animatedIndex] * scaleY);
    
    final pointPaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(pointX, pointY),
      6,
      pointPaint,
    );

    // Draw outer glow circle
    final outerGlowPaint = Paint()
      ..color = waveColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(pointX, pointY),
      12,
      outerGlowPaint,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // Horizontal lines
    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Vertical lines
    for (int i = 0; i <= 8; i++) {
      final x = (size.width / 8) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Center line (thicker)
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.signalType != signalType ||
        oldDelegate.parameters != parameters ||
        oldDelegate.animationValue != animationValue;
  }
}

class AnimatedWaveformWidget extends StatefulWidget {
  final SignalType signalType;
  final SignalParameters parameters;
  final double height;

  const AnimatedWaveformWidget({
    Key? key,
    required this.signalType,
    required this.parameters,
    this.height = 200,
  }) : super(key: key);

  @override
  State<AnimatedWaveformWidget> createState() => _AnimatedWaveformWidgetState();
}

class _AnimatedWaveformWidgetState extends State<AnimatedWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getSignalColor() {
    switch (widget.signalType) {
      case SignalType.sine:
        return AppTheme.neonBlue;
      case SignalType.square:
        return AppTheme.neonPurple;
      case SignalType.triangle:
        return AppTheme.neonGreen;
      case SignalType.sawtooth:
        return AppTheme.neonOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getSignalColor().withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          AppTheme.neonGlow(_getSignalColor(), blur: 15),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: WaveformPainter(
                signalType: widget.signalType,
                parameters: widget.parameters,
                waveColor: _getSignalColor(),
                animationValue: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}
