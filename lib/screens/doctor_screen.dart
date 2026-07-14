import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/doctor_card.dart';
import '../models/doctor.dart';
import 'doctor_colors.dart';
import 'request_checkup_screen.dart';
import 'appointment_screen.dart';
import 'cabinet_screen.dart';
import 'home_page.dart';

// TODO: replace with a real Settings screen import once available, e.g.:
// import 'settings_screen.dart';

class DoctorScreen extends StatefulWidget {
  final List<Doctor> initialDoctors;
  final String userName; // needed to navigate back to Home/Cabinet

  const DoctorScreen({
    super.key,
    this.initialDoctors = const [],
    required this.userName,
  });

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  late List<Doctor> _doctors;
  bool _deleteMode = false;
  final Set<String> _selectedIds = {};

  // Appointment(0), Cabinet(1), Home(2), Doctor(3), Setting(4)
  static const int _tabIndex = 3;

  @override
  void initState() {
    super.initState();
    _doctors = _initialSeed(widget.initialDoctors);
  }

  // Seeds the two doctors from the mockup if nothing was passed in, so the
  // screen matches the design out of the box. Remove this once real data
  // is wired up.
  List<Doctor> _initialSeed(List<Doctor> provided) {
    if (provided.isNotEmpty) return List.of(provided);
    return [
      Doctor(
        id: 'd1',
        name: 'Dr. Jose P. Rizal',
        specialty: 'Surgeon',
        hospital: 'CP Reyes',
        status: DoctorStatus.active,
      ),
      Doctor(
        id: 'd2',
        name: 'Dr. Jose P. Laurel',
        specialty: 'Surgeon',
        hospital: 'CP Reyes',
        status: DoctorStatus.inactive,
      ),
    ];
  }

  void _onTabTapped(int index) {
    if (index == _tabIndex) return;

    // Appointment, Cabinet, and Home now point at the real screens.
    // Settings stays on _PlaceholderScreen until that screen exists.
    final Widget destination = switch (index) {
      0 => AppointmentScreen(userName: widget.userName),
      1 => CabinetScreen(userName: widget.userName),
      2 => HomePage(userName: widget.userName),
      4 => _PlaceholderScreen(label: 'Settings', userName: widget.userName),
      _ => HomePage(userName: widget.userName),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _toggleDeleteMode() {
    setState(() {
      if (_deleteMode) {
        _deleteMode = false;
        _selectedIds.clear();
      } else if (_doctors.isEmpty) {
        return;
      } else {
        _deleteMode = true;
      }
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _openRequestCheckup() async {
    final result = await Navigator.of(context).push<CheckupRequest>(
      MaterialPageRoute(builder: (_) => const RequestCheckupScreen()),
    );

    if (result != null) {
      // A submitted checkup request doesn't map 1:1 to a new Doctor entry;
      // hook this up to your actual request/booking logic once it exists.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CheckUp requested for ${result.fullName} (age ${result.age}).',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (_selectedIds.isEmpty) {
      _toggleDeleteMode();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) => _DeleteConfirmDialog(count: _selectedIds.length),
    );

    if (confirmed == true) {
      setState(() {
        _doctors.removeWhere((d) => _selectedIds.contains(d.id));
        _selectedIds.clear();
        _deleteMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: Container(
        color: DoctorColors.pageBackground,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Doctors',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DoctorColors.titleText,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _doctors.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      itemCount: _doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = _doctors[index];
                        return DoctorCard(
                          doctor: doctor,
                          selectionMode: _deleteMode,
                          selected: _selectedIds.contains(doctor.id),
                          onTap: _deleteMode
                              ? () => _toggleSelected(doctor.id)
                              : null,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            if (!_deleteMode)
              Row(
                children: [
                  Expanded(
                    child: _PillButton(
                      label: 'Add',
                      color: DoctorColors.addGreen,
                      onPressed: _openRequestCheckup,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PillButton(
                      label: 'Delete',
                      color: DoctorColors.deleteRed,
                      onPressed: _toggleDeleteMode,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _PillButton(
                      label: 'Cancel',
                      color: DoctorColors.cancelGrey,
                      onPressed: _toggleDeleteMode,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PillButton(
                      label: 'Delete (${_selectedIds.length})',
                      color: DoctorColors.deleteRed,
                      onPressed: _selectedIds.isEmpty ? null : _confirmDelete,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _tabIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No doctors added yet.\nTap "Add" to request a check-up.',
        textAlign: TextAlign.center,
        style: TextStyle(color: DoctorColors.subtitleText, fontSize: 14),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _PillButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  final int count;
  const _DeleteConfirmDialog({required this.count});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DoctorColors.dialogTeal,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count == 1
                  ? 'Are you sure you want to Delete?'
                  : 'Are you sure you want to Delete $count items?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: 'Yes',
                    color: DoctorColors.addGreen,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PillButton(
                    label: 'Cancel',
                    color: DoctorColors.deleteRed,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Temporary stand-in used ONLY for Settings (index 4), which doesn't have a
/// real screen yet. Delete this once settings_screen.dart exists, and point
/// _onTabTapped() at it instead — same as Appointment/Cabinet/Home above.
class _PlaceholderScreen extends StatelessWidget {
  final String label;
  final String userName;

  const _PlaceholderScreen({required this.label, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: Center(child: Text('$label screen goes here')),
      bottomNavigationBar: BottomBar(
        currentIndex: 4,
        onTap: (index) {
          if (index == 4) return;

          final Widget destination = switch (index) {
            0 => AppointmentScreen(userName: userName),
            1 => CabinetScreen(userName: userName),
            2 => HomePage(userName: userName),
            3 => DoctorScreen(userName: userName),
            _ => HomePage(userName: userName),
          };

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),
    );
  }
}