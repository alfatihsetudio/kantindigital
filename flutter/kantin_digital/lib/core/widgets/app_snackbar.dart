import 'package:flutter/material.dart';
import 'top_notification.dart';

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    IconData? icon,
  }) {
    TopNotification.show(
      message: message,
      backgroundColor: backgroundColor ?? Colors.black87,
      icon: icon,
    );
  }
}

