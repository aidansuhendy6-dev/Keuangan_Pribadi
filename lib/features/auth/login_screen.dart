import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../core/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_pinController.text.length == 6) {
      context.read<AuthProvider>().login(_pinController.text);
      if (context.read<AuthProvider>().errorMessage.isNotEmpty) {
        _pinController.clear();
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.network(
                  'https://xbtdqjfmgthbnbgyujkv.supabase.co/storage/v1/object/public/Logo/logo_dompet_terkunci.png',
                  height: isMobile ? 100 : 120,
                ),
                const SizedBox(height: 24),
                // Name
                Text(
                  'Aidan Suhendy',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'Masukkan 6 digit PIN',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                // PIN Input (Masked)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _pinController,
                    focusNode: _focusNode,
                    obscureText: true,
                    obscuringCharacter: '●',
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      letterSpacing: isMobile ? 8 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      hintText: '○ ○ ○ ○ ○ ○',
                      hintStyle: TextStyle(
                        color: Colors.black12,
                        letterSpacing: isMobile ? 6 : 8,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 6) {
                        _handleLogin();
                      }
                    },
                  ),
                ),
                if (auth.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    auth.errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 32),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
