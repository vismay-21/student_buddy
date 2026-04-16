import 'dart:math' as math;

import 'package:flutter/material.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  static const _background = Color(0xFFFFFFFF);
  static const _card = Color(0xFFE7F1FF);
  static const _cardAlt = Color(0xFFDCEBFF);
  static const _textPrimary = Color(0xFF1B2430);
  static const _textMuted = Color(0xFF5E6A7A);
  static const _attended = Color(0xFF4CD07F);
  static const _missed = Color(0xFFFF6B6B);
  static const _off = Color(0xFFFFB24A);
  static const _clear = Color(0xFF8D95A5);

  static const _subjects = <SubjectAttendance>[
    SubjectAttendance(
      name: 'Software Engineering Lab',
      attendancePercent: 92.31,
      targetPercent: 80,
      canMiss: 2,
    ),
    SubjectAttendance(
      name: 'Design And Analysis Of Algorithm Lab',
      attendancePercent: 85.71,
      targetPercent: 80,
      canMiss: 1,
    ),
    SubjectAttendance(
      name: 'Computer Networks',
      attendancePercent: 88.24,
      targetPercent: 85,
      canMiss: 3,
    ),
    SubjectAttendance(
      name: 'Database Systems',
      attendancePercent: 79.05,
      targetPercent: 80,
      canMiss: 0,
    ),
    SubjectAttendance(
      name: 'Operating Systems',
      attendancePercent: 90.12,
      targetPercent: 85,
      canMiss: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                dateText: 'Thu, 9 Apr 2026',
                badgeText: '87.03 | 80',
              ),
              const SizedBox(height: 16),
              _LegendRow(
                clear: _clear,
                off: _off,
                missed: _missed,
                attended: _attended,
                textMuted: _textMuted,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: _subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return SubjectAttendanceCard(
                      subject: _subjects[index],
                      cardColor: index.isEven ? _card : _cardAlt,
                      textPrimary: _textPrimary,
                      textMuted: _textMuted,
                      attended: _attended,
                      missed: _missed,
                      off: _off,
                      clear: _clear,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.dateText,
    required this.badgeText,
  });

  final String dateText;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance - Today',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AttendanceScreen._textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 13,
                  color: AttendanceScreen._textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD6E7FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AttendanceScreen._textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFD6E7FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: AttendanceScreen._textPrimary,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.clear,
    required this.off,
    required this.missed,
    required this.attended,
    required this.textMuted,
  });

  final Color clear;
  final Color off;
  final Color missed;
  final Color attended;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _LegendItem(label: 'Clear', color: clear, icon: Icons.remove_circle_outline, textMuted: textMuted),
        _LegendItem(label: 'Off', color: off, icon: Icons.pause_circle_outline, textMuted: textMuted),
        _LegendItem(label: 'Missed', color: missed, icon: Icons.highlight_off, textMuted: textMuted),
        _LegendItem(label: 'Attended', color: attended, icon: Icons.check_circle_outline, textMuted: textMuted),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.color,
    required this.icon,
    required this.textMuted,
  });

  final String label;
  final Color color;
  final IconData icon;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ],
    );
  }
}

class SubjectAttendanceCard extends StatefulWidget {
  const SubjectAttendanceCard({
    super.key,
    required this.subject,
    required this.cardColor,
    required this.textPrimary,
    required this.textMuted,
    required this.attended,
    required this.missed,
    required this.off,
    required this.clear,
  });

  final SubjectAttendance subject;
  final Color cardColor;
  final Color textPrimary;
  final Color textMuted;
  final Color attended;
  final Color missed;
  final Color off;
  final Color clear;

  @override
  State<SubjectAttendanceCard> createState() => _SubjectAttendanceCardState();
}

class _SubjectAttendanceCardState extends State<SubjectAttendanceCard> {
  AttendanceAction _selected = AttendanceAction.clear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AttendanceRing(
                percentage: widget.subject.attendancePercent,
                target: widget.subject.targetPercent,
                ringColor: widget.subject.attendancePercent >= widget.subject.targetPercent
                    ? widget.attended
                    : widget.off,
                backgroundColor: widget.clear.withOpacity(0.25),
                textColor: widget.textPrimary,
                mutedColor: widget.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subject.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'can miss ${widget.subject.canMiss} lectures',
                      style: TextStyle(fontSize: 12, color: widget.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: widget.textMuted.withOpacity(0.12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ActionIconButton(
                icon: Icons.remove_circle_outline,
                color: widget.clear,
                label: 'Clear',
                isSelected: _selected == AttendanceAction.clear,
                onTap: () => _select(AttendanceAction.clear),
              ),
              const SizedBox(width: 10),
              ActionIconButton(
                icon: Icons.pause_circle_outline,
                color: widget.off,
                label: 'Off',
                isSelected: _selected == AttendanceAction.off,
                onTap: () => _select(AttendanceAction.off),
              ),
              const SizedBox(width: 10),
              ActionIconButton(
                icon: Icons.highlight_off,
                color: widget.missed,
                label: 'Missed',
                isSelected: _selected == AttendanceAction.missed,
                onTap: () => _select(AttendanceAction.missed),
              ),
              const SizedBox(width: 10),
              ActionIconButton(
                icon: Icons.check_circle,
                color: widget.attended,
                label: 'Attended',
                isSelected: _selected == AttendanceAction.attended,
                onTap: () => _select(AttendanceAction.attended),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _select(AttendanceAction action) {
    setState(() {
      _selected = action;
    });
  }
}

class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color.withOpacity(0.6) : Colors.transparent,
          ),
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: isSelected ? 1.05 : 1,
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? color : AttendanceScreen._textMuted,
            semanticLabel: label,
          ),
        ),
      ),
    );
  }
}

class AttendanceRing extends StatelessWidget {
  const AttendanceRing({
    super.key,
    required this.percentage,
    required this.target,
    required this.ringColor,
    required this.backgroundColor,
    required this.textColor,
    required this.mutedColor,
  });

  final double percentage;
  final int target;
  final Color ringColor;
  final Color backgroundColor;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(64, 64),
            painter: _RingPainter(
              progress: (percentage / 100).clamp(0.0, 1.0),
              ringColor: ringColor,
              backgroundColor: backgroundColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                percentage.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                target.toString(),
                style: TextStyle(fontSize: 11, color: mutedColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.backgroundColor,
  });

  final double progress;
  final Color ringColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = backgroundColor);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      stroke..color = ringColor,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class SubjectAttendance {
  const SubjectAttendance({
    required this.name,
    required this.attendancePercent,
    required this.targetPercent,
    required this.canMiss,
  });

  final String name;
  final double attendancePercent;
  final int targetPercent;
  final int canMiss;
}

enum AttendanceAction { clear, off, missed, attended }
