import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscure = true;
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _nameC = TextEditingController();
  final _confirmC = TextEditingController();
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmail(_emailC.text.trim(), _passC.text);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on Exception catch (e) {
      _showError(e.toString());
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passC.text != _confirmC.text) { _showError('Passwords do not match'); return; }
    setState(() => _isLoading = true);
    try {
      await _auth.signUpWithEmail(_nameC.text.trim(), _emailC.text.trim(), _passC.text);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on Exception catch (e) {
      _showError(e.toString());
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await _auth.signInWithGoogle();
      if (result != null && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } on Exception catch (e) {
      _showError(e.toString());
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: AppColors.errorContainer));
  }

  void _forgotPassword() {
    final emailCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: Text('Reset Password', style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface)),
      content: TextField(controller: emailCtrl, style: const TextStyle(color: AppColors.onSurface),
        decoration: InputDecoration(hintText: 'Enter your email', hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.outline)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.electricCyan)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () async {
          await _auth.sendPasswordResetEmail(emailCtrl.text.trim());
          if (mounted) { Navigator.pop(ctx); _showError('Reset email sent!'); }
        }, child: Text('Send', style: TextStyle(color: AppColors.electricCyan))),
      ],
    ));
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label, labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
    prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
    filled: true, fillColor: AppColors.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.electricCyan, width: 1.5)),
    errorStyle: TextStyle(color: AppColors.error),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(width: 64, height: 64, decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [AppColors.electricCyan.withOpacity(0.2), AppColors.deepViolet.withOpacity(0.1)]),
                  border: Border.all(color: AppColors.glassBorder)),
                  child: const Icon(Icons.view_in_ar, color: AppColors.electricCyan, size: 32)),
                const SizedBox(height: 24),
                Text(_isSignUp ? 'Create Account' : 'Welcome Back',
                    style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 24),
                // Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerHigh, borderRadius: BorderRadius.circular(50)),
                  child: Row(children: [
                    _tab('SIGN IN', !_isSignUp, () => setState(() => _isSignUp = false)),
                    _tab('SIGN UP', _isSignUp, () => setState(() => _isSignUp = true)),
                  ]),
                ),
                const SizedBox(height: 24),
                // Glass card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground, borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.glassBorder)),
                  child: Column(children: [
                    if (_isSignUp) ...[
                      TextFormField(controller: _nameC, style: const TextStyle(color: AppColors.onSurface),
                        decoration: _inputDeco('Full Name', Icons.person_outline),
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(controller: _emailC, style: const TextStyle(color: AppColors.onSurface),
                      decoration: _inputDeco('Email', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.contains('@') ? null : 'Invalid email'),
                    const SizedBox(height: 16),
                    TextFormField(controller: _passC, obscureText: _obscure,
                      style: const TextStyle(color: AppColors.onSurface),
                      decoration: _inputDeco('Password', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.onSurfaceVariant, size: 20), onPressed: () => setState(() => _obscure = !_obscure))),
                      validator: (v) => v!.length < 6 ? 'Min 6 chars' : null),
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      TextFormField(controller: _confirmC, obscureText: true,
                        style: const TextStyle(color: AppColors.onSurface),
                        decoration: _inputDeco('Confirm Password', Icons.lock_outline),
                        validator: (v) => v != _passC.text ? 'No match' : null),
                    ],
                    if (!_isSignUp) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight,
                        child: GestureDetector(onTap: _forgotPassword,
                          child: Text('Forgot Password?', style: GoogleFonts.inter(fontSize: 13, color: AppColors.electricCyan)))),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_isSignUp ? _signUp : _signIn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricCyan, foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          elevation: 0),
                        child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                          : Text(_isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN  →',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      )),
                  ]),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Divider(color: AppColors.outline.withOpacity(0.3))),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or continue with', style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant))),
                  Expanded(child: Divider(color: AppColors.outline.withOpacity(0.3))),
                ]),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _googleSignIn,
                    icon: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    label: Text('Google', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      side: BorderSide(color: AppColors.glassBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                  )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String text, bool active, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.electricCyan : Colors.transparent,
          borderRadius: BorderRadius.circular(50)),
        child: Center(child: Text(text, style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2,
            color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant))))));
  }
}
