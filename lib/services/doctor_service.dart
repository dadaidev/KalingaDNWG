import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/doctor.dart';

/// Bridges the local [Doctor] UI model to public.my_doctors -- a personal
/// list of doctors the current user has saved (distinct from the shared
/// public.doctors catalog used for appointment booking; this table is
/// per-user via user_id + RLS, not global).
class DoctorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _requireUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user. Please log in again.');
    }
    return user.id;
  }

  /// Fetch the current user's saved doctors, most recently added first.
  Future<List<Doctor>> getMyDoctors() async {
    final userId = _requireUserId;

    final data = await _supabase
        .from('my_doctors')
        .select('id, full_name, specialty, hospital')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data)
        .map((row) => Doctor(
              id: row['id'].toString(),
              name: row['full_name'] ?? '',
              specialty: row['specialty'] ?? '',
              hospital: row['hospital'] ?? '',
            ))
        .toList();
  }

  /// Insert a new saved doctor for the current user. Returns the saved
  /// [Doctor] with its real database id.
  Future<Doctor> addDoctor({
    required String fullName,
    required String specialty,
    required String hospital,
  }) async {
    final userId = _requireUserId;

    final row = await _supabase
        .from('my_doctors')
        .insert({
          'user_id': userId,
          'full_name': fullName,
          'specialty': specialty,
          'hospital': hospital,
        })
        .select('id')
        .single();

    return Doctor(
      id: row['id'].toString(),
      name: fullName,
      specialty: specialty,
      hospital: hospital,
    );
  }

  /// Remove a saved doctor. RLS also restricts this to the owning user,
  /// but the explicit .eq('user_id', ...) keeps the intent clear here too.
  Future<void> deleteDoctor(String id) async {
    final userId = _requireUserId;

    await _supabase
        .from('my_doctors')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
}