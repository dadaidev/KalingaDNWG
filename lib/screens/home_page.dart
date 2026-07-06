import 'package:flutter/material.dart';

void main() => runApp(const MedApp());

class MedApp extends StatelessWidget {
  const MedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medicine Reminder',
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF6FAFC),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6FA8)),
      ),
      // The app starts on LoginPage. Whoever logs in (provides a name)
      // is the one shown in the "Hello" greeting on HomePage.
      home: const LoginPage(),
    );
  }
}

// ====================================================================
// LOGIN PAGE
// A simple login screen. This is where the user's name comes from,
// which gets passed to HomePage — so even if the user changes,
// the greeting always shows the right name.
// ====================================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(userName: _nameController.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E6FA8), Color(0xFF7EC8E3)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.medication_rounded,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Medicine Reminder',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3A55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your name to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF5B6B7F)),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: const Color(0xFFDCEFF7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6FA8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// MODEL
// ====================================================================
class MedicineItem {
  final String name;
  final String timeLabel;
  final String dosage;
  final DateTime date;
  final MedicineStatus status;

  const MedicineItem({
    required this.name,
    required this.timeLabel,
    required this.dosage,
    required this.date,
    required this.status,
  });
}

enum MedicineStatus { upcoming, notTaken, taken }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// ====================================================================
// HOME PAGE
// ====================================================================
class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Fixed "today" to match the demo data (July 2026). You can replace
  // this with DateTime.now() if you want it to follow the real date.
  final DateTime _todayDate = DateTime(2026, 7, 11);

  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  final Set<DateTime> _daysWithDose = {
    DateTime(2026, 7, 1),
    DateTime(2026, 7, 11),
    DateTime(2026, 7, 12),
    DateTime(2026, 7, 18),
    DateTime(2026, 7, 29),
  };

  // Dates the user has pinned as "medicine taken". Long-press a day on
  // the calendar to toggle it in/out of this set.
  final Set<DateTime> _takenDays = {
    DateTime(2026, 7, 12),
  };

  final List<MedicineItem> _medicines = [
    MedicineItem(
      name: 'Biogesic',
      timeLabel: '8:00 AM',
      dosage: '1pc Only',
      date: DateTime(2026, 7, 11),
      status: MedicineStatus.upcoming,
    ),
    MedicineItem(
      name: 'Bioflu',
      timeLabel: '8:00 AM',
      dosage: '1pc Only',
      date: DateTime(2026, 7, 11),
      status: MedicineStatus.notTaken,
    ),
    MedicineItem(
      name: 'Vitamin C',
      timeLabel: '7:00 PM',
      dosage: '1pc Only',
      date: DateTime(2026, 7, 12),
      status: MedicineStatus.taken,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_todayDate.year, _todayDate.month, 1);
    _selectedDay = _todayDate;
  }

  List<MedicineItem> get _medicinesForSelectedDay => _medicines
      .where((m) => _dateOnly(m.date) == _dateOnly(_selectedDay))
      .toList();

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      // If you tap a day belonging to the previous/next month (from the
      // start/end of the grid), the focused month follows it too.
      _focusedMonth = DateTime(day.year, day.month, 1);
    });
  }

  // Toggles whether a date is pinned as "medicine taken".
  void _toggleTaken(DateTime day) {
    final key = _dateOnly(day);
    setState(() {
      if (_takenDays.contains(key)) {
        _takenDays.remove(key);
      } else {
        _takenDays.add(key);
      }
    });

    final bool nowTaken = _takenDays.contains(key);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: nowTaken
              ? const Color(0xFF2FB35C)
              : const Color(0xFF5B6B7F),
          content: Text(
            nowTaken
                ? 'Marked ${day.day} ${_monthNames[day.month - 1]} as medicine taken'
                : 'Removed the "taken" pin from ${day.day} ${_monthNames[day.month - 1]}',
          ),
        ),
      );
  }

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 20),
              _buildCalendarCard(),
              const SizedBox(height: 28),
              _buildMedicineListHeader(),
              const SizedBox(height: 14),
              if (_medicinesForSelectedDay.isEmpty)
                _buildEmptyState()
              else
                ..._medicinesForSelectedDay.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MedicineCard(item: item),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Greeting ----------------
  Widget _buildGreeting() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E6FA8), Color(0xFF7EC8E3)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.medication_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello ${widget.userName},',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B3A55),
                ),
              ),
              const Text(
                'Here are your medicines for today',
                style: TextStyle(fontSize: 13, color: Color(0xFF5B6B7F)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Medicine list header ----------------
  Widget _buildMedicineListHeader() {
    final bool isToday = _dateOnly(_selectedDay) == _dateOnly(_todayDate);
    final String label = isToday
        ? "Today's Medicine List"
        : 'Medicine List — ${_selectedDay.day} ${_monthNames[_selectedDay.month - 1]} ${_selectedDay.year}';
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2B3A55),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFF7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF1E6FA8), size: 34),
          SizedBox(height: 8),
          Text(
            'No medicine scheduled for this day',
            style: TextStyle(color: Color(0xFF5B6B7F)),
          ),
        ],
      ),
    );
  }

  // ---------------- Calendar ----------------
  Widget _buildCalendarCard() {
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<DateTime> cells = _buildMonthGrid(_focusedMonth);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFE2F2), Color(0xFFEAF6FB)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E6FA8).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _changeMonth(-1),
              ),
              Text(
                '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B3A55),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF2B3A55),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final day = cells[index];
              final bool inMonth = day.month == _focusedMonth.month;
              final bool hasDose = _daysWithDose.contains(_dateOnly(day));
              final bool isToday = _dateOnly(day) == _dateOnly(_todayDate);
              final bool isSelected = _dateOnly(day) == _dateOnly(_selectedDay);
              final bool isTaken = _takenDays.contains(_dateOnly(day));

              return _CalendarDayCell(
                day: day.day,
                faded: !inMonth,
                hasDose: hasDose,
                isToday: isToday,
                isSelected: isSelected,
                isTaken: isTaken,
                onTap: () => _selectDay(day),
                onLongPress: inMonth || true ? () => _toggleTaken(day) : null,
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.push_pin_rounded,
                  size: 14, color: Color(0xFF2FB35C)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tap a date to view it. Long-press a date to pin it as "medicine taken".',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF5B6B7F),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds the full 7-column month grid (including days from the
  // previous/next month so the first/last week is filled in).
  List<DateTime> _buildMonthGrid(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday = 1 ... Sunday = 7
    final leadingCount = firstOfMonth.weekday - 1;
    final gridStart = firstOfMonth.subtract(Duration(days: leadingCount));
    final totalCells = (((leadingCount + daysInMonth) / 7).ceil()) * 7;
    return List.generate(totalCells, (i) => gridStart.add(Duration(days: i)));
  }
}

// ---------------- small reusable nav button ----------------
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: const Color(0xFF1E6FA8), size: 22),
        ),
      ),
    );
  }
}

// ---------------- calendar day cell (tappable + long-pressable) ----------------
class _CalendarDayCell extends StatelessWidget {
  final int day;
  final bool faded;
  final bool hasDose;
  final bool isToday;
  final bool isSelected;
  final bool isTaken;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CalendarDayCell({
    required this.day,
    required this.faded,
    required this.hasDose,
    required this.isToday,
    required this.isSelected,
    required this.isTaken,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = faded
        ? const Color(0xFFB9C6D6)
        : (isSelected || isToday)
            ? Colors.white
            : const Color(0xFF2B3A55);

    Color? fillColor;
    if (isSelected) {
      fillColor = const Color(0xFF1E6FA8);
    } else if (isToday) {
      fillColor = const Color(0xFF7EC8E3);
    } else if (isTaken) {
      fillColor = const Color(0xFFCDEFDA);
    }

    return Center(
      child: GestureDetector(
        onTap: faded ? null : onTap,
        onLongPress: faded ? null : onLongPress,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fillColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isTaken && !isSelected && !isToday
                ? Border.all(color: const Color(0xFF2FB35C), width: 1.4)
                : (isSelected && isToday)
                    ? Border.all(color: const Color(0xFF2B3A55), width: 1.6)
                    : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
              if (hasDose)
                Positioned(
                  bottom: -4,
                  right: -2,
                  child: Icon(
                    Icons.medication,
                    size: 12,
                    color: (isSelected || isToday)
                        ? Colors.white
                        : const Color(0xFF1E6FA8),
                  ),
                ),
              // Green pin marks a date the user has confirmed as
              // "medicine taken" (toggled via long-press).
              if (isTaken)
                Positioned(
                  top: -5,
                  left: -3,
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 12,
                    color: (isSelected || isToday)
                        ? Colors.white
                        : const Color(0xFF2FB35C),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- medicine card ----------------
class _MedicineCard extends StatelessWidget {
  final MedicineItem item;
  const _MedicineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    late final Color badgeColor;
    late final String badgeLabel;
    late final IconData badgeIcon;
    switch (item.status) {
      case MedicineStatus.upcoming:
        badgeColor = const Color(0xFF1E9BE0);
        badgeLabel = 'Upcoming';
        badgeIcon = Icons.schedule_rounded;
        break;
      case MedicineStatus.notTaken:
        badgeColor = const Color(0xFFE03B3B);
        badgeLabel = 'Not Taken';
        badgeIcon = Icons.close_rounded;
        break;
      case MedicineStatus.taken:
        badgeColor = const Color(0xFF2FB35C);
        badgeLabel = 'Taken';
        badgeIcon = Icons.check_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFF7),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E6FA8).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_liquid_rounded,
                color: Color(0xFF1E6FA8)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B3A55),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: Color(0xFF5B6B7F)),
                    const SizedBox(width: 4),
                    Text(
                      'Time to Take: ${item.timeLabel}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5B6B7F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.medication_outlined,
                        size: 14, color: Color(0xFF5B6B7F)),
                    const SizedBox(width: 4),
                    Text(
                      'Dosage/Pcs: ${item.dosage}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5B6B7F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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