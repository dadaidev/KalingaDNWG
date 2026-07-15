import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Kalinga DNWG - Profile Screen
/// Reached from Settings > Profile. Lets the user upload/change their
/// profile photo, edit their username and password, and view their
/// My Medication and Appointment History summaries.
///
/// When the user taps "Save Changes", the currently selected profile
/// image is popped back to the caller (Settings screen) so the two
/// screens stay in sync.
class ProfileScreen extends StatefulWidget {
  final String userName;

  /// The profile image currently shown on the Settings screen, if any.
  /// Passed in so this screen starts with the same picture already
  /// selected instead of resetting to blank every time it's opened.
  final File? currentProfileImage;

  const ProfileScreen({
    super.key,
    required this.userName,
    this.currentProfileImage,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  final TextEditingController _usernameController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ---- Palette (matched to Settings screen / mockups) ----
  static const Color kDarkTeal = Color(0xFF1E5A66);
  static const Color kAccentTeal = Color(0xFF2C7A8C);
  static const Color kPageBg = Color(0xFFDCEFF2);
  static const Color kFieldBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    // Start with whatever picture is already set on the Settings screen.
    _profileImage = widget.currentProfileImage;
    _usernameController.text = widget.userName;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Let the user choose between camera and gallery.
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1000,
      );
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
        // TODO: upload _profileImage to backend / storage here.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get image: $e')),
        );
      }
    }
  }

  void _saveProfile() {
    // TODO: persist username / password changes to backend.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved successfully.')),
    );

    // Send the (possibly new) profile picture back to the Settings
    // screen so it shows up there immediately, without needing a
    // shared state manager or backend round-trip.
    Navigator.of(context).pop(_profileImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        backgroundColor: kPageBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: kDarkTeal),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: kDarkTeal,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: kAccentTeal,
                      backgroundImage:
                          _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? const Icon(Icons.person, size: 52, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _pickImage,
                    child: Text(
                      'Upload Image',
                      style: TextStyle(
                        color: kDarkTeal.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FieldLabel('Edit Username'),
            const SizedBox(height: 6),
            _EditableField(
              controller: _usernameController,
              hintText: 'Enter your username',
            ),
            const SizedBox(height: 18),
            _FieldLabel('Edit Password'),
            const SizedBox(height: 6),
            _EditableField(
              controller: _passwordController,
              hintText: 'Enter new password',
              obscureText: true,
            ),
            const SizedBox(height: 18),
            _FieldLabel('My Medication'),
            const SizedBox(height: 6),
            _InfoBox(
              // TODO: replace with actual medication list from data source.
              child: _EmptyHint(text: 'No medications listed yet.'),
            ),
            const SizedBox(height: 18),
            _FieldLabel('Appointment History'),
            const SizedBox(height: 6),
            _InfoBox(
              // TODO: replace with actual appointment history from data source.
              child: _EmptyHint(text: 'No appointment history yet.'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDarkTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saveProfile,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
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
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        color: _ProfileScreenState.kDarkTeal,
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const _EditableField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfileScreenState.kFieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ProfileScreenState.kAccentTeal.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: _ProfileScreenState.kDarkTeal),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Widget child;
  const _InfoBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ProfileScreenState.kFieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ProfileScreenState.kAccentTeal.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}