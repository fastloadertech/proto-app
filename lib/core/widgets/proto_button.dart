import 'package:flutter/material.dart';

import '../theme/proto_theme.dart';

class ProtoButton extends StatelessWidget {
  const ProtoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Text(label, textAlign: TextAlign.center)),
        if (icon != null) ...[const SizedBox(width: 10), Icon(icon, size: 19)],
      ],
    );
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ProtoColors.text,
          minimumSize: const Size(0, 54),
          side: const BorderSide(color: ProtoColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        child: child,
      );
    }
    return FilledButton(onPressed: onPressed, child: child);
  }
}
