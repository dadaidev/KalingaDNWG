import 'package:flutter/material.dart';

class Doctor {
  final String id;
  final String fullName;
  final String specialty;
  final double rating;
  final String hospital;

  Doctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.rating,
    required this.hospital,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      fullName: json['full_name'],
      specialty: json['specialty'],
      rating: (json['rating'] as num).toDouble(),
      hospital: json['hospital'],
    );
  }
}

class Appointment {
  final String id;
  final String date;
  final String timeSlot;
  final String status;
  final String? reason;
  final Doctor? doctor;

  Appointment({
    required this.id,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.reason,
    this.doctor,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      date: json['date'],
      timeSlot: json['time_slot'],
      status: json['status'],
      reason: json['reason'],
      doctor: json['doctors'] != null ? Doctor.fromJson(json['doctors']) : null,
    );
  }
}
