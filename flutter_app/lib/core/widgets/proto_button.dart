import 'package:flutter/material.dart';

import '../theme/proto_theme.dart';

class ProtoButton extends StatelessWidget {
  const ProtoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Text(label, textAlign: TextAlign.center)),
        if (loading) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? ProtoColors.lime : ProtoColors.background,
            ),
          ),
        ] else if (icon != null) ...[
          const SizedBox(width: 10),
          Icon(icon, size: 19),
        ],
      ],
    );
    if (outlined) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
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
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: loading
          ? FilledButton.styleFrom(
              disabledBackgroundColor: ProtoColors.lime,
              disabledForegroundColor: ProtoColors.background,
            )
          : null,
      child: child,
    );
  }
}
