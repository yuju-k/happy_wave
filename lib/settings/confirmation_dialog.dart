import 'package:flutter/material.dart';

Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  String cancelText = '취소',
  String confirmText = '확인',
  Color? confirmColor,
}) async {
  return showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor ?? Theme.of(context).primaryColor,
              ),
              child: Text(
                confirmText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
  );
}
