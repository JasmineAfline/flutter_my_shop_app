import 'package:flutter/material.dart';

class TitlesTextWidget extends StatelessWidget {
  const TitlesTextWidget({
    super.key,
    required this.label,
    this.fontSize = 20,
    this.color,
    this.maxLines,
    this.fontWeight = FontWeight.bold,
  });

  final String label;
  final double fontSize;
  final Color? color;
  final int? maxLines;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Text(
      label,
      maxLines: maxLines,
      style: TextStyle(
        color: color ?? (isDark ? Colors.white : Colors.black87),
        fontSize: fontSize,
        fontWeight: fontWeight,
        overflow: TextOverflow.ellipsis,
        letterSpacing: -0.5,
      ),
    );
  }
}
