import 'package:flutter/material.dart';

import '../models/medicine_item.dart';

class MedicineCard extends StatelessWidget {
  final MedicineItem item;

  const MedicineCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (item.status) {
      case MedicineStatus.upcoming:
        badgeColor = Colors.blue;
        badgeText = "Upcoming";
        badgeIcon = Icons.schedule;
        break;

      case MedicineStatus.notTaken:
        badgeColor = Colors.red;
        badgeText = "Not Taken";
        badgeIcon = Icons.close;
        break;

      case MedicineStatus.taken:
        badgeColor = Colors.green;
        badgeText = "Taken";
        badgeIcon = Icons.check;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFDCEFF7),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [

          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),

            child: const Icon(
              Icons.medication,
              color: Color(0xFF1E6FA8),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 15,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      item.timeLabel,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.medication_outlined,
                      size: 15,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      item.dosage,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                Icon(
                  badgeIcon,
                  size: 14,
                  color: Colors.white,
                ),

                const SizedBox(width: 5),

                Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}