import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cabinet_colors.dart';
import 'medicine_model.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.selectionMode = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('h:mm a, MMM d, yyyy').format(medicine.timeToTake);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CabinetColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: CabinetColors.titleText,
                        ),
                      ),
                      if (!selectionMode) _StatusBadge(isActive: medicine.isActive),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Time to Take: $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: CabinetColors.subtitleText,
                    ),
                  ),
                  Text(
                    'Dosage/Pcs: ${medicine.dosage}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: CabinetColors.subtitleText,
                    ),
                  ),
                ],
              ),
            ),
            if (selectionMode) ...[
              const SizedBox(width: 8),
              _SelectIndicator(selected: selected),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? CabinetColors.activeGreen : CabinetColors.inactiveRed,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SelectIndicator extends StatelessWidget {
  final bool selected;
  const _SelectIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? CabinetColors.selectBlue : Colors.transparent,
        border: Border.all(
          color: selected ? CabinetColors.selectBlue : CabinetColors.unselectedGrey,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}