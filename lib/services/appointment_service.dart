import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. FETCH BOOKING FORM DATA

  // Fetch users (patients) for the "Select Patient" dropdown.
  // NOTE: the old `patients` table was merged into `users` — the
  // primary key here is `user_id`, not `id`.
  Future<List<Map<String, dynamic>>> getPatients() async {
    final data = await _supabase
        .from('users')
        .select('user_id, full_name');
    return List<Map<String, dynamic>>.from(data);
  }

  // Resolves the signed-in user's own patient/user id, for screens that
  // show "my appointments" rather than letting the user pick a patient
  // from a dropdown. Returns null if either nobody is signed in, or the
  // signed-in auth user has no matching row in public.users — which can
  // happen if the on_auth_user_created trigger ever failed to fire for
  // an older account created before that trigger existed.
  Future<String?> getCurrentPatientId() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final row = await _supabase
        .from('users')
        .select('user_id')
        .eq('user_id', authUser.id)
        .maybeSingle();

    return row?['user_id'] as String?;
  }

  // Fetch unique doctor specialties for the "Select Specialty" dropdown
  Future<List<String>> getSpecialties() async {
    final List<dynamic> data = await _supabase
        .from('doctors')
        .select('specialty');

    // Extract strings and remove duplicates safely
    final specialties = data
        .where((d) => d['specialty'] != null)
        .map((d) => d['specialty'] as String)
        .toSet()
        .toList();
    return specialties;
  }

  // Fetch every date that currently has at least one available_slots row
  // AND is today or later, sorted ascending. Past dates are excluded —
  // even though they still technically have slot rows in the DB, they're
  // not bookable, so showing them would let someone select a dead date.
  Future<List<DateTime>> getAvailableDates() async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final todayStr =
        '${todayDateOnly.year}-${todayDateOnly.month.toString().padLeft(2, '0')}-${todayDateOnly.day.toString().padLeft(2, '0')}';

    final data = await _supabase
        .from('available_slots')
        .select('date')
        .gte('date', todayStr)
        .order('date', ascending: true);

    final dates = <DateTime>{};
    for (final row in List<Map<String, dynamic>>.from(data)) {
      final dateStr = row['date'] as String?;
      if (dateStr != null) dates.add(DateTime.parse(dateStr));
    }
    final sorted = dates.toList()..sort();
    return sorted;
  }

  // Fetch doctors along with their available slots based on specialty and date
  Future<List<Map<String, dynamic>>> getDoctorsWithSlots(String specialty, String dateString) async {
    // Uses '!inner' join filtering so doctors with 0 matching active slots are omitted entirely
    final data = await _supabase
        .from('doctors')
        .select('''
          id, full_name, specialty, rating, hospital,
          available_slots!inner (id, time_slot, date)
        ''')
        .eq('specialty', specialty)
        .eq('available_slots.date', dateString);

    return List<Map<String, dynamic>>.from(data);
  }

  /// 2. CONFIRM BOOKING ACTION
  // NOTE: `appointments.patient_id` still has that column name, but it now
  // references `users.user_id` (the signed-in user's auth id), not the old
  // `patients.id`.
  Future<void> confirmBooking({
    required String patientId,
    required String doctorId,
    required String date,
    required String timeSlot,
    String? reason,
  }) async {
    await _supabase.from('appointments').insert({
      'patient_id': patientId,
      'doctor_id': doctorId,
      'date': date,
      'time_slot': timeSlot,
      'reason': reason ?? '',
      'status': 'Upcoming',
    });
  }

  /// 3. MY APPOINTMENTS DASHBOARD FUNCTIONS
  Future<List<Appointment>> getMyAppointments(String patientId) async {
    final List<dynamic> data = await _supabase
        .from('appointments')
        .select('''
          id, date, time_slot, status, reason,
          doctors (id, full_name, specialty, rating, hospital)
        ''')
        .eq('patient_id', patientId)
        .order('date', ascending: true);

    return data.map((json) => Appointment.fromJson(json)).toList();
  }

  // Handle cancelling/updating status states
  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    await _supabase
        .from('appointments')
        .update({'status': newStatus})
        .eq('id', appointmentId);
  }

  // Handle the 'Delete' button action on the screen
  Future<void> deleteAppointment(String appointmentId) async {
    await _supabase
        .from('appointments')
        .delete()
        .eq('id', appointmentId);
  }
}