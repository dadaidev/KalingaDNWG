import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        vertical: 35,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFDCEFF7),
        borderRadius: BorderRadius.circular(20),
      ),

      child: const Column(
        children: [

          Icon(
            Icons.check_circle_outline,
            color: Color(0xFF1E6FA8),
            size: 40,
          ),

          SizedBox(height: 10),

          Text(
            "No medicine scheduled today",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}