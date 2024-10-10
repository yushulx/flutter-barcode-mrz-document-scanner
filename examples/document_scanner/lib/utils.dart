import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void showAlert(BuildContext context, String title, String content) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<ui.Image> createImage(
    Uint8List buffer, int width, int height, ui.PixelFormat pixelFormat) {
  final Completer<ui.Image> completer = Completer();

  ui.decodeImageFromPixels(buffer, width, height, pixelFormat, (ui.Image img) {
    completer.complete(img);
  });

  return completer.future;
}
