import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../models/appointment.dart';
import 'book_appointment_screen.dart';
import '../widgets/bottom_bar.dart';
import 'cabinet_screen.dart';
import 'home_page.dart';
import 'doctor_screen.dart';

class AppointmentScreen extends StatefulWidget {
  // Pass the real signed-in user's name when you have it,
  // e.g. AppointmentScreen(userName: widget.userName) from HomePage/Cabinet.
  final String userName;

  const AppointmentScreen({super.key, this.userName = ''});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final AppointmentService _service = AppointmentService();

  // Patient ID linked to database seeds
  final String mockPatientId = 'a1111111-1111-1111-1111-111111111111';
  late Future<List<Appointment>> _appointmentsFuture;

  // Track selected appointment index for the Delete button target
  int _selectedIndex = 0;

  // Appointment is index 0 in the bottom tab order:
  // Appointment(0), Cabinet(1), Home(2), Doctor(3), Settings(4)
  static const int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    setState(() {
      _appointmentsFuture = _service.getMyAppointments(mockPatientId);
      _selectedIndex = 0; // Reset active selection
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.blue;
      case 'Done':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Cabinet, Home, and Doctor all have real screens now, so those tabs
  // navigate. Settings(4) is TODO until that screen exists. Uses
  // pushReplacement so the stack stays consistent across all tabs
  // (no back-stack pileup between tabs).
  void _onTabTapped(int index) {
    if (index == _tabIndex) return; // already here

    switch (index) {
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CabinetScreen(userName: widget.userName),
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
      default:
        // TODO: wire up Settings(4) once that screen exists.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A5F)),
        title: const Text(
          'My Appointments',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Appointment>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading dashboard: ${snapshot.error}'));
          }

          // Fallback to empty list if no data returned
          final appointments = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // DYNAMIC APPOINTMENT FEED LIST
                Expanded(
                  child: appointments.isEmpty
                      ? const Center(
                          child: Text(
                            'No appointments found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: appointments.length,
                          itemBuilder: (context, index) {
                            final item = appointments[index];
                            final doctorName = item.doctor?.fullName ?? 'Unknown Doctor';
                            final hospital = item.doctor?.hospital ?? 'Unknown Hospital';
                            final isSelected = _selectedIndex == index;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(color: const Color(0xFF1E3A5F), width: 2)
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          doctorName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E3A5F),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(item.status),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            item.status,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Time and Date: ${item.timeSlot} (${item.date})',
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                    ),
                                    Text(
                                      'Hospital/Clinic: $hospital',
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // FIXED INTERACTIVE FOOTER ACTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      // REQUEST ACTION BUTTON
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BookAppointmentScreen(),
                              ),
                            ).then((_) {
                              // Automatically refresh appointments when returning from booking screen
                              _loadAppointments();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Request', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // DELETE ACTION BUTTON
                      Expanded(
                        child: ElevatedButton(
                          onPressed: appointments.isEmpty
                              ? null // Disables the delete button when the list is empty
                              : () async {
                                  final targetAppointment = appointments[_selectedIndex];
                                  try {
                                    await _service.deleteAppointment(targetAppointment.id);
                                    _loadAppointments();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Appointment removed completely.')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Could not delete record: $e')),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _tabIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}