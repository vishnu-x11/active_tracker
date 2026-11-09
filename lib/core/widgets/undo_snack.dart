import 'package:flutter/material.dart';

void showUndoSnack(ScaffoldMessengerState messenger, String text, VoidCallback onUndo, {double above = 0}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        persist: false,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + above),
        action: SnackBarAction(label: 'Undo', onPressed: onUndo),
      ),
    );
}
