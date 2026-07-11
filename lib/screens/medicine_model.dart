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
  final String frequency; // e.g. "Once a day"
  final DateTime timeToTake; // date + time of next/scheduled dose
  final MealTiming meal;
  bool isActive;

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
    );
  }
}