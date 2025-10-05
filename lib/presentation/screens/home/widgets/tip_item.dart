import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class TipItem extends StatelessWidget {
  final String text;

  const TipItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: kSuccessColor,
            size: 26,
          ),
          const SizedBox(width: kDefaultPadding),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: kSmallFontSize,
                color: Color(0xFF4A4A4A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
