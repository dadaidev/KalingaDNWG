import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import '../services/medication_service.dart';
import '../services/appointment_service.dart';
import '../models/appointment.dart';
import 'home_page.dart';
import 'appointment_screen.dart';
import 'cabinet_screen.dart';
import 'doctor_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

/// Which modal card is currently expanded over the settings list.
/// `none` means the plain list is shown.
enum _SettingsModal {
  none,
  medicationHistory,
  appointmentHistory,
  about,
  howToUse,
  feedback,
  logout,
}

class SettingsScreen extends StatefulWidget {
  final String userName;

  const SettingsScreen({super.key, required this.userName});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Appointment(0), Cabinet(1), Home(2), Doctor(3), Settings(4)
  static const int _tabIndex = 4;

  _SettingsModal _activeModal = _SettingsModal.none;

  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmittingFeedback = false;

  final MedicationService _medicationService = MedicationService();
  // Set fresh each time the Medication History modal is opened, so it
  // always reflects doses taken since the screen was last shown.
  Future<List<Map<String, String>>>? _medicationHistoryFuture;

  // Moved here from ProfileScreen so both history views live under
  // Settings. Set fresh each time the modal is opened, same pattern as
  // Medication History above.
  final AppointmentService _appointmentService = AppointmentService();
  Future<List<Appointment>>? _appointmentsFuture;

  // Naka-save na sa `profiles` table sa Supabase, kaya hindi na nawawala
  // kapag nagpalit ng tab (dati ay File _profileImage lang ito, local
  // state na nare-reset tuwing gumagawa ng bagong SettingsScreen instance
  // ang pushReplacement).
  String? _avatarUrl;
  late String _displayName;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _loadProfile();
  }

  /// Kinukuha ang naka-save na username at avatar_url mula sa
  /// `profiles` table.
  Future<void> _loadProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final row = await supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted || row == null) return;
      setState(() {
        _avatarUrl = row['avatar_url'] as String?;
        final savedUsername = row['username'] as String?;
        if (savedUsername != null && savedUsername.isNotEmpty) {
          _displayName = savedUsername;
        }
      });
    } catch (_) {
      // Wala pang profile row -- mananatili ang default na
      // widget.userName hanggang sa unang pag-save.
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// Kinukuha muna ang patient id ng naka-login (kaparehong paraan ng
  /// AppointmentScreen), tapos ang mga appointment nito, para lumabas
  /// ang Appointment History modal.
  void _loadAppointmentHistory() {
    _appointmentsFuture = _appointmentService.getCurrentPatientId().then((
      patientId,
    ) {
      if (patientId == null) {
        throw Exception('No patient record linked to this account.');
      }
      return _appointmentService.getMyAppointments(patientId);
    });
  }

  void _openModal(_SettingsModal modal) {
    if (modal == _SettingsModal.medicationHistory) {
      _medicationHistoryFuture = _medicationService.getMedicationHistory();
    } else if (modal == _SettingsModal.appointmentHistory) {
      _loadAppointmentHistory();
    }
    setState(() => _activeModal = modal);
  }

  void _closeModal() {
    setState(() => _activeModal = _SettingsModal.none);
  }

  void _onTabTapped(int index) {
    if (index == _tabIndex) return; // already on Settings

    final Widget destination = switch (index) {
      0 => AppointmentScreen(userName: _displayName),
      1 => CabinetScreen(userName: _displayName),
      2 => HomePage(userName: _displayName),
      3 => DoctorScreen(userName: _displayName),
      _ => SettingsScreen(userName: _displayName),
    };

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  Future<void> _openProfile() async {
    // Pass the currently saved username and avatar so the Profile
    // screen opens already showing them, and wait for whatever comes
    // back when the user taps "Save Changes" there.
    final result = await Navigator.of(context).push<Map<String, String?>>(
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(userName: _displayName, currentAvatarUrl: _avatarUrl),
      ),
    );

    // ProfileScreen only pops with a non-null Map from inside
    // _saveProfile (i.e. after tapping "Save Changes"). Pressing the
    // default back button returns null and is ignored here, so
    // existing values are never accidentally cleared.
    if (result != null) {
      setState(() {
        _avatarUrl = result['avatarUrl'];
        final newUsername = result['username'];
        if (newUsername != null && newUsername.isNotEmpty) {
          _displayName = newUsername;
        }
      });
    }
  }

  Future<void> _submitFeedback() async {
    final message = _feedbackController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSubmittingFeedback = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception("You must be logged in to submit feedback.");
      }

      await supabase.from('feedback').insert({
        'user_id': userId,
        'message': message,
      });

      _feedbackController.clear();
      if (mounted) {
        _closeModal();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thank you for your feedback!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit feedback: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingFeedback = false);
    }
  }

  void _logout() {
    // TODO: clear session/tokens here before navigating to your login screen.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopBar(),
      body: SafeArea(
        child: Stack(
          children: [
            // --- Base settings list ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Settings",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _ProfileTile(
                    userName: _displayName,
                    avatarUrl: _avatarUrl,
                    onTap: _openProfile,
                  ),
                  const SizedBox(height: 15),

                  _SettingsTile(
                    icon: Icons.medication_outlined,
                    label: "Medication History",
                    onTap: () => _openModal(_SettingsModal.medicationHistory),
                  ),
                  const SizedBox(height: 15),

                  _SettingsTile(
                    icon: Icons.event_note_outlined,
                    label: "Appointment History",
                    onTap: () => _openModal(_SettingsModal.appointmentHistory),
                  ),
                  const SizedBox(height: 15),

                  _SettingsTile(
                    icon: Icons.info_outline,
                    label: "About Kalinga",
                    onTap: () => _openModal(_SettingsModal.about),
                  ),
                  const SizedBox(height: 15),

                  _SettingsTile(
                    icon: Icons.help_outline,
                    label: "How to Use This App",
                    onTap: () => _openModal(_SettingsModal.howToUse),
                  ),
                  const SizedBox(height: 15),

                  _SettingsTile(
                    icon: Icons.chat_bubble_outline,
                    label: "Feedback",
                    onTap: () => _openModal(_SettingsModal.feedback),
                  ),
                  const SizedBox(height: 15),

                  _SettingsTile(
                    icon: Icons.phonelink_lock_outlined,
                    label: "Logout",
                    onTap: () => _openModal(_SettingsModal.logout),
                  ),
                ],
              ),
            ),

            // --- Scrim + modal overlay ---
            if (_activeModal != _SettingsModal.none) ...[
              GestureDetector(
                onTap: _closeModal,
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
              _buildModalCard(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        currentIndex: _tabIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildModalCard() {
    late final Widget content;

    switch (_activeModal) {
      case _SettingsModal.medicationHistory:
        content = _ModalCard(
          icon: Icons.medication_outlined,
          title: "Medication History",
          onClose: _closeModal,
          child: SizedBox(
            height: 320,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: FutureBuilder<List<Map<String, String>>>(
                future: _medicationHistoryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          "Could not load history: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black45),
                        ),
                      ),
                    );
                  }

                  final history = snapshot.data ?? [];

                  if (history.isEmpty) {
                    return const Center(
                      child: Text(
                        "No medication history yet.",
                        style: TextStyle(color: Colors.black45),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final status = item["status"] ?? "";

                      late final Color statusColor;
                      late final IconData statusIcon;
                      late final String statusLabel;
                      switch (status) {
                        case 'Taken':
                          statusColor = const Color(0xFF3FB86D);
                          statusIcon = Icons.check_circle;
                          statusLabel = 'Taken';
                          break;
                        case 'Missed':
                          statusColor = const Color(0xFFE64545);
                          statusIcon = Icons.cancel;
                          statusLabel = 'Missed';
                          break;
                        case 'Skipped':
                          statusColor = const Color(0xFFE99A4B);
                          statusIcon = Icons.remove_circle;
                          statusLabel = 'Skipped';
                          break;
                        default:
                          statusColor = Colors.black38;
                          statusIcon = Icons.help_outline;
                          statusLabel = status.isEmpty ? 'Unknown' : status;
                      }

                      return ListTile(
                        dense: true,
                        leading: Icon(statusIcon, color: statusColor, size: 20),
                        title: Text(item["name"] ?? ""),
                        subtitle: Text(item["date"] ?? ""),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
        break;

      case _SettingsModal.appointmentHistory:
        content = _ModalCard(
          icon: Icons.event_note_outlined,
          title: "Appointment History",
          onClose: _closeModal,
          child: SizedBox(
            height: 320,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: FutureBuilder<List<Appointment>>(
                future: _appointmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          "Could not load appointments: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black45),
                        ),
                      ),
                    );
                  }

                  final appointments = snapshot.data ?? [];

                  if (appointments.isEmpty) {
                    return const Center(
                      child: Text(
                        "No appointment history yet.",
                        style: TextStyle(color: Colors.black45),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: appointments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final appt = appointments[index];
                      final doctorName =
                          appt.doctor?.fullName ?? 'Unknown Doctor';
                      final hospital = appt.doctor?.hospital ?? '';

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          doctorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${appt.timeSlot} • ${appt.date}'
                          '${hospital.isNotEmpty ? '\n$hospital' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: hospital.isNotEmpty,
                        trailing: _AppointmentStatusChip(status: appt.status),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
        break;

      case _SettingsModal.about:
        content = _ModalCard(
          icon: Icons.info_outline,
          title: "About Kalinga",
          onClose: _closeModal,
          child: SizedBox(
            height: 420,
            child: SingleChildScrollView(
              child: Column(
                children: const [
                  _AboutParagraph(
                    "Kalinga DNWG is a mobile healthcare application "
                    "designed to help users manage their medications "
                    "safely and on time. The application provides "
                    "medication reminders, appointment scheduling, "
                    "and medicine tracking to promote better health "
                    "and improve medication adherence.",
                  ),
                  SizedBox(height: 14),
                  _AboutParagraph(
                    "The name \"Kalinga\" comes from the Filipino word "
                    "meaning care, reflecting our commitment to "
                    "supporting users in maintaining their health "
                    "through simple and reliable service.",
                  ),
                  SizedBox(height: 14),
                  _AboutHeading("Our Mission"),
                  SizedBox(height: 6),
                  _AboutParagraph(
                    "To provide an accessible and user-friendly "
                    "healthcare application that empowers individuals "
                    "to manage their medications, appointments, and "
                    "daily health routines effectively.",
                  ),
                  SizedBox(height: 14),
                  _AboutHeading("Our Vision"),
                  SizedBox(height: 6),
                  _AboutParagraph(
                    "To become a trusted digital healthcare "
                    "companion that improves medication adherence "
                    "and promotes healthier communities through "
                    "innovative technology.",
                  ),
                  SizedBox(height: 20),
                  _AboutHeading("Developed By"),
                  SizedBox(height: 4),
                  _AboutParagraph("DNWG Developers"),
                  _AboutParagraph("D - Dhyron"),
                  _AboutParagraph("N - Nash"),
                  _AboutParagraph("W - Wilson"),
                  _AboutParagraph("G - Gerald"),
                ],
              ),
            ),
          ),
        );
        break;

      case _SettingsModal.howToUse:
        content = _ModalCard(
          icon: Icons.help_outline,
          title: "How to Use This App",
          onClose: _closeModal,
          child: SizedBox(
            height: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _AboutHeading("1. Add Your Medicines"),
                  SizedBox(height: 6),
                  _AboutParagraph(
                    "Go to the Cabinet tab and add each medicine you "
                    "take, including its name, dosage, and the time "
                    "you need to take it. The app will use this to "
                    "build your daily schedule.",
                  ),
                  SizedBox(height: 14),
                  _AboutHeading("2. Check Today's Medicine"),
                  SizedBox(height: 6),
                  _AboutParagraph(
                    "On the Home tab, you'll see a calendar and a list "
                    "of medicines due for the selected day. Days with "
                    "a scheduled dose are marked on the calendar so "
                    "you can plan ahead.",
                  ),
                  SizedBox(height: 14),
                  _AboutHeading("3. Mark a Dose as Taken"),
                  SizedBox(height: 6),
                  _AboutParagraph(
                    "Tap a medicine card on the Home tab to update its "
                    "status. Each tap cycles it through Taken, Missed, "
                    "and Skipped, so your records stay accurate.",
                  ),
                  SizedBox(height: 14),
                  _AboutHeading("4. Book and Track Appointments"),
                  SizedBox(height: 6),
                  _AboutParagraph(
                    "Use the Appointment tab to schedule visits with "
                    "your doctor. You can review past and upcoming "
                    "appointments anytime under Settings > Appointment "
                    "History.",
                  ),
                  SizedBox(height: 14),
                  _AboutHeading("5. Review Your History"),
                  SizedBox(height: 6),
                  _AboutParagraph(
                    "Settings > Medication History shows a full record "
                    "of doses you've taken, missed, or skipped, so you "
                    "and your doctor can track your adherence over "
                    "time.",
                  ),
                  SizedBox(height: 14),
                  _AboutHeading("6. Keep Your Profile Updated"),
                  SizedBox(height: 6),
                  _AboutParagraph(
                    "Tap your name under Settings to update your "
                    "username or profile photo. Keeping this current "
                    "helps your doctor recognize your records.",
                  ),
                  SizedBox(height: 14),
                  _AboutHeading("Need Help?"),
                  SizedBox(height: 6),
                  _AboutParagraph(
                    "If something isn't working as expected, use the "
                    "Feedback option below to let the DNWG team know.",
                  ),
                ],
              ),
            ),
          ),
        );
        break;

      case _SettingsModal.feedback:
        content = _ModalCard(
          icon: Icons.chat_bubble_outline,
          title: "Feedback",
          onClose: _closeModal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "You can write your feedback here",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _isSubmittingFeedback ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6E8C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmittingFeedback
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Submit"),
              ),
            ],
          ),
        );
        break;

      case _SettingsModal.logout:
        content = _ModalCard(
          icon: Icons.phonelink_lock_outlined,
          title: "Logout",
          onClose: _closeModal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Are you sure you want to log out of Kalinga DNWG?",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                "You will need to log in again to access your medication "
                "reminders and account.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE23E3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Log out"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _closeModal,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        break;

      case _SettingsModal.none:
        content = const SizedBox.shrink();
        break;
    }

    return Align(
      alignment: const Alignment(0, -0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: content,
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.userName,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFCFE6EC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF1F6E8C),
                  backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: Color(0xFF1F6E8C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Profile",
                  style: TextStyle(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFCFE6EC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1F6E8C)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback onClose;

  const _ModalCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFCFE6EC),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1F6E8C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _AboutHeading extends StatelessWidget {
  final String text;
  const _AboutHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

class _AboutParagraph extends StatelessWidget {
  final String text;
  const _AboutParagraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, height: 1.4),
    );
  }
}

class _AppointmentStatusChip extends StatelessWidget {
  final String status;
  const _AppointmentStatusChip({required this.status});

  Color get _color {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
