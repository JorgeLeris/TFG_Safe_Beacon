import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableCodeField extends StatelessWidget {
  const CopyableCodeField({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.only(left: 12, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  code,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.copy_outlined,
                color: Colors.black.withValues(alpha: 0.5),
                size: 20,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
              },
            ),
          ],
        ),
      ),
    );
  }
}
