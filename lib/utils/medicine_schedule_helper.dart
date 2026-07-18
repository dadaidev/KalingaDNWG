/// Pure-Dart helpers for turning a Medicine's start date + frequency into
/// the set of calendar days it's due, for a given displayed month.
///
/// Deliberately free of any Flutter import (no package:flutter/material.dart)
/// so it can be unit tested without the widget test harness.
library;

import '../screens/medicine_model.dart';

/// Number of days in [year]-[month]. Hand-rolled instead of using
/// Flutter's DateUtils.getDaysInMonth so this file stays Flutter-free.
int daysInMonth(int year, int month) {
  final firstOfNextMonth =
      (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return firstOfNextMonth.subtract(const Duration(days: 1)).day;
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Frequencies that recur every calendar day once the schedule has
/// started. Must stay in sync with add_medicine_screen.dart's
/// _frequencyOptions list.
const _dailyFrequencies = {
  'Once Daily',
  'Twice Daily',
  'Every 8 Hours',
  'Every 12 Hours',
};

/// Returns every date within [focusedMonth] (year+month, day ignored)
/// that [medicine] is scheduled to be taken.
///
/// - Daily-style frequencies are due every day on/after the start date
///   (medicine.timeToTake's date part), up to endDate if set.
/// - 'Weekly' is due once a week, on the same weekday as the start date.
/// - 'As Needed' (or any unrecognized frequency) has no fixed schedule,
///   so it contributes no automatic due day here — it will still show up
///   for a given day if a log already exists for it.
Set<DateTime> dueDaysInMonth(Medicine medicine, DateTime focusedMonth) {
  final start = dateOnly(medicine.timeToTake);
  final end = medicine.endDate != null ? dateOnly(medicine.endDate!) : null;

  final totalDays = daysInMonth(focusedMonth.year, focusedMonth.month);
  final due = <DateTime>{};

  for (int day = 1; day <= totalDays; day++) {
    final current = DateTime(focusedMonth.year, focusedMonth.month, day);
    if (current.isBefore(start)) continue;
    if (end != null && current.isAfter(end)) continue;

    if (_dailyFrequencies.contains(medicine.frequency)) {
      due.add(current);
    } else if (medicine.frequency == 'Weekly') {
      if (current.weekday == start.weekday) due.add(current);
    }
  }

  return due;
}