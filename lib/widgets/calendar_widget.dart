import 'package:flutter/material.dart';

import 'calendar_day_cell.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final DateTime todayDate;

  final Set<DateTime> daysWithDose;
  final Set<DateTime> takenDays;

  final Function(DateTime) onSelectDay;
  final Function(DateTime) onToggleTaken;
  final Function(int) onChangeMonth;

  const CalendarWidget({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.todayDate,
    required this.daysWithDose,
    required this.takenDays,
    required this.onSelectDay,
    required this.onToggleTaken,
    required this.onChangeMonth,
  });

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = List.generate(
      DateUtils.getDaysInMonth(
        focusedMonth.year,
        focusedMonth.month,
      ),
      (index) => DateTime(
        focusedMonth.year,
        focusedMonth.month,
        index + 1,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFF7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              IconButton(
                onPressed: () => onChangeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),

              Text(
                "${focusedMonth.month}/${focusedMonth.year}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                onPressed: () => onChangeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),

          const SizedBox(height: 15),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),

            itemCount: days.length,

            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),

            itemBuilder: (context, index) {

              final day = days[index];

              return CalendarDayCell(
                day: day,
                selectedDay: selectedDay,
                todayDate: todayDate,
                hasDose: daysWithDose.contains(day),
                taken: takenDays.contains(day),
                onTap: () => onSelectDay(day),
                onLongPress: () => onToggleTaken(day),
              );
            },
          )
        ],
      ),
    );
  }
}