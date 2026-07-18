enum MedicineType {
  tablets,
  capsules,
  softGels,
  ointment,
  lozenges,
  syrup,
  eyeDrops,
  inhaler,
  injection,
  oralSuspension,
}

extension MedicineTypeLabel on MedicineType {
  String get label {
    switch (this) {
      case MedicineType.tablets:
        return 'Tablets';
      case MedicineType.capsules:
        return 'Capsules';
      case MedicineType.softGels:
        return 'Soft Gels';
      case MedicineType.ointment:
        return 'Ointment';
      case MedicineType.lozenges:
        return 'Lozenges';
      case MedicineType.syrup:
        return 'Syrup';
      case MedicineType.eyeDrops:
        return 'Eye Drops';
      case MedicineType.inhaler:
        return 'Inhaler';
      case MedicineType.injection:
        return 'Injection';
      case MedicineType.oralSuspension:
        return 'Oral Suspension';
    }
  }
}

enum MealTiming { before, after }

class Medicine {
  final String id;
  final String name;
  final String genericName;
  final MedicineType type;
  final String dosage; // e.g. "1pc Only"
  final String purpose;
  final String frequency; // e.g. "Once Daily"
  final DateTime timeToTake; // schedule start date + time of dose
  final MealTiming meal;
  bool isActive;

  // The real medication_reminders.reminder_id this medicine is tied to.
  // medication_logs writes back against this id, not medication_id.
  // It's an integer column in the DB (medication_reminders.reminder_id
  // is a serial/int PK) -- was previously declared as String? here,
  // which caused an int -> String? assignment error wherever
  // MedicationService passed the real int reminder_id in.
  // Nullable because a hand-built Medicine (e.g. a draft before saving)
  // won't have one yet.
  final int? reminderId;

  // medication_reminders.end_date, if the schedule has a cutoff.
  // Null means "recurs indefinitely" for daily/weekly frequencies.
  final DateTime? endDate;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.type,
    required this.dosage,
    required this.purpose,
    required this.frequency,
    required this.timeToTake,
    required this.meal,
    this.isActive = true,
    this.reminderId,
    this.endDate,
  });

  Medicine copyWith({
    String? name,
    String? genericName,
    MedicineType? type,
    String? dosage,
    String? purpose,
    String? frequency,
    DateTime? timeToTake,
    MealTiming? meal,
    bool? isActive,
    int? reminderId,
    DateTime? endDate,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      type: type ?? this.type,
      dosage: dosage ?? this.dosage,
      purpose: purpose ?? this.purpose,
      frequency: frequency ?? this.frequency,
      timeToTake: timeToTake ?? this.timeToTake,
      meal: meal ?? this.meal,
      isActive: isActive ?? this.isActive,
      reminderId: reminderId ?? this.reminderId,
      endDate: endDate ?? this.endDate,
    );
  }
}