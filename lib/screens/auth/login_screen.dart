import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:medication_reminder_app/providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().signIn(
        _emailController.text.trim(),
        _passController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _getFriendlyError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getFriendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found.';
      case 'wrong-password':
        return 'Incorrect password.';
      default:
        return 'Login failed. Try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  SizedBox(height: 32),
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  SizedBox(height: 32),
                  _buildTextField(
                    _emailController,
                    Icons.email_outlined,
                    'Email',
                    validator: (v) => v!.isEmpty || !v.contains('@')
                        ? 'Valid email required'
                        : null,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    _passController,
                    Icons.lock_outline,
                    'Password',
                    obscure: _obscurePass,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                  ),
                  if (_error != null) _buildError(_error!),
                  SizedBox(height: 24),
                  _buildButton(
                    'Sign In',
                    _isLoading ? null : _login,
                    _isLoading,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => SignupScreen()),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.blue.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade400, Colors.blue.shade700],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Icon(Icons.medication, color: Colors.white, size: 40),
  );

  Widget _buildTextField(
    TextEditingController c,
    IconData icon,
    String hint, {
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade400),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
          suffixIcon: suffix,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildError(String msg) => Container(
    margin: EdgeInsets.only(top: 8),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade900.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade700.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade300, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(color: Colors.red.shade300, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _buildButton(String text, VoidCallback? onPressed, bool loading) =>
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      );
}
