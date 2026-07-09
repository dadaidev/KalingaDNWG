import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. FETCH BOOKING FORM DATA
  
  // Fetch patients for the "Select Patient" dropdown
  Future<List<Map<String, dynamic>>> getPatients() async {
    final data = await _supabase
        .from('patients')
        .select('id, full_name');
    return List<Map<String, dynamic>>.from(data);
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