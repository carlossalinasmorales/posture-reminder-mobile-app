import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';
import 'tip_item.dart';

class TipsCard extends StatelessWidget {
  const TipsCard({super.key});

  static const _tips = [
    'Mantén la espalda recta y apoyada al sentarte',
    'Asegúrate que tus pies toquen el suelo firmemente',
    'Posiciona la pantalla a la altura de tus ojos',
    'Recuerda levantarte y estirar cada 30-60 minutos',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kLargeBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kLargePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            ..._tips.map((tip) => TipItem(text: tip)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: const [
        Icon(Icons.lightbulb_outline, color: Color(0xFFF39C12), size: 30),
        SizedBox(width: 12),
        Text(
          'Mejora tu Postura',
          style: TextStyle(
            fontSize: kMediumFontSize,
            fontWeight: FontWeight.bold,
            color: kContrastColor,
          ),
        ),
      ],
    );
  }
}
