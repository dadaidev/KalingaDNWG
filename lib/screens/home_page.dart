import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/greeting_widget.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/medicine_card.dart';
import '../widgets/empty_state.dart';
import '../models/medicine_item.dart';
import '../utils/date_helper.dart';
import 'appointment_screen.dart';
import 'cabinet_screen.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DateTime todayDate = DateTime(2026, 7, 11);

  late DateTime focusedMonth;
  late DateTime selectedDay;

  final Set<DateTime> daysWithDose = {
    DateTime(2026, 7, 1),
    DateTime(2026, 7, 11),
    DateTime(2026, 7, 12),
    DateTime(2026, 7, 18),
    DateTime(2026, 7, 29),
  };

  final Set<DateTime> takenDays = {DateTime(2026, 7, 12)};

  final List<MedicineItem> medicines = [
    MedicineItem(
      name: "Biogesic",
      timeLabel: "8:00 AM",
      dosage: "1 pc",
      date: DateTime(2026, 7, 11),
      status: MedicineStatus.upcoming,
    ),
    MedicineItem(
      name: "Bioflu",
      timeLabel: "8:00 AM",
      dosage: "1 pc",
      date: DateTime(2026, 7, 11),
      status: MedicineStatus.notTaken,
    ),
    MedicineItem(
      name: "Vitamin C",
      timeLabel: "7:00 PM",
      dosage: "1 pc",
      date: DateTime(2026, 7, 12),
      status: MedicineStatus.taken,
    ),
  ];

  @override
  void initState() {
    super.initState();
    focusedMonth = DateTime(todayDate.year, todayDate.month, 1);
    selectedDay = todayDate;
  }

  List<MedicineItem> get medicinesToday => medicines
      .where((e) => dateOnly(e.date) == dateOnly(selectedDay))
      .toList();

  void changeMonth(int value) {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + value, 1);
    });
  }

  void selectDay(DateTime day) {
    setState(() {
      selectedDay = day;
      focusedMonth = DateTime(day.year, day.month, 1);
    });
  }

  void toggleTaken(DateTime day) {
    final key = dateOnly(day);

    setState(() {
      if (takenDays.contains(key)) {
        takenDays.remove(key);
      } else {
        takenDays.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingWidget(userName: widget.userName),

              const SizedBox(height: 20),

              CalendarWidget(
                focusedMonth: focusedMonth,
                todayDate: todayDate,
                selectedDay: selectedDay,
                daysWithDose: daysWithDose,
                takenDays: takenDays,
                onSelectDay: selectDay,
                onToggleTaken: toggleTaken,
                onChangeMonth: changeMonth,
              ),

              const SizedBox(height: 25),

              const Text(
                "Today's Medicine",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              if (medicinesToday.isEmpty)
                const EmptyState()
              else
                ...medicinesToday.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: MedicineCard(item: e),
                  ),
                ),
            ],
          ),
        ),
      ),

      // 2. ITONG BAHAGI ANG PINAGSAMA NATING RE-ALIGNED BOTTOM BAR:
      bottomNavigationBar: BottomBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AppointmentScreen(),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CabinetScreen()),
            );
          }
        },
      ),
    );
  }
}
