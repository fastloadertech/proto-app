import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/proto_brand.dart';

/// The first, deliberately brief introduction to Proto.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final Timer _timer;
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..forward();
    _timer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtoColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 520;
            final verticalPadding = compact ? 16.0 : 28.0;
            final artworkSize = compact
                ? (constraints.maxHeight * .3).clamp(96.0, 152.0).toDouble()
                : 242.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        0.0,
                        constraints.maxHeight - verticalPadding * 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Align(
                          alignment: Alignment.topLeft,
                          child: ProtoBrand(size: 30),
                        ),
                        SizedBox(height: compact ? 16 : 24),
                        FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _animation,
                            curve: Curves.easeOut,
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                width: artworkSize,
                                height: artworkSize,
                                child: AnimatedBuilder(
                                  animation: _animation,
                                  builder: (context, child) => CustomPaint(
                                    painter: _EnergyPainter(_animation.value),
                                    child: child,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.bolt_rounded,
                                      color: ProtoColors.lime,
                                      size: artworkSize * .4,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 12 : 32),
                              Text(
                                'FUEL YOUR NEXT.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ProtoColors.text,
                                  fontSize: compact ? 26 : 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.3,
                                ),
                              ),
                              SizedBox(height: compact ? 8 : 12),
                              Text(
                                'Protein. Performance.\nAt your doorstep.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ProtoColors.muted,
                                  fontSize: compact ? 14 : 16,
                                  height: compact ? 1.4 : 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              size: 16,
                              color: ProtoColors.lime,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'YOUR DAILY DOSE OF GO.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ProtoColors.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EnergyPainter extends CustomPainter {
  const _EnergyPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final fill = Paint()
      ..shader = RadialGradient(
        colors: [
          ProtoColors.lime.withValues(alpha: 0.09),
          ProtoColors.lime.withValues(alpha: 0.01),
          ProtoColors.background,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, radius, fill);

    final ring = Paint()
      ..color = ProtoColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.83, ring);
    canvas.drawCircle(center, radius * 0.6, ring);
    final active = Paint()
      ..color = ProtoColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.83),
      -math.pi / 2,
      math.pi * 0.7 * progress,
      false,
      active,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.6),
      math.pi * 0.6,
      math.pi * 0.35 * progress,
      false,
      active,
    );
    final angle = -math.pi / 2 + math.pi * 0.7 * progress;
    canvas.drawCircle(
      center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.83,
      5,
      Paint()..color = ProtoColors.lime,
    );
  }

  @override
  bool shouldRepaint(_EnergyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
