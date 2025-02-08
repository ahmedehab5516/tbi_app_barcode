import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final void Function()? onTap;
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final double? padding;
  final TextStyle? textStyle;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final double margin;

  const MyButton({
    super.key,
    required this.onTap,
    required this.label,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
    this.borderRadius = 10.0,
    this.padding = 12.0, // Adjusted to a default padding
    this.textStyle,
    this.isFullWidth = true,
    this.width,
    this.height,
    this.margin = 10.0, // Adjusted margin to be more standard
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : width,
        height: height,
        padding: EdgeInsets.all(padding!),
        margin: EdgeInsets.symmetric(horizontal: margin),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius!),
        ),
        child: Center(
          child: Text(
            label,
            style: textStyle ??
                TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
        ),
      ),
    );
  }
}
