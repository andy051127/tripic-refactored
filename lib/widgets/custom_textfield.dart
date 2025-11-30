import 'package:flutter/material.dart';

enum ValidationState { none, success, error }

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final ValidationState validationState;
  final String? validationMessage;
  final Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.validationState = ValidationState.none,
    this.validationMessage,
    this.onChanged,
  });

  Color _getBorderColor() {
    switch (validationState) {
      case ValidationState.success:
        return Colors.green;
      case ValidationState.error:
        return Colors.red;
      case ValidationState.none:
        return Colors.grey[300]!;
    }
  }

  Color _getMessageColor() {
    switch (validationState) {
      case ValidationState.success:
        return Colors.green;
      case ValidationState.error:
        return Colors.red;
      case ValidationState.none:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            obscureText: isPassword,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: _getBorderColor(), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: _getBorderColor(), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (validationMessage != null && validationMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                validationMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: _getMessageColor(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
