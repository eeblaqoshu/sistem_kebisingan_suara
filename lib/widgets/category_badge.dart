import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge visual tri-faktor (Warna + Ikon + Teks) sesuai standar aksesibilitas lapangan
class CategoryBadge extends StatelessWidget {
  final String category;
  final double fontSize;
  final EdgeInsets padding;

  const CategoryBadge({
    super.key,
    required this.category,
    this.fontSize = 13.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorForCategory(category);
    final bgColor = AppTheme.bgColorForCategory(category);
    final label = AppTheme.labelForCategory(category);
    final icon = AppTheme.iconForCategory(category);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: fontSize + 3),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
