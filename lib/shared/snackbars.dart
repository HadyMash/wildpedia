import 'package:flutter/material.dart';

SnackBar _snackBarWithIcon(IconData icon, Color iconColor, String message) {
  return SnackBar(
    content: Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Icon(
          icon,
          color: iconColor,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(message),
      ],
    ),
  );
}

SnackBar errorSnackBar(BuildContext context, String message) {
  return _snackBarWithIcon(
      Icons.error, Theme.of(context).colorScheme.error, message);
}

SnackBar warningSnackBar(BuildContext context, String message) {
  return _snackBarWithIcon(Icons.warning, Colors.yellow, message);
}
