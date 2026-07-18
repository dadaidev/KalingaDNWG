import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../models/appointment.dart';
import 'book_appointment_screen.dart';
import '../widgets/bottom_bar.dart';
import 'cabinet_screen.dart';
import 'home_page.dart';
import 'doctor_screen.dart';
import 'settings_screen.dart';

class AppointmentScreen extends StatefulWidget {
  final String userName;

  const AppointmentScreen({super.key, this.userName = ''});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final AppointmentService _service = AppointmentService();

  
  String? _patientId;
  Future<List<Appointment>>? _appointmentsFuture;
  bool _isResolvingPatient = true;
  String? _patientResolutionError;

  int _selectedIndex = 0;
  static const int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _resolvePatientAndLoad();
  }

  Future<void> _resolvePatientAndLoad() async {
    setState(() {
      _isResolvingPatient = true;
      _patientResolutionError = null;
    });

    try {
      final patientId = await _service.getCurrentPatientId();

      if (patientId == null) {
        setState(() {
          _isResolvingPatient = false;
          _patientResolutionError =
              'No patient record is linked to this account yet. '
              'Please contact support or complete your profile setup.';
        });
        return;
      }

      setState(() {
        _patientId = patientId;
        _isResolvingPatient = false;
      });

      _loadAppointments();
    } catch (e) {
      setState(() {
        _isResolvingPatient = false;
        _patientResolutionError = 'Could not load your patient profile: $e';
      });
    }
  }

  void _loadAppointments() {
    if (_patientId == null) return;
    setState(() {
      _appointmentsFuture = _service.getMyAppointments(_patientId!);
      _selectedIndex = 0;
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

  void _onTabTapped(int index) {
    if (index == _tabIndex) return;

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
      body: _buildBody(),
      bottomNavigationBar: BottomBar(
        currentIndex: _tabIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildBody() {
    if (_isResolvingPatient) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_patientResolutionError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _patientResolutionError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return FutureBuilder<List<Appointment>>(
      future: _appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading dashboard: ${snapshot.error}'));
        }

        final appointments = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookAppointmentScreen(),
                            ),
                          ).then((_) {
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
                    Expanded(
                      child: ElevatedButton(
                        onPressed: appointments.isEmpty
                            ? null
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
    );
  }
}