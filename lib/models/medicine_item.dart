enum MedicineStatus {
  upcoming, // no medication_logs row yet for this reminder+day
  notTaken, // maps to DB status 'Missed'
  taken, // maps to DB status 'Taken'
  skipped, // maps to DB status 'Skipped'
}

class MedicineItem {
  final String name;
  final String timeLabel;
  final String dosage;
  final DateTime date;
  final MedicineStatus status;

  // The medication_reminders.reminder_id this entry is tied to, so
  // tapping the card can write a Taken/Missed/Skipped log against the
  // right row. It's an integer column in the DB (matches Medicine.reminderId
  // in screens/medicine_model.dart) -- was previously declared as String?
  // here, which caused an int -> String? assignment error wherever
  // HomePage passed Medicine.reminderId in, and a String? -> int mismatch
  // wherever item.reminderId! was passed to MedicationService.setLogStatus.
  // Null for any legacy/demo entry with no real reminder.
  final int? reminderId;

  const MedicineItem({
    required this.name,
    required this.timeLabel,
    required this.dosage,
    required this.date,
    required this.status,
    this.reminderId,
  });
}