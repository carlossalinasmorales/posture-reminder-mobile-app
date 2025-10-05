import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';
import 'day_selector_chip.dart';

/// Card de opciones personalizadas de frecuencia
class CustomFrequencyOptions extends StatelessWidget {
  final List<int> selectedDays;
  final int? customInterval;
  final Function(List<int>) onDaysChanged;
  final Function(int?) onIntervalChanged;

  const CustomFrequencyOptions({
    super.key,
    required this.selectedDays,
    required this.customInterval,
    required this.onDaysChanged,
    required this.onIntervalChanged,
  });

  void _onDaySelected(int day, bool selected) {
    final newDays = List<int>.from(selectedDays);
    if (selected) {
      newDays.add(day);
      onIntervalChanged(null); // Limpiar intervalo si se selecciona día
    } else {
      newDays.remove(day);
    }
    newDays.sort();
    onDaysChanged(newDays);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: kDefaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opciones personalizadas', style: kSubtitleTextStyle),
            const SizedBox(height: kDefaultPadding),
            Text(
              'Selecciona días de la semana:',
              style: kBodyTextStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: kSmallPadding),
            Wrap(
              spacing: kSmallPadding,
              runSpacing: kSmallPadding,
              children: [
                DaySelectorChip(
                  label: 'L',
                  day: 1,
                  isSelected: selectedDays.contains(1),
                  onSelected: (selected) => _onDaySelected(1, selected),
                ),
                DaySelectorChip(
                  label: 'M',
                  day: 2,
                  isSelected: selectedDays.contains(2),
                  onSelected: (selected) => _onDaySelected(2, selected),
                ),
                DaySelectorChip(
                  label: 'X',
                  day: 3,
                  isSelected: selectedDays.contains(3),
                  onSelected: (selected) => _onDaySelected(3, selected),
                ),
                DaySelectorChip(
                  label: 'J',
                  day: 4,
                  isSelected: selectedDays.contains(4),
                  onSelected: (selected) => _onDaySelected(4, selected),
                ),
                DaySelectorChip(
                  label: 'V',
                  day: 5,
                  isSelected: selectedDays.contains(5),
                  onSelected: (selected) => _onDaySelected(5, selected),
                ),
                DaySelectorChip(
                  label: 'S',
                  day: 6,
                  isSelected: selectedDays.contains(6),
                  onSelected: (selected) => _onDaySelected(6, selected),
                ),
                DaySelectorChip(
                  label: 'D',
                  day: 7,
                  isSelected: selectedDays.contains(7),
                  onSelected: (selected) => _onDaySelected(7, selected),
                ),
              ],
            ),
            const SizedBox(height: kLargePadding),
            Text(
              'O repite cada:',
              style: kBodyTextStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: kSmallPadding),
            TextFormField(
              initialValue: customInterval?.toString() ?? '',
              keyboardType: TextInputType.number,
              style: kBodyTextStyle,
              decoration: kTextFieldDecoration.copyWith(
                hintText: 'Número',
                suffixText: 'días',
              ),
              onChanged: (value) {
                final interval = int.tryParse(value);
                onIntervalChanged(interval);
                if (interval != null) {
                  onDaysChanged([]); // Limpiar días si se ingresa intervalo
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
