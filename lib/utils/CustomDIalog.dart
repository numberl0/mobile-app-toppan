import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum DialogType {
  info,
  success,
  warning,
  error,
}

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final DialogType type;
  final bool showCancelButton;

  const CustomDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.onCancel,
    this.type = DialogType.info,
    this.showCancelButton = true,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    DialogType type = DialogType.info,
    bool showCancelButton = true,
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
        onCancel: onCancel,
        type: type,
        showCancelButton: showCancelButton,
      ),
    );
  }

  Color _getColor() {
    switch (type) {
      case DialogType.success:
        return Colors.green;
      case DialogType.warning:
        return Colors.orange;
      case DialogType.error:
        return Colors.red;
      case DialogType.info:
      default:
        return Colors.blue;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle_outline;
      case DialogType.warning:
        // return Icons.warning_amber_outlined;
        return Icons.error_outline;
      case DialogType.error:
        return Icons.error_outline;
      case DialogType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: color),
            ),
            const SizedBox(height: 20),

            // Title
            Text(title,
                style:const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Message
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 25),

            // Buttons
            Row(
              children: [
                if (showCancelButton)
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          onCancel ?? () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          Text('ยกเลิก', style: TextStyle(color: color)),
                    ),
                  ),
                if (showCancelButton) const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ตกลง',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}