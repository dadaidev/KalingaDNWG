import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sign_up_screen.dart';
import 'forget_password.dart';
import 'home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  static const Color _darkBlue = Color(0xFF0D3B66);
  static const Color _fieldFill = Color(0xFFB2F0F2);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // NOTE: Supabase Auth only authenticates with email + password.
      // The `username` field is currently collected for display/context
      // only — it is NOT verified against the database, since
      // public.users does not have a `username` column yet (it stores
      // full_name, email, phone, password, created_at). If you want the
      // username to actually be checked at login, add a `username`
      // column to public.users and populate it during sign-up, then
      // query it here after a successful sign-in to confirm it matches.
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(userName: username),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onForgetPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForgetPassword()),
    );
  }

  void _onSignUp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black45),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Heart + people + pill logo
                      Image.asset(
                        'lib/Assets/kalinga.png',
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Log in to your Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _darkBlue,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // User Name field
                      TextField(
                        controller: _usernameController,
                        decoration: _fieldDecoration('User Name'),
                      ),
                      const SizedBox(height: 16),
                      // Email field (NEW)
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _fieldDecoration('Email'),
                      ),
                      const SizedBox(height: 16),
                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _fieldDecoration('Password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.black45,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Forgot Password link, right-aligned
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _onForgetPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forget Password',
                            style: TextStyle(
                              color: _darkBlue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // LOG IN button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _onLoginPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _darkBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            elevation: 4,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'LOG IN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Sign Up prompt -- tappable "Sign Up" navigates to SignUpScreen
                      GestureDetector(
                        onTap: _onSignUp,
                        behavior: HitTestBehavior.opaque,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: _darkBlue, fontSize: 14),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign Up',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: (TapGestureRecognizer()
                                  ..onTap = _onSignUp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}