import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import 'cabinet_colors.dart';
import 'medicine_card.dart';
import 'medicine_model.dart';
import 'add_medicine_screen.dart';
import 'appointment_screen.dart';
import 'home_page.dart';
import 'doctor_screen.dart';
import 'settings_screen.dart';

class CabinetScreen extends StatefulWidget {
  final List<Medicine> initialMedicines;
  final String userName; // needed so we can navigate to the other tabs

  const CabinetScreen({
    super.key,
    this.initialMedicines = const [],
    required this.userName,
  });

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  late List<Medicine> _medicines;
  bool _deleteMode = false;
  final Set<String> _selectedIds = {};

  // Cabinet is index 1: Appointment(0), Cabinet(1), Home(2), Doctor(3), Settings(4)
  static const int _tabIndex = 1;

  // Appointment, Home, Doctor, and Settings all have real screens now,
  // so every tab navigates. Uses pushReplacement so the stack stays
  // consistent across all tabs (no back-stack pileup between tabs).
  void _onTabTapped(int index) {
    if (index == _tabIndex) return; // already here

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AppointmentScreen(userName: widget.userName),
          ),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomePage(userName: widget.userName),
          ),
        );
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DoctorScreen(userName: widget.userName),
          ),
        );
        break;
      case 4:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SettingsScreen(userName: widget.userName),
          ),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _medicines = List.of(widget.initialMedicines);
  }

  void _toggleDeleteMode() {
    setState(() {
      if (_deleteMode) {
        // Cancel out of selection mode.
        _deleteMode = false;
        _selectedIds.clear();
      } else if (_medicines.isEmpty) {
        // Nothing to delete.
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

  Future<void> _openAddMedicine() async {
    final newMedicine = await Navigator.of(context).push<Medicine>(
      MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
    );
    if (newMedicine != null) {
      setState(() => _medicines.add(newMedicine));
    }
  }

  Future<void> _confirmDelete() async {
    if (_selectedIds.isEmpty) {
      // Tapping Delete with nothing selected just cancels selection mode.
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
        _medicines.removeWhere((m) => _selectedIds.contains(m.id));
        _selectedIds.clear();
        _deleteMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(), // adjust props if your TopBar constructor needs any
      body: Container(
        color: CabinetColors.pageBackground,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Medicine',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CabinetColors.titleText,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _medicines.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      itemCount: _medicines.length,
                      itemBuilder: (context, index) {
                        final medicine = _medicines[index];
                        return MedicineCard(
                          medicine: medicine,
                          selectionMode: _deleteMode,
                          selected: _selectedIds.contains(medicine.id),
                          onTap: _deleteMode
                              ? () => _toggleSelected(medicine.id)
                              : null,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: 'Add',
                    color: CabinetColors.addGreen,
                    onPressed: _deleteMode ? null : _openAddMedicine,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _PillButton(
                    label: _deleteMode ? 'Cancel' : 'Delete',
                    color: _deleteMode
                        ? CabinetColors.subtitleText
                        : CabinetColors.deleteRed,
                    onPressed: _toggleDeleteMode,
                  ),
                ),
              ],
            ),
            if (_deleteMode) ...[
              const SizedBox(height: 10),
              _PillButton(
                label: 'Confirm Delete (${_selectedIds.length})',
                color: CabinetColors.deleteRed,
                onPressed: _selectedIds.isEmpty ? null : _confirmDelete,
                fullWidth: true,
              ),
            ],
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
        'No medicines added yet.\nTap "Add" to get started.',
        textAlign: TextAlign.center,
        style: TextStyle(color: CabinetColors.subtitleText, fontSize: 14),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const _PillButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
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
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
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
          color: CabinetColors.dialogTeal,
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
                    color: CabinetColors.addGreen,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PillButton(
                    label: 'Cancel',
                    color: CabinetColors.deleteRed,
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