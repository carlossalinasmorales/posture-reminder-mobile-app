import 'dart:async';
import 'package:flutter/material.dart';
import '/../../theme/app_styles.dart';

/// Helper para mostrar indicador sutil de éxito
class SuccessIndicatorHelper {
  static void show(BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
              vertical: kSmallPadding,
            ),
            decoration: BoxDecoration(
              color: kSuccessColor,
              borderRadius: BorderRadius.circular(kLargeBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    color: kWhiteColor, size: kSmallIconSize),
                SizedBox(width: kSmallPadding),
                Text(
                  'Listo',
                  style: TextStyle(
                    color: kWhiteColor,
                    fontSize: kExtraSmallFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Timer(const Duration(milliseconds: 1500), () => overlayEntry?.remove());
  }
}
