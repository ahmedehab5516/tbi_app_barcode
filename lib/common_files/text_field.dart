import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData sendIcon;
  final IconData attachmentIcon;
  final Color sendButtonColor;
  final Color attachmentButtonColor;
  final Color fillColor;
  final Color hintTextColor;
  final Color borderColor;
  final TextInputType keyboardType;
  final String? Function(dynamic value)? validator; // Nullable validator
  final void Function(String)? onChanged;

  const MyTextField({
    super.key,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.hintText = 'Type a message...',
    this.sendIcon = Icons.send,
    this.attachmentIcon = Icons.attach_file,
    this.sendButtonColor = Colors.teal,
    this.attachmentButtonColor = Colors.teal,
    this.fillColor = const Color(0xFFE0E0E0),
    this.hintTextColor = const Color(0xFF9E9E9E),
    this.borderColor = const Color(0xFFBDBDBD),
    this.validator, this.onChanged, // Optional validator
  });

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      hintText: hintText,
      hintStyle: TextStyle(color: hintTextColor),
      fillColor: fillColor,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(color: borderColor),
      ),
    );

    return TextFormField(
      
      keyboardType: keyboardType,
      controller: controller,
      decoration: inputDecoration,
      onChanged: onChanged,
      validator: validator, // Use the validator if provided
    );
  }
}
