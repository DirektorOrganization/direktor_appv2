import 'package:flutter/material.dart';

class DirektorLogo extends StatelessWidget {
  const DirektorLogo({
    super.key,
    this.size = 88,
    this.showLabel = false,
    this.labelColor,
  });

  static const assetPath = 'assets/Iimages/isotipoD.png';

  final double size;
  final bool showLabel;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final resolvedLabelColor = labelColor ?? const Color(0xFF1E2B3A);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => SizedBox(
            width: size,
            height: size,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: size * 0.10),
          Text(
            'DIREKTOR',
            style: TextStyle(
              color: resolvedLabelColor,
              fontSize: size * 0.20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}
