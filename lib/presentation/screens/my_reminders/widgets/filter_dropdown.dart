import 'package:flutter/material.dart';
import '/../../theme/app_styles.dart';

/// Widget de dropdown para filtrar recordatorios por estado
class FilterDropdownWidget extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;

  const FilterDropdownWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  static const List<String> filterLabels = [
    'Todos',
    'Pendientes',
    'Completados',
    'Omitidos',
    'Aplazados',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Filtrar por estado:', style: kSubtitleTextStyle),
        const SizedBox(height: kSmallPadding),
        DropdownMenu<String>(
          initialSelection: currentFilter,
          width: MediaQuery.of(context).size.width - (kLargePadding * 2),
          label: const Text('Seleccionar estado'),
          trailingIcon: const Icon(Icons.filter_list,
              size: kLargeIconSize, color: kPrimaryColor),
          selectedTrailingIcon: const Icon(Icons.filter_list,
              size: kLargeIconSize, color: kPrimaryColor),
          textStyle: kBodyTextStyle.copyWith(
            fontSize: kMediumFontSize,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: kSmallPadding,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kDefaultBorderRadius),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kDefaultBorderRadius),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kDefaultBorderRadius),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
          ),
          menuStyle: MenuStyle(
            alignment: Alignment.bottomLeft,
            maximumSize: const MaterialStatePropertyAll(
              Size.fromHeight(300),
            ),
            backgroundColor: const MaterialStatePropertyAll(kWhiteColor),
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kDefaultBorderRadius),
                side: const BorderSide(color: kPrimaryColor, width: 1),
              ),
            ),
          ),
          onSelected: (String? newValue) {
            if (newValue != null) {
              onFilterChanged(newValue);
            }
          },
          dropdownMenuEntries: filterLabels.map((String value) {
            return DropdownMenuEntry<String>(
              value: value,
              label: value,
              style: MenuItemButton.styleFrom(
                foregroundColor:
                    currentFilter == value ? kPrimaryColor : kContrastColor,
                textStyle: kBodyTextStyle.copyWith(
                  fontSize: kMediumFontSize,
                  fontWeight: currentFilter == value
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
