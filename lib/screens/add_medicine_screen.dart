import 'package:flutter/material.dart';
import 'cabinet_colors.dart';
import 'medicine_model.dart';

/// "Add Medicine" form screen.
///
/// Wrapped in its own Scaffold so TextFormField/DropdownButton/etc. have a
/// proper Material ancestor. Push this with Navigator and it returns a
/// [Medicine] via Navigator.pop when the user taps Add, or null when they
/// Cancel.
class AddMedicineScreen extends StatefulWidget {
  final Medicine? existing; // pass in to edit, leave null to create new

  const AddMedicineScreen({super.key, this.existing});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _genericCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _purposeCtrl;
  late final TextEditingController _frequencyCtrl;

  MedicineType? _type;
  DateTime? _timeToTake;
  MealTiming _meal = MealTiming.after;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _genericCtrl = TextEditingController(text: e?.genericName ?? '');
    _dosageCtrl = TextEditingController(text: e?.dosage ?? '');
    _purposeCtrl = TextEditingController(text: e?.purpose ?? '');
    _frequencyCtrl = TextEditingController(text: e?.frequency ?? '');
    _type = e?.type;
    _timeToTake = e?.timeToTake;
    _meal = e?.meal ?? MealTiming.after;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericCtrl.dispose();
    _dosageCtrl.dispose();
    _purposeCtrl.dispose();
    _frequencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _timeToTake ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timeToTake ?? now),
    );
    if (time == null) return;

    setState(() {
      _timeToTake = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null || _timeToTake == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Medicine Type and Time to Take.')),
      );
      return;
    }

    final medicine = Medicine(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      genericName: _genericCtrl.text.trim(),
      type: _type!,
      dosage: _dosageCtrl.text.trim(),
      purpose: _purposeCtrl.text.trim(),
      frequency: _frequencyCtrl.text.trim(),
      timeToTake: _timeToTake!,
      meal: _meal,
      isActive: widget.existing?.isActive ?? true,
    );

    Navigator.of(context).pop(medicine);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CabinetColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'Add Medicine' : 'Edit Medicine',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: CabinetColors.titleText,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CabinetColors.formBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Medicine Name'),
                          _TextInput(
                            controller: _nameCtrl,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Generic Name'),
                          _TextInput(controller: _genericCtrl),
                          const SizedBox(height: 12),
                          _FieldLabel('Medicine Type'),
                          _TypeDropdown(
                            value: _type,
                            onChanged: (v) => setState(() => _type = v),
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Pieces/Dosage'),
                          _TextInput(
                            controller: _dosageCtrl,
                            hint: 'e.g. 1pc Only',
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Purpose/Condition'),
                          _TextInput(controller: _purposeCtrl, minLines: 3, maxLines: 5),
                          const SizedBox(height: 12),
                          _FieldLabel('Frequency'),
                          _TextInput(
                            controller: _frequencyCtrl,
                            hint: 'e.g. Once a day',
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Time to Take'),
                          _TimePickerField(value: _timeToTake, onTap: _pickTime),
                          const SizedBox(height: 12),
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Meal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: CabinetColors.titleText,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _MealRadio(
                                      label: 'Before',
                                      selected: _meal == MealTiming.before,
                                      onTap: () =>
                                          setState(() => _meal = MealTiming.before),
                                    ),
                                    const SizedBox(width: 24),
                                    _MealRadio(
                                      label: 'After',
                                      selected: _meal == MealTiming.after,
                                      onTap: () =>
                                          setState(() => _meal = MealTiming.after),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PillButton(
                      label: widget.existing == null ? 'Add' : 'Save',
                      color: CabinetColors.addGreen,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PillButton(
                      label: 'Cancel',
                      color: CabinetColors.deleteRed,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: CabinetColors.titleText,
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;

  const _TextInput({
    required this.controller,
    this.hint,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  final MedicineType? value;
  final ValueChanged<MedicineType?> onChanged;

  const _TypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MedicineType>(
          value: value,
          isExpanded: true,
          hint: const Text('Select type'),
          items: MedicineType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;

  const _TimePickerField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? 'Select date & time'
        : '${TimeOfDay.fromDateTime(value!).format(context)}, '
            '${value!.month}/${value!.day}/${value!.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: CabinetColors.subtitleText),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: CabinetColors.titleText)),
          ],
        ),
      ),
    );
  }
}

class _MealRadio extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MealRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: CabinetColors.titleText,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: CabinetColors.titleText)),
          ],
        ),
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