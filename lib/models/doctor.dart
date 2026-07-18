class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String hospital;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
  });

  Doctor copyWith({
    String? name,
    String? specialty,
    String? hospital,
  }) {
    return Doctor(
      id: id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      hospital: hospital ?? this.hospital,
    );
  }
}