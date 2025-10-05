import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 4,
        color: kPrimaryColor,
      ),
    );
  }
}
