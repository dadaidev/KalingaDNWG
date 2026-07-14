import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../screens/doctor_colors.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    this.selectionMode = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = doctor.status == DoctorStatus.active;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DoctorColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: selectionMode && selected
              ? Border.all(color: DoctorColors.deleteRed, width: 2)
              : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: DoctorColors.avatarBackground,
              child: const Icon(
                Icons.masks_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: DoctorColors.titleText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Specialty:  ${doctor.specialty}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: DoctorColors.subtitleText,
                    ),
                  ),
                  Text(
                    'Hospital:  ${doctor.hospital}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: DoctorColors.subtitleText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? DoctorColors.activeGreen
                          : DoctorColors.inactiveOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selectionMode)
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? DoctorColors.deleteRed
                    : DoctorColors.subtitleText,
              ),
          ],
        ),
      ),
    );
  }
}