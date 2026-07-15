import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/top_bar.dart';
import '../widgets/bottom_bar.dart';
import 'home_page.dart';
import 'appointment_screen.dart';
import 'cabinet_screen.dart';
import 'doctor_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

/// Which modal card is currently expanded over the settings list.
/// `none` means the plain list is shown.
enum _SettingsModal { none, medicationHistory, about, feedback, logout }

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

  // TODO: replace with real medication history data from your storage/API.
  final List<Map<String, String>> _medicationHistory = [];

  // Holds the profile picture picked/uploaded by the user.
  // TODO: replace with a persisted image (e.g. saved path/URL from backend)
  // so it survives app restarts.
  File? _profileImage;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _openModal(_SettingsModal modal) {
    setState(() => _activeModal = modal);
  }

  void _closeModal() {
    setState(() => _activeModal = _SettingsModal.none);
  }

  void _onTabTapped(int index) {
    if (index == _tabIndex) return; // already on Settings

    final Widget destination = switch (index) {
      0 => AppointmentScreen(userName: widget.userName),
      1 => CabinetScreen(userName: widget.userName),
      2 => HomePage(userName: widget.userName),
      3 => DoctorScreen(userName: widget.userName),
      _ => SettingsScreen(userName: widget.userName),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Future<void> _openProfile() async {
    // Pass the currently selected profile picture so the Profile
    // screen opens already showing it, and wait for whatever image
    // comes back when the user taps "Save Changes" there.
    final File? updatedImage = await Navigator.of(context).push<File?>(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          userName: widget.userName,
          currentProfileImage: _profileImage,
        ),
      ),
    );

    // ProfileScreen only pops with a non-null value from inside
    // _saveProfile (i.e. after tapping "Save Changes"). Pressing the
    // default back button returns null and is ignored here, so an
    // existing picture is never accidentally cleared.
    if (updatedImage != null) {
      setState(() => _profileImage = updatedImage);
    }
  }

  /// Opens the image picker so the user can choose/upload a profile photo.
  /// The picked image replaces the default avatar icon.
  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
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
                    userName: widget.userName,
                    profileImage: _profileImage,
                    onTap: _openProfile,
                    onAvatarTap: _pickProfileImage,
                  ),
                  const SizedBox(height: 15),

                  _SettingsTile(
                    icon: Icons.medication_outlined,
                    label: "Medication History",
                    onTap: () => _openModal(_SettingsModal.medicationHistory),
                  ),
                  const SizedBox(height: 15),

                  _SettingsTile(
                    icon: Icons.info_outline,
                    label: "About Kalinga",
                    onTap: () => _openModal(_SettingsModal.about),
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
            child: _medicationHistory.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "No medication history yet.",
                      style: TextStyle(color: Colors.black45),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListView.separated(
                      itemCount: _medicationHistory.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _medicationHistory[index];
                        return ListTile(
                          dense: true,
                          title: Text(item["name"] ?? ""),
                          subtitle: Text(item["date"] ?? ""),
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
                  hintText: "You can write your feedback's here",
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
                onPressed: () {
                  // TODO: send _feedbackController.text to your backend.
                  _feedbackController.clear();
                  _closeModal();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F6E8C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Submit"),
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
  final File? profileImage;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  const _ProfileTile({
    required this.userName,
    required this.profileImage,
    required this.onTap,
    required this.onAvatarTap,
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
            // Tapping the avatar lets the user upload/replace their
            // profile picture. Once an image is picked, it is shown
            // here instead of the default placeholder.
            GestureDetector(
              onTap: onAvatarTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF1F6E8C),
                    backgroundImage:
                        profileImage != null ? FileImage(profileImage!) : null,
                    // No fallback person icon anymore — if there's no
                    // image yet, the circle just stays a plain color
                    // with a small camera hint below.
                  ),
                  if (profileImage == null)
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
                          Icons.add_a_photo_outlined,
                          size: 14,
                          color: Color(0xFF1F6E8C),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Profile",
                  style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                ),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  child: const Icon(Icons.close, size: 20, color: Colors.black45),
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