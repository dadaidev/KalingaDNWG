import 'package:flutter/material.dart';
import 'cabinet_colors.dart';
import 'medicine_model.dart';
import '../services/medication_service.dart';

/// "Add Medicine" form screen.
///
/// Wrapped in its own Scaffold so TextFormField/DropdownButton/etc. have a
/// proper Material ancestor. Push this with Navigator and it returns a
/// [Medicine] via Navigator.pop when the user taps Add/Save (after it has
/// actually been saved to Supabase), or null when they Cancel.
class AddMedicineScreen extends StatefulWidget {
  final Medicine? existing; // pass in to edit, leave null to create new

  const AddMedicineScreen({super.key, this.existing});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicationService _service = MedicationService();

  // The database's medication_reminders.frequency column has a CHECK
  // constraint that only accepts these exact strings -- keep this list
  // in sync with that constraint if it ever changes.
  static const List<String> _frequencyOptions = [
    'Once Daily',
    'Twice Daily',
    'Every 8 Hours',
    'Every 12 Hours',
    'Weekly',
    'As Needed',
  ];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _genericCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _purposeCtrl;

  MedicineType? _type;
  DateTime? _timeToTake;
  MealTiming _meal = MealTiming.after;
  String? _frequency;
  // Optional cutoff date for the recurring schedule. Null means "runs
  // indefinitely", which is also the previous behavior before this field
  // existed (medication_reminders.end_date stayed null for every row).
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _genericCtrl = TextEditingController(text: e?.genericName ?? '');
    _dosageCtrl = TextEditingController(text: e?.dosage ?? '');
    _purposeCtrl = TextEditingController(text: e?.purpose ?? '');
    _type = e?.type;
    _timeToTake = e?.timeToTake;
    _meal = e?.meal ?? MealTiming.after;
    _endDate = e?.endDate;
    // Only pre-select if the existing value is one of the valid options
    // (older/legacy data may hold a free-text value that no longer matches).
    _frequency = _frequencyOptions.contains(e?.frequency) ? e!.frequency : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericCtrl.dispose();
    _dosageCtrl.dispose();
    _purposeCtrl.dispose();
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

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final earliestAllowed = _timeToTake ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? earliestAllowed,
      firstDate: earliestAllowed,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;

    setState(() => _endDate = date);
  }

  void _clearEndDate() {
    setState(() => _endDate = null);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == null || _timeToTake == null || _frequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Medicine Type, Frequency, and Time to Take.'),
        ),
      );
      return;
    }

    final draftMedicine = Medicine(
      // Placeholder id — real id comes back from Supabase after insert.
      // For edits, the existing real database id is kept as-is.
      id: widget.existing?.id ?? '0',
      name: _nameCtrl.text.trim(),
      genericName: _genericCtrl.text.trim(),
      type: _type!,
      dosage: _dosageCtrl.text.trim(),
      purpose: _purposeCtrl.text.trim(),
      frequency: _frequency!,
      timeToTake: _timeToTake!,
      meal: _meal,
      isActive: widget.existing?.isActive ?? true,
      reminderId: widget.existing?.reminderId,
      endDate: _endDate,
    );

    setState(() => _isSubmitting = true);

    try {
      Medicine savedMedicine;

      if (widget.existing == null) {
        // Create: insert into medications + medication_reminders,
        // get back the real database id.
        savedMedicine = await _service.addMedication(draftMedicine);
      } else {
        // Edit: update both tables for the existing medication_id.
        await _service.updateMedication(draftMedicine);
        savedMedicine = draftMedicine;
      }

      if (!mounted) return;
      Navigator.of(context).pop(savedMedicine);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save medicine: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                          _FrequencyDropdown(
                            value: _frequency,
                            options: _frequencyOptions,
                            onChanged: (v) => setState(() => _frequency = v),
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Time to Take'),
                          _TimePickerField(value: _timeToTake, onTap: _pickTime),
                          const SizedBox(height: 12),
                          _FieldLabel('End Date (optional)'),
                          _EndDatePickerField(
                            value: _endDate,
                            onTap: _pickEndDate,
                            onClear: _endDate != null ? _clearEndDate : null,
                          ),
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
                      onPressed: _isSubmitting ? null : _submit,
                      isLoading: _isSubmitting,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PillButton(
                      label: 'Cancel',
                      color: CabinetColors.deleteRed,
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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

class _FrequencyDropdown extends StatelessWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FrequencyDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Text('Select frequency'),
          items: options
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
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

/// Optional cutoff date for the recurring schedule. Shows "No end date"
/// when unset (the schedule then recurs indefinitely), with a small
/// clear (x) button once a date has been picked.
class _EndDatePickerField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _EndDatePickerField({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? 'No end date (recurs indefinitely)'
        : '${value!.month}/${value!.day}/${value!.year}';

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
            const Icon(Icons.event_busy, size: 18, color: CabinetColors.subtitleText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: const TextStyle(color: CabinetColors.titleText)),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                child: const Icon(Icons.close, size: 18, color: CabinetColors.subtitleText),
              ),
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
  final bool isLoading;

  const _PillButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
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
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
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