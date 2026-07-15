import 'package:flutter/material.dart';
import 'cabinet_screen.dart';
import 'medicine_model.dart';

/// CabinetScreen already builds its own Scaffold, TopBar, and BottomBar
/// internally (see cabinet_screen.dart), so we do NOT wrap it in another
/// Scaffold/AppBar/BottomNavigationBar here — doing so would create
/// duplicate top bars and bottom nav bars on screen.
///
/// This widget just supplies the data (medicine list + userName) and
/// hands off rendering to CabinetScreen.
class CabinetHomeScreen extends StatelessWidget {
  final String userName;

  const CabinetHomeScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    // Sample data — swap this out for your real medicine list
    // (e.g. loaded from local storage, a database, or a provider/bloc).
    final List<Medicine> myMedicineList = [
      Medicine(
        id: '1',
        name: 'Biogesic',
        genericName: 'Paracetamol',
        type: MedicineType.tablets,
        dosage: '1pc Only',
        purpose: 'Fever/Pain relief',
        frequency: 'Every 6 hours',
        timeToTake: DateTime(2026, 7, 5, 8, 0),
        meal: MealTiming.after,
        isActive: true,
      ),
    ];

    return CabinetScreen(
      initialMedicines: myMedicineList,
      userName: userName,
    );
  }
}