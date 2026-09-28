import 'package:flutter/material.dart';

import '../theme/proto_theme.dart';

class ProtoBrand extends StatelessWidget {
  const ProtoBrand({super.key, this.size = 26, this.compact = false});
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Proto',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.18,
          child: Icon(
            Icons.bolt_rounded,
            color: ProtoColors.lime,
            size: size * 1.12,
          ),
        ),
        if (!compact) ...[
          SizedBox(width: size * .12),
          Text(
            'proto',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w900,
              fontSize: size,
              letterSpacing: -size * .055,
              height: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: size * .13, top: size * .13),
            child: Container(
              width: size * .13,
              height: size * .13,
              color: ProtoColors.lime,
            ),
          ),
        ],
      ],
    ),
  );
}
