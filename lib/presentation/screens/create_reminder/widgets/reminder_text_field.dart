import 'package:flutter/material.dart';
import '/../../theme/app_styles.dart';

/// Widget reutilizable para campos de texto del formulario de recordatorios
class ReminderTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const ReminderTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: kDefaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: kBodyTextStyle,
          onChanged: onChanged,
          decoration: kTextFieldDecoration.copyWith(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: kPrimaryColor, size: kMediumIconSize),
          ),
          validator: validator,
        ),
      ),
    );
  }
}