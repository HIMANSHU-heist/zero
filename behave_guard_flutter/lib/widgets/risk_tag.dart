// lib/widgets/risk_tag.dart
import 'package:flutter/material.dart';

class RiskTag extends StatelessWidget {
  final String tier; // 'low' | 'medium' | 'high'
  final String? extra;
  const RiskTag(this.tier, {super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    switch (tier) {
      case 'high':
        fg = const Color(0xFFD63552);
        bg = const Color(0x1AD63552);
        break;
      case 'medium':
        fg = const Color(0xFFB9790A);
        bg = const Color(0x1AB9790A);
        break;
      default:
        fg = const Color(0xFF1A9B6C);
        bg = const Color(0x1A1A9B6C);
    }
    final label = extra != null
        ? '${tier.toUpperCase()} · $extra'
        : tier.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
