import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/greeting_widget.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/medicine_card.dart';
import '../widgets/empty_state.dart';
import '../models/medicine_item.dart';
import '../services/medication_service.dart';
import '../utils/medicine_schedule_helper.dart';
import 'medicine_model.dart';
import 'appointment_screen.dart';
import 'cabinet_screen.dart';
import 'doctor_screen.dart';
import 'settings_screen.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Assumption: using the real current date now that the calendar is
  // backed by live data, instead of the old hardcoded 2026-07-11 demo
  // value. If you'd rather keep testing against a fixed date, swap this
  // back to a literal DateTime(...).
  final DateTime todayDate = DateTime.now();

  final MedicationService _service = MedicationService();

  late DateTime focusedMonth;
  late DateTime selectedDay;

  List<Medicine> _medicines = [];
  // Keyed by "reminderId_yyyy-MM-dd" -> 'Taken' | 'Missed' | 'Skipped'
  Map<String, String> _logs = {};

  bool _isLoading = true;
  String? _loadError;

  // Home is index 2: Appointment(0), Cabinet(1), Home(2), Doctor(3), Settings(4)
  static const int _tabIndex = 2;

  @override
  void initState() {
    super.initState();
    focusedMonth = DateTime(todayDate.year, todayDate.month, 1);
    selectedDay = todayDate;
    _loadAll();
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _monthStart(DateTime month) => DateTime(month.year, month.month, 1);
  DateTime _monthEnd(DateTime month) =>
      DateTime(month.year, month.month, daysInMonth(month.year, month.month));

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final medicines = await _service.getMedications();
      // reminderId is now int? (matches medication_reminders.reminder_id,
      // an integer column) -- was mistakenly filtered as String? before.
      final reminderIds = medicines
          .map((m) => m.reminderId)
          .whereType<int>()
          .toList();

      final logs = await _service.getLogsForReminders(
        reminderIds: reminderIds,
        start: _monthStart(focusedMonth),
        end: _monthEnd(focusedMonth),
      );

      if (!mounted) return;
      setState(() {
        _medicines = medicines;
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load your medicine schedule: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadLogsForFocusedMonth() async {
    final reminderIds = _medicines
        .map((m) => m.reminderId)
        .whereType<int>()
        .toList();

    final logs = await _service.getLogsForReminders(
      reminderIds: reminderIds,
      start: _monthStart(focusedMonth),
      end: _monthEnd(focusedMonth),
    );

    if (!mounted) return;
    setState(() => _logs = logs);
  }

  /// Union of every date any medicine is due, across the focused month.
  Set<DateTime> get daysWithDose {
    final due = <DateTime>{};
    for (final m in _medicines) {
      due.addAll(dueDaysInMonth(m, focusedMonth));
    }
    return due;
  }

  /// A day shows the calendar "taken" pin if at least one log for that
  /// day, among this month's reminders, is 'Taken'.
  Set<DateTime> get takenDays {
    final taken = <DateTime>{};
    for (final entry in _logs.entries) {
      if (entry.value != 'Taken') continue;
      final dateStr = entry.key.split('_').last;
      final parts = dateStr.split('-');
      taken.add(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])));
    }
    return taken;
  }

  /// Medicines due on [selectedDay], resolved against any existing log.
  /// 'As Needed' (or any medicine with no automatic due day) still shows
  /// up if a log already exists for that day.
  List<MedicineItem> get medicinesToday {
    final day = dateOnly(selectedDay);
    final items = <MedicineItem>[];

    for (final m in _medicines) {
      final due = dueDaysInMonth(m, focusedMonth).contains(day);
      final logKey = m.reminderId != null ? '${m.reminderId}_${_dateStr(day)}' : null;
      final hasLog = logKey != null && _logs.containsKey(logKey);

      if (!due && !hasLog) continue;

      final status = hasLog ? _statusFromDb(_logs[logKey]!) : MedicineStatus.upcoming;

      items.add(MedicineItem(
        name: m.name,
        timeLabel: TimeOfDay.fromDateTime(m.timeToTake).format(context),
        dosage: m.dosage,
        date: day,
        status: status,
        reminderId: m.reminderId,
      ));
    }

    return items;
  }

  MedicineStatus _statusFromDb(String dbStatus) {
    switch (dbStatus) {
      case 'Taken':
        return MedicineStatus.taken;
      case 'Missed':
        return MedicineStatus.notTaken;
      case 'Skipped':
        return MedicineStatus.skipped;
      default:
        return MedicineStatus.upcoming;
    }
  }

  String _nextDbStatus(MedicineStatus current) {
    switch (current) {
      case MedicineStatus.upcoming:
        return 'Taken';
      case MedicineStatus.taken:
        return 'Missed';
      case MedicineStatus.notTaken:
        return 'Skipped';
      case MedicineStatus.skipped:
        return 'Taken';
    }
  }

  /// Tapping a medicine card cycles its status for the selected day:
  /// Upcoming -> Taken -> Missed -> Skipped -> Taken -> ...
  /// and persists each step via medication_logs.
  Future<void> _cycleStatus(MedicineItem item) async {
    if (item.reminderId == null) return; // nothing to write against

    final nextStatus = _nextDbStatus(item.status);

    try {
      await _service.setLogStatus(
        reminderId: item.reminderId!,
        date: item.date,
        status: nextStatus,
      );
      await _reloadLogsForFocusedMonth();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $e')),
      );
    }
  }

  void changeMonth(int value) {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + value, 1);
    });
    _reloadLogsForFocusedMonth();
  }

  void selectDay(DateTime day) {
    setState(() {
      selectedDay = day;
      focusedMonth = DateTime(day.year, day.month, 1);
    });
    _reloadLogsForFocusedMonth();
  }

  // Home, Cabinet, Appointment, Doctor, and Settings now all have real
  // screens. Uses pushReplacement so the stack stays consistent with the
  // other tab screens (no back-stack pileup when switching tabs).
  void _onTabTapped(int index) {
    if (index == _tabIndex) return; // already on Home

    final Widget destination = switch (index) {
      0 => AppointmentScreen(userName: widget.userName),
      1 => CabinetScreen(userName: widget.userName),
      3 => DoctorScreen(userName: widget.userName),
      4 => SettingsScreen(userName: widget.userName),
      _ => HomePage(userName: widget.userName),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),

      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _loadError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : SingleChildScrollView(
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
                          onToggleTaken: (_) {}, // manual toggle removed — status now driven by real logs via card taps
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
                              child: MedicineCard(
                                item: e,
                                onTap: () => _cycleStatus(e),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),

      bottomNavigationBar: BottomBar(
        currentIndex: _tabIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}