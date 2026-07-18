import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/doctor_card.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';
import 'doctor_colors.dart';
import 'add_doctor_screen.dart';
import 'appointment_screen.dart';
import 'cabinet_screen.dart';
import 'home_page.dart';
import 'settings_screen.dart';

class DoctorScreen extends StatefulWidget {
  final String userName; // needed to navigate back to Home/Cabinet

  const DoctorScreen({
    super.key,
    required this.userName,
  });

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final DoctorService _service = DoctorService();

  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String? _loadError;
  bool _deleteMode = false;
  final Set<String> _selectedIds = {};

  // Appointment(0), Cabinet(1), Home(2), Doctor(3), Setting(4)
  static const int _tabIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final doctors = await _service.getMyDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load doctors: $e';
        _isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    if (index == _tabIndex) return;

    // All five tabs now point at their real screens. Each tab switch
    // uses pushReplacement so tapping Appointment from Settings (or
    // any other tab) lands you back on that tab's own screen instead
    // of stacking routes on top of each other.
    final Widget destination = switch (index) {
      0 => AppointmentScreen(userName: widget.userName),
      1 => CabinetScreen(userName: widget.userName),
      2 => HomePage(userName: widget.userName),
      4 => SettingsScreen(userName: widget.userName),
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

  Future<void> _openAddDoctor() async {
    final result = await Navigator.of(context).push<AddDoctorResult>(
      MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
    );

    if (result == null) return;

    try {
      await _service.addDoctor(
        fullName: result.fullName,
        specialty: result.specialty,
        hospital: result.hospital,
      );
      // Reload from Supabase rather than appending locally, so the list
      // reflects the real saved state (and the real database id) instead
      // of a client-only guess.
      await _loadDoctors();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save doctor: $e')),
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

    if (confirmed != true) return;

    final idsToDelete = List<String>.from(_selectedIds);

    try {
      for (final id in idsToDelete) {
        await _service.deleteDoctor(id);
      }

      if (!mounted) return;
      setState(() {
        _doctors.removeWhere((d) => idsToDelete.contains(d.id));
        _selectedIds.clear();
        _deleteMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete: $e')),
      );
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
              child: _buildBody(),
            ),
            const SizedBox(height: 8),
            if (!_deleteMode)
              Row(
                children: [
                  Expanded(
                    child: _PillButton(
                      label: 'Add',
                      color: DoctorColors.addGreen,
                      onPressed: _openAddDoctor,
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DoctorColors.subtitleText),
          ),
        ),
      );
    }

    if (_doctors.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        return DoctorCard(
          doctor: doctor,
          selectionMode: _deleteMode,
          selected: _selectedIds.contains(doctor.id),
          onTap: _deleteMode ? () => _toggleSelected(doctor.id) : null,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No doctors added yet.\nTap "Add" to add your doctor.',
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