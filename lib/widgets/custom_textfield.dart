import 'package:flutter/material.dart';

enum ValidationState { none, success, error }

class CustomTextField extends StatefulWidget {
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

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  Color _getBorderColor() {
    switch (widget.validationState) {
      case ValidationState.success:
        return Colors.green;
      case ValidationState.error:
        return Colors.red;
      case ValidationState.none:
        return Colors.grey[300]!;
    }
  }

  Color _getMessageColor() {
    switch (widget.validationState) {
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
            controller: widget.controller,
            obscureText: _obscureText,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
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
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
            ),
          ),
          if (widget.validationMessage != null &&
              widget.validationMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                widget.validationMessage!,
                style: TextStyle(fontSize: 12, color: _getMessageColor()),
              ),
            ),
        ],
      ),
    );
  }
}
