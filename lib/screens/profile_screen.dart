import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kalinga DNWG - Profile Screen
/// Reached from Settings > Profile. Lets the user upload/change their
/// profile photo and username.
///
/// Both the username and the profile picture are persisted to Supabase
/// (the `profiles` table + `avatars` storage bucket) when the user taps
/// "Save Changes". This is what makes them survive navigation -- they
/// are no longer just local widget state that resets whenever the
/// Settings screen is rebuilt (e.g. switching tabs).
///
/// NOTE: Appointment History was moved to the Settings screen as its
/// own modal (next to Medication History) so both history views live
/// in one place.
class ProfileScreen extends StatefulWidget {
  final String userName;

  /// The avatar URL currently shown on the Settings screen, if any.
  /// Passed in so this screen starts with the same picture already
  /// loaded instead of flashing blank while it re-fetches.
  final String? currentAvatarUrl;

  const ProfileScreen({
    super.key,
    required this.userName,
    this.currentAvatarUrl,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  /// Bagong pinili na larawan na hindi pa naka-upload -- ipapakita agad
  /// (local preview) habang naghihintay ng "Save Changes".
  File? _pendingImage;

  /// Kasalukuyang naka-save na avatar URL mula sa database.
  String? _avatarUrl;

  bool _isSaving = false;

  final TextEditingController _usernameController = TextEditingController();

  // ---- Palette (matched to Settings screen / mockups) ----
  static const Color kDarkTeal = Color(0xFF1E5A66);
  static const Color kAccentTeal = Color(0xFF2C7A8C);
  static const Color kPageBg = Color(0xFFDCEFF2);
  static const Color kFieldBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.currentAvatarUrl;
    _usernameController.text = widget.userName;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
        setState(() => _pendingImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get image: $e')));
      }
    }
  }

  /// Ini-upload ang napiling larawan sa Supabase Storage, ibinabalik
  /// ang public URL nito. Ginagamit ang user_id bilang folder para
  /// consistent ang path at hindi mag-collide ang mga user.
  Future<String> _uploadAvatar(File imageFile, String userId) async {
    final supabase = Supabase.instance.client;
    final extension = imageFile.path.split('.').last;
    final filePath = '$userId/avatar.$extension';

    await supabase.storage
        .from('avatars')
        .upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    // Cache-bust ang URL gamit ang timestamp para agad ma-reflect ang
    // bagong larawan sa mga Image widget na naka-cache ng lumang URL.
    final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
    return '$publicUrl?updated=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveProfile() async {
    final newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('You must be logged in to save changes.');
      }

      String? newAvatarUrl = _avatarUrl;

      if (_pendingImage != null) {
        newAvatarUrl = await _uploadAvatar(_pendingImage!, userId);
      }

      await supabase.from('profiles').upsert({
        'id': userId,
        'username': newUsername,
        'avatar_url': newAvatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully.')),
      );

      // Ibalik ang bagong username at avatar URL papunta sa Settings
      // screen para agad ma-update ang display doon nang hindi na
      // kailangan mag-refetch.
      Navigator.of(
        context,
      ).pop({'username': newUsername, 'avatarUrl': newAvatarUrl});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  ImageProvider? get _avatarImageProvider {
    if (_pendingImage != null) return FileImage(_pendingImage!);
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    }
    return null;
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
                      backgroundImage: _avatarImageProvider,
                      child: _avatarImageProvider == null
                          ? const Icon(
                              Icons.person,
                              size: 52,
                              color: Colors.white,
                            )
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
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
        border: Border.all(
          color: _ProfileScreenState.kAccentTeal.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: _ProfileScreenState.kDarkTeal),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
