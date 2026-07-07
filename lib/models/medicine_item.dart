enum MedicineStatus {
  upcoming,
  notTaken,
  taken,
}

class MedicineItem {
  final String name;
  final String timeLabel;
  final String dosage;
  final DateTime date;
  final MedicineStatus status;

  const MedicineItem({
    required this.name,
    required this.timeLabel,
    required this.dosage,
    required this.date,
    required this.status,
  });
}