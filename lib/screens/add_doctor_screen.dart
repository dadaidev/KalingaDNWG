import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import 'doctor_colors.dart';

/// Result returned when the user taps "Add" on the Add My Doctor form.
class AddDoctorResult {
  final String fullName;
  final String specialty;
  final String hospital;

  AddDoctorResult({
    required this.fullName,
    required this.specialty,
    required this.hospital,
  });
}

/// Simple "add a doctor to my list" form -- just the doctor's name and
/// specialty. This replaced the old checkup-request form, which asked for
/// unrelated fields (address, age, purpose) that don't belong on a
/// personal doctor list.
class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _hospitalController = TextEditingController();

  // Doctor tab index, kept consistent with the rest of the app's BottomBar:
  // Appointment(0), Cabinet(1), Home(2), Doctor(3), Setting(4)
  static const int _tabIndex = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      AddDoctorResult(
        fullName: _nameController.text.trim(),
        specialty: _specialtyController.text.trim(),
        hospital: _hospitalController.text.trim(),
      ),
    );
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  InputDecoration _fieldDecoration({String? hint}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: DoctorColors.inputBorder, width: 1),
    );

    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(color: DoctorColors.subtitleText),
      filled: true,
      fillColor: DoctorColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: DoctorColors.dialogTeal, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: DoctorColors.deleteRed, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: Container(
        color: DoctorColors.pageBackground,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Doctor',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: DoctorColors.titleText,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DoctorColors.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabeledField(
                          label: 'Full Name',
                          child: TextFormField(
                            controller: _nameController,
                            decoration: _fieldDecoration(hint: "e.g. Dr. Jose P. Rizal"),
                            validator: (value) => (value == null ||
                                    value.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildLabeledField(
                          label: 'Specialty',
                          child: TextFormField(
                            controller: _specialtyController,
                            decoration: _fieldDecoration(hint: "e.g. Cardiologist"),
                            validator: (value) => (value == null ||
                                    value.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildLabeledField(
                          label: 'Hospital',
                          child: TextFormField(
                            controller: _hospitalController,
                            decoration: _fieldDecoration(hint: "e.g. CP Reyes"),
                            validator: (value) => (value == null ||
                                    value.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PillButton(
                      label: 'Add',
                      color: DoctorColors.addGreen,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PillButton(
                      label: 'Cancel',
                      color: DoctorColors.deleteRed,
                      onPressed: _cancel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _tabIndex,
        onTap: (_) {}, // Form stays modal-like; ignore tab taps here.
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: DoctorColors.titleText,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

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