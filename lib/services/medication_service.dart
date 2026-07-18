import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/medicine_model.dart';

/// Bridges the local [Medicine] UI model to the real Supabase schema,
/// which splits data across three tables:
///   - public.medications           (the medicine's own details)
///   - public.medication_reminders  (the schedule: time, frequency, meal, end_date)
///   - public.medication_logs       (per-day Taken/Missed/Skipped history)
///
/// Note: `medications.medication_id` is an auto-incrementing integer in
/// the database, but [Medicine.id] is a String in the UI model (originally
/// a client-generated placeholder). We store the real DB id as a String
/// here for compatibility with the existing model, parsing back to int
/// only when calling Supabase.
///
/// Note: `medication_reminders.before_after_meal` has a CHECK constraint
/// that only accepts the exact strings 'Before Meal' / 'After Meal'
/// (title case, with " Meal" suffix) -- not 'before'/'after'.
///
/// Note: `medication_logs.status` has a CHECK constraint that only
/// accepts the exact strings 'Taken' / 'Missed' / 'Skipped' (title case).
/// `medication_logs.reminder_id` -> `medication_reminders.reminder_id`
/// ON DELETE CASCADE, so logs are cleaned up automatically only if a
/// reminder row is hard-deleted -- which we now avoid (see deleteMedication).
///
/// Note: `medication_reminders.end_date` is an optional cutoff date for
/// the recurring schedule. Null means "recurs indefinitely" -- callers
/// building calendar/schedule views should stop recurrence at this date
/// when it's set.
///
/// Note: `medications.deleted_at` implements a SOFT delete. Deleting a
/// medicine from the UI does NOT remove its row (which would cascade-
/// delete its reminders and, through them, its medication_logs history).
/// Instead it just stamps deleted_at, and getMedications() excludes any
/// row where deleted_at is set. getMedicationHistory() intentionally does
/// NOT filter on deleted_at, so a medicine's Taken/Missed/Skipped history
/// stays visible in Settings even after the medicine itself is "deleted".
class MedicationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _requireUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user. Please log in again.');
    }
    return user.id;
  }

  String _mealLabel(MealTiming meal) =>
      meal == MealTiming.before ? 'Before Meal' : 'After Meal';

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Fetch all *active* (non-deleted) medications for the current user,
  /// joined with their reminder schedule.
  Future<List<Medicine>> getMedications() async {
    final userId = _requireUserId;

    final data = await _supabase
        .from('medications')
        .select('''
          medication_id, medicine_name, generic_name, medicine_type,
          dosage, purpose,
          medication_reminders (reminder_id, reminder_time, frequency, before_after_meal, start_date, end_date)
        ''')
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data)
        .map(_mapRowToMedicine)
        .toList();
  }

  /// Insert a new medication + its reminder schedule.
  /// Returns the saved [Medicine] with its real database id and reminderId.
  Future<Medicine> addMedication(Medicine medicine) async {
    final userId = _requireUserId;

    // 1. Insert into medications, get back the auto-generated id.
    final medicationRow = await _supabase
        .from('medications')
        .insert({
      'user_id': userId,
      'medicine_name': medicine.name,
      'generic_name': medicine.genericName,
      'medicine_type': medicine.type.label,
      'dosage': medicine.dosage,
      'purpose': medicine.purpose,
    })
        .select('medication_id')
        .single();

    final medicationId = medicationRow['medication_id'] as int;

    // 2. Insert the schedule into medication_reminders using that id,
    // and get back the auto-generated reminder_id so we can log against it.
    final timeOfDay = medicine.timeToTake;
    final reminderTime =
        '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}:00';
    final startDate = dateKey(timeOfDay);
    final endDate = medicine.endDate != null ? dateKey(medicine.endDate!) : null;

    final reminderRow = await _supabase
        .from('medication_reminders')
        .insert({
      'medication_id': medicationId,
      'reminder_time': reminderTime,
      'frequency': medicine.frequency,
      'before_after_meal': _mealLabel(medicine.meal),
      'start_date': startDate,
      'end_date': endDate,
    })
        .select('reminder_id')
        .single();

    final reminderId = reminderRow['reminder_id'] as int;

    // Medicine.id is final, so build a fresh instance carrying the real
    // database ids (and the end date that's now actually persisted)
    // rather than trying to mutate the one passed in.
    return Medicine(
      id: medicationId.toString(),
      name: medicine.name,
      genericName: medicine.genericName,
      type: medicine.type,
      dosage: medicine.dosage,
      purpose: medicine.purpose,
      frequency: medicine.frequency,
      timeToTake: medicine.timeToTake,
      meal: medicine.meal,
      isActive: medicine.isActive,
      reminderId: reminderId,
      endDate: medicine.endDate,
    );
  }

  /// Update an existing medication + its reminder schedule.
  Future<void> updateMedication(Medicine medicine) async {
    final userId = _requireUserId;
    final medicationId = int.parse(medicine.id);

    await _supabase
        .from('medications')
        .update({
      'medicine_name': medicine.name,
      'generic_name': medicine.genericName,
      'medicine_type': medicine.type.label,
      'dosage': medicine.dosage,
      'purpose': medicine.purpose,
    })
        .eq('medication_id', medicationId)
        .eq('user_id', userId);

    final timeOfDay = medicine.timeToTake;
    final reminderTime =
        '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}:00';
    final startDate = dateKey(timeOfDay);
    final endDate = medicine.endDate != null ? dateKey(medicine.endDate!) : null;

    // Update the existing reminder row for this medication (assumes one
    // active reminder per medication, matching the current single-schedule UI).
    // end_date is set explicitly to null when the user clears it, not
    // just omitted, so clearing an existing end date actually persists.
    await _supabase
        .from('medication_reminders')
        .update({
      'reminder_time': reminderTime,
      'frequency': medicine.frequency,
      'before_after_meal': _mealLabel(medicine.meal),
      'start_date': startDate,
      'end_date': endDate,
    })
        .eq('medication_id', medicationId);
  }

  /// Soft-delete a medication: stamps deleted_at instead of removing the
  /// row, so its medication_reminders row (and, through it, its
  /// medication_logs history) is left completely intact. getMedications()
  /// excludes anything with deleted_at set, so it disappears from the
  /// active Cabinet list immediately, while getMedicationHistory() keeps
  /// showing its past Taken/Missed/Skipped entries.
  Future<void> deleteMedication(String medicineId) async {
    final userId = _requireUserId;
    final medicationId = int.parse(medicineId);

    await _supabase
        .from('medications')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('medication_id', medicationId)
        .eq('user_id', userId);
  }

  // --- medication_logs: daily Taken/Missed/Skipped tracking ---

  /// Fetch logs for a set of reminder ids within an inclusive date range.
  /// Returns a flat map keyed "reminderId_yyyy-MM-dd" -> status, matching
  /// how HomePage looks entries up (it builds the same key format itself
  /// and does `.split('_').last` to recover the date). Days with no row
  /// in medication_logs simply won't have a key here.
  Future<Map<String, String>> getLogsForReminders({
    required List<int> reminderIds,
    required DateTime start,
    required DateTime end,
  }) async {
    if (reminderIds.isEmpty) return {};

    final data = await _supabase
        .from('medication_logs')
        .select('reminder_id, taken_date, status')
        .inFilter('reminder_id', reminderIds)
        .gte('taken_date', dateKey(start))
        .lte('taken_date', dateKey(end));

    final result = <String, String>{};
    for (final row in List<Map<String, dynamic>>.from(data)) {
      final reminderId = row['reminder_id'] as int;
      final takenDate = row['taken_date'] as String;
      final status = row['status'] as String;
      result['${reminderId}_$takenDate'] = status;
    }
    return result;
  }

  /// Create or update the log entry for a given reminder + date.
  /// [status] must be exactly 'Taken', 'Missed', or 'Skipped' (DB CHECK
  /// constraint enforces this; anything else will throw from Supabase).
  Future<void> setLogStatus({
    required int reminderId,
    required DateTime date,
    required String status,
  }) async {
    final takenDate = dateKey(date);
    final now = DateTime.now();
    final takenTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

    // No unique constraint on (reminder_id, taken_date) was shown in the
    // schema, so we check for an existing row ourselves to avoid duplicate
    // log entries for the same day.
    final existing = await _supabase
        .from('medication_logs')
        .select('log_id')
        .eq('reminder_id', reminderId)
        .eq('taken_date', takenDate)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('medication_logs').insert({
        'reminder_id': reminderId,
        'taken_date': takenDate,
        'taken_time': takenTime,
        'status': status,
      });
    } else {
      await _supabase
          .from('medication_logs')
          .update({'taken_time': takenTime, 'status': status})
          .eq('log_id', existing['log_id']);
    }
  }

  // --- Medication history: all logged doses, most recent first ---

  /// Fetch the current user's full medication log history for display in
  /// Settings > Medication History -- every logged dose regardless of
  /// status (Taken / Missed / Skipped), most recent first, so the UI can
  /// show what was actually taken vs. not.
  ///
  /// Deliberately does NOT filter on medications.deleted_at: history for
  /// a medicine the user has since "deleted" (soft-deleted) should still
  /// show up here, since the underlying medications/medication_reminders
  /// rows are never actually removed.
  ///
  /// Returns string maps with a 'status' key alongside name/date so
  /// SettingsScreen can render an appropriate badge/icon per row.
  Future<List<Map<String, String>>> getMedicationHistory() async {
    final userId = _requireUserId;

    final data = await _supabase
        .from('medication_logs')
        .select('''
          log_id, taken_date, taken_time, status,
          medication_reminders!inner (
            reminder_id,
            medications!inner (medication_id, medicine_name, dosage, user_id)
          )
        ''')
        .eq('medication_reminders.medications.user_id', userId)
        .order('taken_date', ascending: false)
        .order('taken_time', ascending: false);

    return List<Map<String, dynamic>>.from(data).map((row) {
      final reminder = row['medication_reminders'] as Map<String, dynamic>?;
      final medication = reminder?['medications'] as Map<String, dynamic>?;

      final name = medication?['medicine_name']?.toString() ?? 'Unknown medicine';
      final dosage = medication?['dosage']?.toString() ?? '';
      final date = row['taken_date']?.toString() ?? '';
      final time = row['taken_time']?.toString() ?? '';
      final status = row['status']?.toString() ?? '';

      return {
        'name': dosage.isNotEmpty ? '$name ($dosage)' : name,
        'date': time.isNotEmpty ? '$date  •  $time' : date,
        'status': status,
      };
    }).toList();
  }

  // --- Mapping helpers ---

  Medicine _mapRowToMedicine(Map<String, dynamic> row) {
    final reminders = row['medication_reminders'] as List<dynamic>?;
    final reminder = (reminders != null && reminders.isNotEmpty)
        ? reminders.first as Map<String, dynamic>
        : null;

    DateTime timeToTake;
    MealTiming meal = MealTiming.after;
    String frequency = '';
    int? reminderId;
    DateTime? endDate;

    if (reminder != null) {
      reminderId = reminder['reminder_id'] as int?;
      final startDateStr = reminder['start_date'] as String?;
      final reminderTimeStr = reminder['reminder_time'] as String?;
      final endDateStr = reminder['end_date'] as String?;
      final date = startDateStr != null ? DateTime.parse(startDateStr) : DateTime.now();

      int hour = 0;
      int minute = 0;
      if (reminderTimeStr != null) {
        final parts = reminderTimeStr.split(':');
        hour = int.tryParse(parts[0]) ?? 0;
        minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      }

      timeToTake = DateTime(date.year, date.month, date.day, hour, minute);
      meal = (reminder['before_after_meal'] == 'Before Meal') ? MealTiming.before : MealTiming.after;
      frequency = reminder['frequency']?.toString() ?? '';
      endDate = endDateStr != null ? DateTime.parse(endDateStr) : null;
    } else {
      timeToTake = DateTime.now();
    }

    return Medicine(
      id: row['medication_id'].toString(),
      name: row['medicine_name'] ?? '',
      genericName: row['generic_name'] ?? '',
      type: _typeFromLabel(row['medicine_type']?.toString() ?? ''),
      dosage: row['dosage'] ?? '',
      purpose: row['purpose'] ?? '',
      frequency: frequency,
      timeToTake: timeToTake,
      meal: meal,
      isActive: true,
      reminderId: reminderId,
      endDate: endDate,
    );
  }

  MedicineType _typeFromLabel(String label) {
    for (final t in MedicineType.values) {
      if (t.label == label) return t;
    }
    return MedicineType.tablets; // fallback
  }
}