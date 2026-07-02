import 'package:flutter/material.dart';

class AttendanceRingLabel extends StatelessWidget {
  final double current;
  final double target;
  final double fontSize;

  const AttendanceRingLabel({
    super.key,
    required this.current,
    required this.target,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    final Widget percentWidget = Text(
      '%',
      style: TextStyle(
        fontSize: fontSize * 0.85,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Invisible spacer to balance the '%' on the right, keeping numbers centered
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: percentWidget,
        ),
        const SizedBox(width: 1.5),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              current.toInt().toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.0,
              ),
            ),
            Container(
              width: 16,
              height: 1,
              color: textColor.withOpacity(0.4),
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            Text(
              target.toInt().toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor.withOpacity(0.6),
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(width: 1.5),
        percentWidget,
      ],
    );
  }
}
