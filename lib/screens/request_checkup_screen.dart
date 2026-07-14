import 'package:flutter/material.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import 'doctor_colors.dart';

/// Result returned when the user taps "Add" on the Request CheckUp form.
class CheckupRequest {
  final String fullName;
  final String address;
  final int age;
  final String purpose;

  CheckupRequest({
    required this.fullName,
    required this.address,
    required this.age,
    required this.purpose,
  });
}

class RequestCheckupScreen extends StatefulWidget {
  const RequestCheckupScreen({super.key});

  @override
  State<RequestCheckupScreen> createState() => _RequestCheckupScreenState();
}

class _RequestCheckupScreenState extends State<RequestCheckupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _purposeController = TextEditingController();

  int? _selectedAge;

  // Doctor tab index, kept consistent with the rest of the app's BottomBar:
  // Appointment(0), Cabinet(1), Home(2), Doctor(3), Setting(4)
  static const int _tabIndex = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedAge == null) {
      if (_selectedAge == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an age.')),
        );
      }
      return;
    }

    Navigator.of(context).pop(
      CheckupRequest(
        fullName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        age: _selectedAge!,
        purpose: _purposeController.text.trim(),
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
                'Request CheckUp',
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
                            decoration: _fieldDecoration(),
                            validator: (value) => (value == null ||
                                    value.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildLabeledField(
                          label: 'Address',
                          child: TextFormField(
                            controller: _addressController,
                            decoration: _fieldDecoration(),
                            validator: (value) => (value == null ||
                                    value.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildLabeledField(
                          label: 'Age',
                          child: DropdownButtonFormField<int>(
                            value: _selectedAge,
                            decoration: _fieldDecoration(),
                            isExpanded: true,
                            menuMaxHeight: 320,
                            items: List.generate(120, (i) => i + 1)
                                .map(
                                  (age) => DropdownMenuItem(
                                    value: age,
                                    child: Text('$age'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedAge = value);
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildLabeledField(
                          label: 'Purpose/Condition',
                          child: TextFormField(
                            controller: _purposeController,
                            maxLines: 5,
                            decoration: _fieldDecoration(),
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