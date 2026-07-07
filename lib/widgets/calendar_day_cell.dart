import 'package:flutter/material.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final DateTime selectedDay;
  final DateTime todayDate;

  final bool hasDose;
  final bool taken;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.selectedDay,
    required this.todayDate,
    required this.hasDose,
    required this.taken,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {

    final bool isSelected =
        day.year == selectedDay.year &&
        day.month == selectedDay.month &&
        day.day == selectedDay.day;

    final bool isToday =
        day.year == todayDate.year &&
        day.month == todayDate.month &&
        day.day == todayDate.day;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,

      child: Container(
        margin: const EdgeInsets.all(4),

        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E6FA8)
              : isToday
                  ? Colors.lightBlue
                  : Colors.white,

          borderRadius: BorderRadius.circular(10),
        ),

        child: Stack(
          children: [

            Center(
              child: Text(
                "${day.day}",
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),

            if (hasDose)
              const Positioned(
                bottom: 4,
                right: 4,
                child: Icon(
                  Icons.medication,
                  size: 10,
                  color: Colors.blue,
                ),
              ),

            if (taken)
              const Positioned(
                top: 2,
                left: 2,
                child: Icon(
                  Icons.push_pin,
                  size: 10,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}