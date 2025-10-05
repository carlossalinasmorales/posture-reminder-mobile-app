import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '/../../theme/app_styles.dart';

/// Modal personalizado para seleccionar la hora
class TimePickerModal extends StatefulWidget {
  final DateTime initialDateTime;
  final Function(TimeOfDay) onConfirm;

  const TimePickerModal({
    super.key,
    required this.initialDateTime,
    required this.onConfirm,
  });

  @override
  State<TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          // Header con botones
          Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(kDefaultBorderRadius),
                topRight: Radius.circular(kDefaultBorderRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: kWhiteColor),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: kWhiteColor,
                    borderRadius: BorderRadius.circular(kDefaultBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      widget.onConfirm(selectedTime);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding,
                        vertical: kSmallPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
                      ),
                    ),
                    child: Text(
                      'Confirmar',
                      style: kBodyTextStyle.copyWith(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Indicador de hora en tiempo real
          Container(
            padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding,
                    vertical: kSmallPadding,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(kDefaultBorderRadius),
                    border: Border.all(color: kPrimaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: kPrimaryColor,
                        size: kMediumIconSize,
                      ),
                      const SizedBox(width: kSmallPadding),
                      Text(
                        'Hora: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: kBodyTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Picker de hora
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: widget.initialDateTime,
              use24hFormat: true,
              onDateTimeChanged: (DateTime newTime) {
                setState(() {
                  selectedTime = TimeOfDay.fromDateTime(newTime);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Función helper para mostrar el modal
Future<void> showTimePickerModal({
  required BuildContext context,
  required DateTime initialDateTime,
  required Function(TimeOfDay) onConfirm,
}) async {
  await showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return TimePickerModal(
        initialDateTime: initialDateTime,
        onConfirm: onConfirm,
      );
    },
  );
}