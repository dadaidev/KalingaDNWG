import 'package:flutter/material.dart';
import '../services/appointment_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AppointmentService _service = AppointmentService();

  // Selected State Variables
  String? _selectedPatientId;
  String? _selectedSpecialty;
  String? _selectedDoctorId;
  String? _selectedTimeSlot;
  DateTime _selectedDate = DateTime(2026, 7, 15); // Default display target date matching seed rows

  // Text controller for optional visit description
  final TextEditingController _reasonController = TextEditingController();

  // UI Data Holders
  List<Map<String, dynamic>> _patients = [];
  List<String> _specialties = [];
  List<Map<String, dynamic>> _doctorsWithSlots = [];
  bool _isLoadingDoctors = false;

  // Generates timeline grid targets for July 2026 alignment
  final List<DateTime> _julyDays = List.generate(7, (index) => DateTime(2026, 7, 13 + index));

  @override
  void initState() {
    super.initState();
    _loadInitialFormData();
  }

  // FIXED: Correct asynchronous ordering sequence
  Future<void> _loadInitialFormData() async {
    try {
      final patientsData = await _service.getPatients();
      final specialtiesData = await _service.getSpecialties();
      
      setState(() {
        _patients = patientsData;
        _specialties = specialtiesData;
        
        // 1. Assign default patient selection if array contains records
        if (_patients.isNotEmpty) {
          _selectedPatientId = _patients.first['id']?.toString();
        }
        
        // 2. Assign default active specialty filtering string BEFORE invoking lookups
        if (_specialties.isNotEmpty) {
          _selectedSpecialty = _specialties.first;
        }
      });

      // 3. Fire database query only after variables are verified as assigned
      if (_selectedSpecialty != null) {
        _fetchAvailableDoctors();
      }
    } catch (e) {
      _showSnackbar('Initialization Error: $e');
    }
  }

  Future<void> _fetchAvailableDoctors() async {
    if (_selectedSpecialty == null) return;
    
    setState(() {
      _isLoadingDoctors = true;
      _doctorsWithSlots = [];
      _selectedDoctorId = null;
      _selectedTimeSlot = null;
    });

    try {
      final formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      final doctorsData = await _service.getDoctorsWithSlots(_selectedSpecialty!, formattedDate);
      
      setState(() {
        _doctorsWithSlots = doctorsData;
      });
    } catch (e) {
      _showSnackbar('Error loading doctors: $e');
    } finally {
      setState(() {
        _isLoadingDoctors = false;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleBookingSubmission() async {
    if (_selectedPatientId == null || _selectedDoctorId == null || _selectedTimeSlot == null) {
      _showSnackbar('Please pick a Patient, Doctor, and specific Time Slot.');
      return;
    }

    try {
      final dateString = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      
      await _service.confirmBooking(
        patientId: _selectedPatientId!,
        doctorId: _selectedDoctorId!,
        date: dateString,
        timeSlot: _selectedTimeSlot!,
        reason: _reasonController.text.trim(),
      );

      _showSnackbar('Booking successfully confirmed!');
      Navigator.pop(context); 
    } catch (e) {
      _showSnackbar('Booking creation failed: $e');
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
          'Book Appointment',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SELECT PATIENT DROP-DOWN
            const Text('Select Patient:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedPatientId,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              items: _patients.map((p) {
                return DropdownMenuItem<String>(
                  value: p['id'].toString(),
                  child: Text(p['full_name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPatientId = val),
            ),

            const SizedBox(height: 16),

            // CALENDAR CAROUSEL HEADER STRIP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('July', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right, color: Colors.grey)),
              ],
            ),
            
            // TIMELINE MATRIX BUILDER
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _julyDays.length,
                itemBuilder: (context, index) {
                  final currentDay = _julyDays[index];
                  final isSelected = currentDay.day == _selectedDate.day;
                  final weekdayStr = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][currentDay.weekday % 7];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = currentDay;
                      });
                      _fetchAvailableDoctors();
                    },
                    child: Container(
                      width: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(weekdayStr, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${currentDay.day}', style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Selected Date: July ${_selectedDate.day}, ${_selectedDate.year}', 
                style: const TextStyle(color: Colors.grey),
              ),
            ),

            // SELECT SPECIALTY DROP-DOWN
            const Text('Select Specialty:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedSpecialty,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              items: _specialties.map((s) {
                return DropdownMenuItem<String>(value: s, child: Text(s));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedSpecialty = val);
                _fetchAvailableDoctors();
              },
            ),

            const SizedBox(height: 16),
            Text('Available Doctors (for ${_selectedSpecialty ?? ""}):', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // DOCTORS TRACK FEED LIST CONTAINER
            if (_isLoadingDoctors)
              const Center(child: CircularProgressIndicator())
            else if (_doctorsWithSlots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No doctors available with slots on this day.')),
              )
            else
              SizedBox(
                height: 240, 
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _doctorsWithSlots.length,
                  itemBuilder: (context, docIdx) {
                    final doc = _doctorsWithSlots[docIdx];
                    final docId = doc['id'].toString();
                    final isSelectedDoc = _selectedDoctorId == docId;
                    final slotsList = List<Map<String, dynamic>>.from(doc['available_slots'] ?? []);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDoctorId = docId;
                          _selectedTimeSlot = null; 
                        });
                      },
                      child: Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 12, bottom: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelectedDoc ? const Color(0xFF0288D1) : Colors.grey.shade200, 
                            width: isSelectedDoc ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircleAvatar(
                                radius: 25, 
                                backgroundColor: Colors.grey, 
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(doc['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                              Text(doc['specialty'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              Text('⭐ ${doc['rating'] ?? '5.0'}  ${doc['hospital'] ?? ''}', style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
                              
                              const Divider(height: 12),
                              
                              // SUB-SELECTION WRAP CHIPS (Error Free Container Representation)
                              slotsList.isEmpty
                                  ? const Text('No active slots', style: TextStyle(fontSize: 10, color: Colors.red))
                                  : Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: slotsList.map((slot) {
                                        final slotTime = slot['time_slot'].toString();
                                        final isSelectedSlot = _selectedTimeSlot == slotTime && isSelectedDoc;
                                        return ChoiceChip(
                                          label: Text(
                                            slotTime, 
                                            style: TextStyle(
                                              fontSize: 9, 
                                              color: isSelectedSlot ? Colors.white : Colors.black,
                                            ),
                                          ),
                                          selected: isSelectedSlot,
                                          selectedColor: const Color(0xFF0288D1),
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() {
                                                _selectedDoctorId = docId;
                                                _selectedTimeSlot = slotTime;
                                              });
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // VISIT REASON INPUT BOX
            const Text('Reason for Visit (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: "Enter reason...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // CONFIRM EXECUTION SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleBookingSubmission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7), 
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CONFIRM BOOKING', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}