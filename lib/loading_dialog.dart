import 'package:flutter/material.dart';

class LoadingDialog {
  static final LoadingDialog _instance = LoadingDialog._internal();
  factory LoadingDialog() => _instance;
  LoadingDialog._internal();

  OverlayEntry? _overlayEntry;

  void show(BuildContext context) {
    if (_overlayEntry != null) return; // Prevent multiple overlays

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );


    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Overlay.of(context) != null) {
        Overlay.of(context)!.insert(_overlayEntry!);
      }
    });
  }

  void hide() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}
