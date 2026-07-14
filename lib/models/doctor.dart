enum DoctorStatus { active, inactive }

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final DoctorStatus status;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.status,
  });

  Doctor copyWith({
    String? name,
    String? specialty,
    String? hospital,
    DoctorStatus? status,
  }) {
    return Doctor(
      id: id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      hospital: hospital ?? this.hospital,
      status: status ?? this.status,
    );
  }
}