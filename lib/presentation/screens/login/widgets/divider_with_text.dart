import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSmallPadding),
          child: Text(
            text,
            style: kBodyTextStyle.copyWith(color: Colors.grey[600]),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[400])),
      ],
    );
  }
}
