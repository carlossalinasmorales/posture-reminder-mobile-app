import 'package:flutter/material.dart';

// Colores principales
const Color kPrimaryColor = Color.fromARGB(255, 164, 112, 223);
const Color kContrastColor = Color(0xFF2C3E50); // Gris oscuro para texto
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kWhiteColor = Colors.white;
const Color kErrorColor = Colors.red;
const Color kSuccessColor = Colors.green;

// Tamaños de fuente
const double kLargeFontSize = 24.0;
const double kMediumFontSize = 20.0;
const double kSmallFontSize = 16.0;
const double kExtraSmallFontSize = 14.0;

// Tamaños de iconos
const double kLargeIconSize = 32.0;
const double kMediumIconSize = 24.0;
const double kSmallIconSize = 20.0;

// Espaciado
const double kDefaultPadding = 16.0;
const double kSmallPadding = 8.0;
const double kLargePadding = 24.0;
const double kExtraLargePadding = 32.0;

// Bordes redondeados
const double kDefaultBorderRadius = 12.0;
const double kLargeBorderRadius = 16.0;
const double kExtraLargeBorderRadius = 20.0;

// Elevación
const double kDefaultElevation = 2.0;
const double kMediumElevation = 4.0;
const double kHighElevation = 6.0;

// Estilos de texto
const TextStyle kTitleTextStyle = TextStyle(
  fontSize: kLargeFontSize,
  fontWeight: FontWeight.w900,
  color: kContrastColor,
);

const TextStyle kSubtitleTextStyle = TextStyle(
  fontSize: kMediumFontSize,
  fontWeight: FontWeight.bold,
  color: kContrastColor,
);

const TextStyle kBodyTextStyle = TextStyle(
  fontSize: kSmallFontSize,
  color: kContrastColor,
);

const TextStyle kCaptionTextStyle = TextStyle(
  fontSize: kExtraSmallFontSize,
  color: kContrastColor,
);

// Estilos de botones
final ButtonStyle kPrimaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: kPrimaryColor,
  foregroundColor: kWhiteColor,
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kDefaultBorderRadius),
  ),
  elevation: kDefaultElevation,
);

final ButtonStyle kSecondaryButtonStyle = OutlinedButton.styleFrom(
  foregroundColor: kPrimaryColor,
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
  side: const BorderSide(color: kPrimaryColor),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kDefaultBorderRadius),
  ),
);

// Estilos de tarjetas
final BoxDecoration kCardDecoration = BoxDecoration(
  color: kWhiteColor,
  borderRadius: BorderRadius.circular(kLargeBorderRadius),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

// Estilos de campos de texto
const InputDecoration kTextFieldDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(kDefaultBorderRadius)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(kDefaultBorderRadius)),
    borderSide: BorderSide(color: Colors.grey),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(kDefaultBorderRadius)),
    borderSide: BorderSide(color: kPrimaryColor, width: 2),
  ),
  filled: true,
  fillColor: kWhiteColor,
  contentPadding: EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding),
);

// Estilos de AppBar
const AppBarTheme kAppBarTheme = AppBarTheme(
  backgroundColor: kWhiteColor,
  elevation: 1,
  titleTextStyle: TextStyle(
    color: kContrastColor,
    fontSize: 26,
    fontWeight: FontWeight.w900,
  ),
  iconTheme: IconThemeData(
    color: kContrastColor,
    size: kLargeIconSize,
  ),
);

// Estilos de SnackBar
final SnackBarThemeData kSnackBarTheme = SnackBarThemeData(
  backgroundColor: kContrastColor,
  contentTextStyle: const TextStyle(
    color: kWhiteColor,
    fontSize: kSmallFontSize,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(kDefaultBorderRadius),
  ),
);
