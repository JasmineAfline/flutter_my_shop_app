import 'package:flutter/material.dart';

class MyAppFunctions {
  static Future<void> showErrorOrWarningDialog({
    required BuildContext context,
    required String subtitle,
    required VoidCallback fct,
    bool isError = true,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isError ? 'Error' : 'Warning'),
        content: Text(subtitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              fct();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
