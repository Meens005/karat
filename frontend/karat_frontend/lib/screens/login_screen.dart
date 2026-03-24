// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../services/gold_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter username and password.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await GoldApiService.login(username, password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
      await prefs.setString('username', username);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Icon
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.currency_exchange_rounded, color: AppTheme.gold, size: 34),
                ),
              ),

              const SizedBox(height: 32),

              Text('Welcome Back',
                style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Sign in to access gold rate predictions',
                style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 14)),

              const SizedBox(height: 40),

              // Username
              _label('Username'),
              const SizedBox(height: 6),
              _field(controller: _userCtrl, hint: 'admin  or  user@gold.app', icon: Icons.person_outline_rounded),

              const SizedBox(height: 20),

              // Password
              _label('Password'),
              const SizedBox(height: 6),
              _field(
                controller: _passCtrl,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.grey, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                          style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Login button
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _login,
                  child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                    : Text('Sign In',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 16),

              // Skip
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                  child: Text('Continue without login →',
                    style: GoogleFonts.dmSans(color: AppTheme.gold.withOpacity(0.7), fontSize: 13)),
                ),
              ),

              const SizedBox(height: 32),

              // Hint box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Test Credentials',
                      style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _cred('admin', 'admin'),
                    const SizedBox(height: 4),
                    _cred('user@gold.app', 'gold1234'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600));

  Widget _cred(String user, String pass) => Row(
    children: [
      Text('$user  /  $pass',
        style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 12)),
    ],
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surface),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: Colors.grey.shade700, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}