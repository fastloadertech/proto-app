import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/catalog/domain/product.dart';

/// Resolution-independent packaging artwork, drawn entirely on-device.
///
/// The same illustration scales from a compact catalog card to the product
/// detail hero, without assets, network requests, or image dependencies.
class ProductArtwork extends StatelessWidget {
  const ProductArtwork({
    super.key,
    required this.product,
    this.size,
    this.showGlow = true,
  });

  final Product product;
  final double? size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${product.name} packaging',
      child: SizedBox(
        width: size ?? 180,
        height: size ?? 180,
        child: CustomPaint(
          painter: _ProductPackagingPainter(
            product: product,
            showGlow: showGlow,
          ),
        ),
      ),
    );
  }
}

class _ProductPackagingPainter extends CustomPainter {
  const _ProductPackagingPainter({
    required this.product,
    required this.showGlow,
  });

  final Product product;
  final bool showGlow;

  static const _ink = Color(0xFF171B19);
  static const _paper = Color(0xFFF7F9F2);
  static const _muted = Color(0xFF9AACA2);

  Color get _accent => product.accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const artWidth = 260.0;
    const artHeight = 300.0;
    final scale = math.min(size.width / artWidth, size.height / artHeight);
    canvas.save();
    canvas.translate(
      (size.width - artWidth * scale) / 2,
      (size.height - artHeight * scale) / 2,
    );
    canvas.scale(scale);

    if (showGlow) {
      const glowBounds = Rect.fromLTWH(15, 28, 230, 246);
      canvas.drawOval(
        glowBounds,
        Paint()
          ..shader = RadialGradient(
            colors: [
              _accent.withValues(alpha: 0.18),
              _accent.withValues(alpha: 0),
            ],
            stops: const [0, 1],
          ).createShader(glowBounds),
      );
    }

    switch (product.form) {
      case ProductForm.tub:
        _paintTub(canvas);
      case ProductForm.pouch:
        _paintPouch(canvas);
      case ProductForm.bar:
        _paintBar(canvas);
      case ProductForm.bottle:
        _paintBottle(canvas);
    }
    canvas.restore();
  }

  void _shadow(Canvas canvas, Rect bounds, {double alpha = 0.16}) {
    canvas.drawOval(
      bounds,
      Paint()
        ..color = const Color(0xFF101B14).withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawOval(
      bounds.deflate(9),
      Paint()
        ..color = const Color(0xFF101B14).withValues(alpha: alpha * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _paintTub(Canvas canvas) {
    _shadow(canvas, const Rect.fromLTWH(48, 248, 164, 18));

    final body = Path()
      ..moveTo(61, 69)
      ..quadraticBezierTo(55, 73, 55, 85)
      ..lineTo(55, 230)
      ..quadraticBezierTo(55, 248, 75, 252)
      ..quadraticBezierTo(130, 262, 185, 252)
      ..quadraticBezierTo(205, 248, 205, 230)
      ..lineTo(205, 85)
      ..quadraticBezierTo(205, 73, 199, 69)
      ..close();
    const bodyBounds = Rect.fromLTWH(55, 69, 150, 192);
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF363D37),
            Color(0xFF1B211D),
            Color(0xFF111713),
            Color(0xFF242B26),
          ],
          stops: [0, 0.25, 0.8, 1],
        ).createShader(bodyBounds),
    );

    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      const Rect.fromLTWH(55, 93, 150, 134),
      Paint()..color = const Color(0xFF1A211C),
    );
    canvas.drawRect(
      const Rect.fromLTWH(55, 91, 150, 5),
      Paint()..color = _accent,
    );
    final panel = Path()
      ..moveTo(164, 133)
      ..lineTo(214, 102)
      ..lineTo(214, 235)
      ..lineTo(144, 235)
      ..lineTo(174, 188)
      ..lineTo(149, 188)
      ..close();
    canvas.drawPath(panel, Paint()..color = _accent.withValues(alpha: 0.11));
    _brand(canvas, const Offset(71, 105), fontSize: 17, maxWidth: 118);

    final title = _titleLines;
    _text(
      canvas,
      title[0],
      const Offset(71, 138),
      fontSize: title[0].length > 7 ? 20 : 27,
      weight: FontWeight.w900,
      maxWidth: 119,
      letterSpacing: -0.8,
    );
    _text(
      canvas,
      title[1],
      const Offset(72, 168),
      fontSize: title[1].length > 10 ? 10.5 : 14,
      color: _accent,
      weight: FontWeight.w800,
      letterSpacing: 1.15,
      maxWidth: 118,
    );
    _text(
      canvas,
      product.flavors.first.toUpperCase(),
      const Offset(72, 191),
      fontSize: 6.8,
      color: _muted,
      letterSpacing: 1,
      maxWidth: 116,
    );
    canvas.drawLine(
      const Offset(72, 210),
      const Offset(189, 210),
      Paint()
        ..color = _paper.withValues(alpha: 0.16)
        ..strokeWidth = 0.6,
    );
    _text(
      canvas,
      _metricValue,
      const Offset(72, 216),
      fontSize: 17,
      weight: FontWeight.w800,
      maxWidth: 52,
    );
    _text(
      canvas,
      _metricLabel,
      const Offset(73, 237),
      fontSize: 5.7,
      color: _muted,
      letterSpacing: 0.65,
      maxWidth: 57,
    );
    _text(
      canvas,
      product.weightLabel.toUpperCase(),
      const Offset(145, 222),
      fontSize: 10,
      color: _paper.withValues(alpha: 0.85),
      weight: FontWeight.w700,
      maxWidth: 47,
      align: TextAlign.right,
    );
    canvas.drawRect(
      const Rect.fromLTWH(55, 74, 15, 184),
      Paint()
        ..shader = LinearGradient(
          colors: [_paper.withValues(alpha: 0.08), _paper.withValues(alpha: 0)],
        ).createShader(const Rect.fromLTWH(55, 74, 15, 184)),
    );
    canvas.drawRect(
      const Rect.fromLTWH(186, 74, 19, 184),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2)],
        ).createShader(const Rect.fromLTWH(186, 74, 19, 184)),
    );
    canvas.restore();

    final lid = RRect.fromRectAndRadius(
      const Rect.fromLTWH(49, 49, 162, 29),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      lid,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF454D45), Color(0xFF252B25), Color(0xFF0C120F)],
        ).createShader(lid.outerRect),
    );
    for (var x = 57.0; x <= 204; x += 6) {
      canvas.drawLine(
        Offset(x, 56),
        Offset(x, 73),
        Paint()
          ..color = _paper.withValues(alpha: x < 100 ? 0.11 : 0.04)
          ..strokeWidth = 1.1,
      );
    }
    const lidTop = Rect.fromLTWH(49, 40, 162, 21);
    canvas.drawOval(
      lidTop,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF485348), Color(0xFF242C25)],
        ).createShader(lidTop),
    );
    canvas.drawArc(
      lidTop.deflate(4),
      math.pi * 1.05,
      math.pi * 0.85,
      false,
      Paint()
        ..color = _paper.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintPouch(Canvas canvas) {
    _shadow(canvas, const Rect.fromLTWH(50, 255, 165, 17));
    final pouch = Path()
      ..moveTo(64, 42)
      ..quadraticBezierTo(130, 33, 195, 42)
      ..lineTo(204, 238)
      ..quadraticBezierTo(207, 254, 184, 260)
      ..quadraticBezierTo(130, 269, 76, 260)
      ..quadraticBezierTo(55, 255, 56, 238)
      ..close();
    const pouchBounds = Rect.fromLTWH(56, 37, 150, 230);
    canvas.drawPath(
      pouch,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF455045),
            Color(0xFF232C24),
            Color(0xFF151D17),
            Color(0xFF323B31),
          ],
          stops: [0, 0.2, 0.85, 1],
        ).createShader(pouchBounds),
    );
    canvas.save();
    canvas.clipPath(pouch);
    canvas.drawRect(
      const Rect.fromLTWH(56, 117, 150, 88),
      Paint()..color = _accent,
    );
    final stripe = Path()
      ..moveTo(164, 117)
      ..lineTo(210, 117)
      ..lineTo(173, 205)
      ..lineTo(128, 205)
      ..close();
    canvas.drawPath(stripe, Paint()..color = _ink.withValues(alpha: 0.07));
    _brand(canvas, const Offset(79, 72), fontSize: 19, maxWidth: 113);
    _text(
      canvas,
      'GOOD FUEL. EVERY DAY.',
      const Offset(80, 97),
      fontSize: 5.8,
      color: _muted,
      letterSpacing: 1,
      maxWidth: 112,
    );
    final title = _titleLines;
    _text(
      canvas,
      title[0],
      const Offset(75, 130),
      fontSize: title[0].length > 7 ? 18 : 27,
      weight: FontWeight.w900,
      color: _ink,
      maxWidth: 120,
      letterSpacing: -0.6,
    );
    _text(
      canvas,
      title[1],
      const Offset(76, 159),
      fontSize: title[1].length > 9 ? 11.5 : 16,
      color: _ink,
      weight: FontWeight.w800,
      letterSpacing: 0.8,
      maxWidth: 120,
    );
    _text(
      canvas,
      product.flavors.first.toUpperCase(),
      const Offset(77, 186),
      fontSize: 6.2,
      color: _ink.withValues(alpha: 0.8),
      letterSpacing: 0.7,
      maxWidth: 119,
    );
    _text(
      canvas,
      _metricValue,
      const Offset(77, 221),
      fontSize: 18,
      weight: FontWeight.w800,
      maxWidth: 52,
    );
    _text(
      canvas,
      _metricLabel,
      const Offset(78, 243),
      fontSize: 5.3,
      color: _muted,
      letterSpacing: 0.6,
      maxWidth: 67,
    );
    _text(
      canvas,
      product.weightLabel.toUpperCase(),
      const Offset(137, 231),
      fontSize: 8.5,
      weight: FontWeight.w700,
      maxWidth: 54,
      align: TextAlign.right,
    );
    final highlight = Path()
      ..moveTo(67, 57)
      ..lineTo(75, 56)
      ..lineTo(68, 242)
      ..lineTo(64, 250)
      ..close();
    canvas.drawPath(highlight, Paint()..color = _paper.withValues(alpha: 0.08));
    final fold = Path()
      ..moveTo(194, 47)
      ..lineTo(204, 244)
      ..lineTo(189, 251)
      ..lineTo(190, 57)
      ..close();
    canvas.drawPath(
      fold,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.restore();

    canvas.drawLine(
      const Offset(68, 47),
      const Offset(191, 47),
      Paint()
        ..color = _paper.withValues(alpha: 0.2)
        ..strokeWidth = 1.1,
    );
    canvas.drawLine(
      const Offset(68, 54),
      const Offset(191, 54),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(const Offset(66, 58), 2.3, Paint()..color = _ink);
    canvas.drawCircle(const Offset(193, 58), 2.3, Paint()..color = _ink);
  }

  void _paintBar(Canvas canvas) {
    _shadow(canvas, const Rect.fromLTWH(17, 219, 229, 16), alpha: 0.13);

    canvas.save();
    canvas.translate(130, 148);
    canvas.rotate(-0.14);
    canvas.translate(-130, -148);
    _barWrapper(canvas, const Rect.fromLTWH(33, 95, 199, 67), back: true);
    canvas.restore();

    canvas.save();
    canvas.translate(130, 175);
    canvas.rotate(0.06);
    canvas.translate(-130, -175);
    const bounds = Rect.fromLTWH(15, 143, 230, 76);
    _barWrapper(canvas, bounds);
    _brand(canvas, const Offset(38, 155), fontSize: 12.5, maxWidth: 116);
    _text(
      canvas,
      'PROTEIN BAR',
      const Offset(38, 178),
      fontSize: 14.7,
      weight: FontWeight.w900,
      maxWidth: 145,
      letterSpacing: -0.15,
    );
    _text(
      canvas,
      'CHOCOLATE PEANUT',
      const Offset(38, 199),
      fontSize: 5.3,
      color: _muted,
      letterSpacing: 0.7,
      maxWidth: 110,
    );
    _text(
      canvas,
      '20G',
      const Offset(179, 167),
      fontSize: 17,
      weight: FontWeight.w900,
      color: _ink,
      maxWidth: 43,
      align: TextAlign.center,
    );
    _text(
      canvas,
      'PROTEIN',
      const Offset(180, 188),
      fontSize: 5.5,
      weight: FontWeight.w700,
      color: _ink,
      letterSpacing: 0.7,
      maxWidth: 42,
      align: TextAlign.center,
    );
    canvas.restore();
  }

  void _barWrapper(Canvas canvas, Rect bounds, {bool back = false}) {
    final wrapper = Path()
      ..moveTo(bounds.left, bounds.top + 4)
      ..lineTo(bounds.left + 9, bounds.top)
      ..lineTo(bounds.right - 8, bounds.top)
      ..lineTo(bounds.right, bounds.top + 4)
      ..lineTo(bounds.right - 2, bounds.bottom - 4)
      ..lineTo(bounds.right - 10, bounds.bottom)
      ..lineTo(bounds.left + 7, bounds.bottom)
      ..lineTo(bounds.left + 1, bounds.bottom - 3)
      ..close();
    canvas.drawPath(
      wrapper,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: back
              ? [const Color(0xFF454F43), const Color(0xFF2C352A)]
              : [const Color(0xFF353D34), _ink, const Color(0xFF293227)],
        ).createShader(bounds),
    );
    canvas.save();
    canvas.clipPath(wrapper);
    final accentPanel = Path()
      ..moveTo(bounds.right - 62, bounds.top)
      ..lineTo(bounds.right, bounds.top)
      ..lineTo(bounds.right, bounds.bottom)
      ..lineTo(bounds.right - 77, bounds.bottom)
      ..close();
    canvas.drawPath(
      accentPanel,
      Paint()..color = back ? _accent.withValues(alpha: 0.65) : _accent,
    );
    canvas.drawLine(
      Offset(bounds.left + 11, bounds.top + 3),
      Offset(bounds.right - 12, bounds.top + 3),
      Paint()
        ..color = _paper.withValues(alpha: 0.17)
        ..strokeWidth = 1,
    );
    for (var x = 3.0; x <= 13; x += 2.5) {
      canvas.drawLine(
        Offset(bounds.left + x, bounds.top + 2),
        Offset(bounds.left + x, bounds.bottom - 2),
        Paint()..color = _paper.withValues(alpha: 0.11),
      );
      canvas.drawLine(
        Offset(bounds.right - x, bounds.top + 2),
        Offset(bounds.right - x, bounds.bottom - 2),
        Paint()..color = _ink.withValues(alpha: 0.18),
      );
    }
    if (back) {
      _text(
        canvas,
        'FUEL YOUR NEXT.',
        Offset(bounds.left + 25, bounds.top + 24),
        fontSize: 12,
        weight: FontWeight.w800,
        color: _paper.withValues(alpha: 0.65),
        maxWidth: 129,
      );
    }
    canvas.restore();
  }

  void _paintBottle(Canvas canvas) {
    _shadow(canvas, const Rect.fromLTWH(69, 256, 126, 16));
    final bottle = Path()
      ..moveTo(100, 57)
      ..lineTo(160, 57)
      ..lineTo(160, 72)
      ..quadraticBezierTo(181, 91, 181, 112)
      ..lineTo(181, 239)
      ..quadraticBezierTo(181, 258, 166, 262)
      ..quadraticBezierTo(130, 269, 94, 262)
      ..quadraticBezierTo(79, 258, 79, 239)
      ..lineTo(79, 112)
      ..quadraticBezierTo(79, 91, 100, 72)
      ..close();
    const bottleBounds = Rect.fromLTWH(79, 57, 102, 207);
    canvas.drawPath(
      bottle,
      Paint()
        ..shader = LinearGradient(
          colors: product.categoryId == 'hydration'
              ? const [
                  Color(0xFF344B50),
                  Color(0xFF1B3036),
                  Color(0xFF102329),
                  Color(0xFF30484E),
                ]
              : const [
                  Color(0xFF4A4731),
                  Color(0xFF2F3022),
                  Color(0xFF1B2118),
                  Color(0xFF363D29),
                ],
          stops: const [0, 0.23, 0.8, 1],
        ).createShader(bottleBounds),
    );
    canvas.save();
    canvas.clipPath(bottle);
    const labelBounds = Rect.fromLTWH(79, 115, 102, 113);
    canvas.drawRect(labelBounds, Paint()..color = _ink);
    canvas.drawRect(
      const Rect.fromLTWH(79, 115, 102, 5),
      Paint()..color = _accent,
    );
    _brand(canvas, const Offset(92, 131), fontSize: 12, maxWidth: 77);
    final title = _titleLines;
    _text(
      canvas,
      title[0],
      const Offset(91, 162),
      fontSize: 20,
      weight: FontWeight.w900,
      maxWidth: 80,
      letterSpacing: -0.5,
    );
    _text(
      canvas,
      title[1],
      const Offset(92, 187),
      fontSize: 13,
      weight: FontWeight.w800,
      color: _accent,
      maxWidth: 78,
      letterSpacing: 0.3,
    );
    _text(
      canvas,
      product.weightLabel.toUpperCase(),
      const Offset(92, 212),
      fontSize: 6.5,
      color: _muted,
      maxWidth: 78,
      letterSpacing: 0.7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(86, 91, 5, 154),
        const Radius.circular(3),
      ),
      Paint()..color = _paper.withValues(alpha: 0.08),
    );
    canvas.drawLine(
      const Offset(88, 236),
      const Offset(173, 236),
      Paint()
        ..color = _paper.withValues(alpha: 0.06)
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      const Offset(88, 246),
      const Offset(173, 246),
      Paint()
        ..color = _paper.withValues(alpha: 0.06)
        ..strokeWidth = 1.5,
    );
    canvas.restore();

    final cap = RRect.fromRectAndRadius(
      const Rect.fromLTWH(94, 39, 72, 25),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      cap,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF424B3F), Color(0xFF1E271E), Color(0xFF111C15)],
        ).createShader(cap.outerRect),
    );
    for (var x = 99.0; x < 164; x += 4) {
      canvas.drawLine(
        Offset(x, 44),
        Offset(x, 60),
        Paint()
          ..color = _paper.withValues(alpha: x < 129 ? 0.16 : 0.06)
          ..strokeWidth = 0.9,
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(94, 34, 72, 12),
      Paint()..color = const Color(0xFF414E40),
    );
    canvas.drawLine(
      const Offset(99, 65),
      const Offset(160, 65),
      Paint()
        ..color = _accent.withValues(alpha: 0.7)
        ..strokeWidth = 2,
    );
  }

  List<String> get _titleLines => switch (product.id) {
    'whey-isolate' => ['WHEY', 'ISOLATE'],
    'everyday-whey' => ['WHEY', 'EVERYDAY'],
    'plant-protein' => ['PLANT', 'PROTEIN'],
    'protein-bites' => ['PROTEIN', 'BITES'],
    'creatine-monohydrate' => ['CREATINE', 'MONOHYDRATE'],
    'ignite-preworkout' => ['IGNITE', 'PRE-WORKOUT'],
    'focus-preworkout' => ['FOCUS', 'PRE-WORKOUT'],
    'daily-greens' => ['DAILY', 'GREENS'],
    'omega-3' => ['OMEGA', '3'],
    'electrolyte-mix' => ['ELECTRO', 'LYTES'],
    'hydration-water' => ['HYDRA', 'FUEL'],
    _ => ['PROTO', 'FUEL'],
  };

  String get _metricValue => product.proteinGrams > 0
      ? '${product.proteinGrams}G'
      : product.categoryId == 'creatine'
      ? '3G'
      : '${product.servings}';

  String get _metricLabel => product.proteinGrams > 0
      ? 'PROTEIN / SERVE'
      : product.categoryId == 'creatine'
      ? 'PURE CREATINE'
      : 'SERVINGS';

  void _brand(
    Canvas canvas,
    Offset offset, {
    required double fontSize,
    required double maxWidth,
  }) {
    _text(
      canvas,
      'PROTO',
      offset,
      fontSize: fontSize,
      weight: FontWeight.w900,
      letterSpacing: 1.6,
      maxWidth: maxWidth,
    );
    final markX = offset.dx + fontSize * 4.2;
    final mark = Path()
      ..moveTo(markX + 4, offset.dy + 2)
      ..lineTo(markX + 12, offset.dy + 2)
      ..lineTo(markX + 7, offset.dy + fontSize * 0.6)
      ..lineTo(markX + 11, offset.dy + fontSize * 0.6)
      ..lineTo(markX + 1, offset.dy + fontSize)
      ..lineTo(markX + 5, offset.dy + fontSize * 0.45)
      ..lineTo(markX, offset.dy + fontSize * 0.45)
      ..close();
    canvas.drawPath(mark, Paint()..color = _accent);
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset, {
    required double fontSize,
    double maxWidth = 140,
    Color color = _paper,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0,
    TextAlign align = TextAlign.left,
  }) {
    final painter =
        TextPainter(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: fontSize,
              fontWeight: weight,
              letterSpacing: letterSpacing,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: align,
          maxLines: 1,
        )..layout(
          minWidth: align == TextAlign.right ? maxWidth : 0,
          maxWidth: maxWidth,
        );
    painter.paint(canvas, offset);
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _ProductPackagingPainter oldDelegate) {
    return oldDelegate.product != product || oldDelegate.showGlow != showGlow;
  }
}
