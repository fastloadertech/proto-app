import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/proto_brand.dart';
import '../../../core/widgets/proto_button.dart';

/// Local, explicit demo sign-in; no authentication service is connected.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    _phoneFocus.unfocus();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ProtoColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            4,
            24,
            28 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: ProtoColors.lime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: ProtoColors.lime,
                  size: 24,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Demo sign-in',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: ProtoColors.text,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '+91 ${_phoneController.text}',
                style: const TextStyle(
                  color: ProtoColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No OTP is sent. You can explore the local demo catalog '
                'without creating an account.',
                style: TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ProtoButton(
                  label: 'Enter Proto',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    widget.onContinue();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPolicy({required bool privacy}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ProtoColors.surface,
        scrollable: true,
        title: Text(privacy ? 'Demo privacy' : 'Demo terms'),
        content: Text(
          privacy
              ? 'This Day 1 demo keeps your phone number only in this screen. '
                    'It is not sent to a server or saved. The catalog uses '
                    'local sample products.'
              : 'Proto is a local product browsing demo. Prices, products, '
                    'availability, and delivery times are examples. '
                    'No purchases, payments, or real deliveries are made.',
          style: const TextStyle(color: ProtoColors.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProtoColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      const ProtoBrand(size: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ProtoColors.surface,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: ProtoColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: ProtoColors.lime,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'FUEL. FAST.',
                              style: TextStyle(
                                color: ProtoColors.text,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Your goals.',
                    style: TextStyle(
                      color: ProtoColors.text,
                      fontSize: 44,
                      height: 1.06,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.2,
                    ),
                  ),
                  const Text(
                    'Delivered.',
                    style: TextStyle(
                      color: ProtoColors.lime,
                      fontSize: 44,
                      height: 1.06,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The good stuff for your next rep.\nProtein, nutrition & everyday essentials.',
                    style: TextStyle(
                      color: ProtoColors.muted,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _PerformanceGraphic(),
                  const SizedBox(height: 28),
                  const Text(
                    'Let’s get you fueled.',
                    style: TextStyle(
                      color: ProtoColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your mobile number to get started.',
                    style: TextStyle(color: ProtoColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _continue(),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: const TextStyle(
                        color: ProtoColors.text,
                        fontSize: 16,
                        letterSpacing: 0.7,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Mobile number',
                        hintStyle: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 14,
                          letterSpacing: 0,
                        ),
                        filled: true,
                        fillColor: ProtoColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        prefixIcon: const SizedBox(
                          width: 68,
                          child: Center(
                            child: Text(
                              '+91',
                              style: TextStyle(
                                color: ProtoColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: ProtoColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: ProtoColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: ProtoColors.lime),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length != 10) {
                          return 'Enter a 10-digit mobile number.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ProtoButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _continue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'LOCAL DEMO · NO OTP REQUIRED',
                      style: TextStyle(
                        color: ProtoColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: widget.onContinue,
                      child: const Text(
                        'Explore as guest',
                        style: TextStyle(
                          color: ProtoColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _showPolicy(privacy: false),
                        child: const Text(
                          'Demo terms',
                          style: TextStyle(
                            color: ProtoColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Text(
                        '·',
                        style: TextStyle(color: ProtoColors.muted),
                      ),
                      TextButton(
                        onPressed: () => _showPolicy(privacy: true),
                        child: const Text(
                          'Privacy',
                          style: TextStyle(
                            color: ProtoColors.muted,
                            fontSize: 11,
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
      ),
    );
  }
}

class _PerformanceGraphic extends StatelessWidget {
  const _PerformanceGraphic();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: ProtoColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ProtoColors.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PulsePainter())),
            Positioned(
              top: 20,
              left: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BUILT FOR\nYOUR EVERYDAY.',
                    style: TextStyle(
                      color: ProtoColors.text,
                      fontSize: 17,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ProtoColors.lime,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'ONE MORE REP.',
                      style: TextStyle(
                        color: ProtoColors.background,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(right: 44, top: 33, child: _DumbbellMark()),
          ],
        ),
      ),
    );
  }
}

class _DumbbellMark extends StatelessWidget {
  const _DumbbellMark();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -math.pi / 5,
      child: const Icon(
        Icons.fitness_center_rounded,
        size: 64,
        color: ProtoColors.lime,
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 74, size.height / 2);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ProtoColors.lime.withValues(alpha: 0.16);
    for (final radius in [46.0, 68.0, 90.0]) {
      canvas.drawCircle(center, radius, ring);
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 68),
      -math.pi / 2,
      math.pi / 3,
      false,
      Paint()
        ..color = ProtoColors.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center + const Offset(0, -68),
      4,
      Paint()..color = ProtoColors.lime,
    );
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) => false;
}
