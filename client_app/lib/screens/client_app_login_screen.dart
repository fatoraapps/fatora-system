// lib/screens/client_app_login_screen.dart
// ===========================================================
// Code: client_app_screen_login
// شاشة تسجيل الدخول لتطبيق العميل - فاتورة عميل
// ===========================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientAppLoginScreen extends StatefulWidget {
  const ClientAppLoginScreen({super.key});

  @override
  State<ClientAppLoginScreen> createState() => _ClientAppLoginScreenState();
}

class _ClientAppLoginScreenState extends State<ClientAppLoginScreen> {
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ====================== Helpers ======================

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ====================== Login Logic ======================

  Future<void> _onLogin() async {
    final contact = _contactController.text.trim();
    final password = _passwordController.text.trim();

    if (contact.isEmpty) {
      _showMessage('من فضلك أدخل رقم التليفون المسجل.');
      return;
    }
    if (password.isEmpty) {
      _showMessage('من فضلك أدخل كلمة المرور.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1) جلب المستخدم من جدول users
      final user = await supabase
          .from('users')
          .select('user_id, user_password_hash, user_status')
          .eq('user_mobile', contact)
          .maybeSingle();

      if (user == null) {
        if (mounted) {
          _showMessage('لا يوجد حساب مسجل بهذا الرقم.');
          setState(() => _isLoading = false);
        }
        return;
      }

      final userStatus = user['user_status'] as int? ?? 1;
      if (userStatus != 1) {
        if (mounted) {
          _showMessage('هذا الحساب غير نشط، برجاء التواصل مع الدعم.');
          setState(() => _isLoading = false);
        }
        return;
      }

      final storedHash = user['user_password_hash'] as String? ?? '';
      final inputHash = _hashPassword(password);

      if (storedHash != inputHash) {
        if (mounted) {
          _showMessage('كلمة المرور غير صحيحة.');
          setState(() => _isLoading = false);
        }
        return;
      }

      final String userId = user['user_id'] as String;

      // 2) جلب العميل المرتبط بنفس الـ user_id
      final client = await supabase
          .from('clients')
          .select('client_id, client_status')
          .eq('client_id', userId)
          .maybeSingle();

      if (client == null) {
        if (mounted) {
          _showMessage(
              'تم العثور على مستخدم بدون بيانات عميل. برجاء التواصل مع الدعم.');
          setState(() => _isLoading = false);
        }
        return;
      }

      final clientStatus = client['client_status'] as int? ?? 1;
      if (clientStatus != 1) {
        if (mounted) {
          _showMessage('هذا الحساب (العميل) غير نشط، برجاء التواصل مع الدعم.');
          setState(() => _isLoading = false);
        }
        return;
      }

      final String clientId = client['client_id'] as String;

      if (!mounted) return;

      setState(() => _isLoading = false);

      // 3) الذهاب إلى الـ Shell (الـ BottomNavigationBar)
      Navigator.pushReplacementNamed(
        context,
        '/client/main',
        arguments: {
          'clientId': clientId,
          'openCart': false,
          'targetSupplierId': null,
        },
      );
    } on PostgrestException catch (e) {
      debugPrint('Supabase DB Error (login): ${e.message}');
      if (mounted) {
        _showMessage('خطأ في الاتصال بقاعدة البيانات، حاول مرة أخرى.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      if (mounted) {
        _showMessage('حدث خطأ غير متوقع، حاول مرة أخرى.');
        setState(() => _isLoading = false);
      }
    }
  }

  // ====================== UI Helpers ======================

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey.shade700),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: "كلمة المرور",
          prefixIcon: Icon(Icons.lock, color: Colors.grey.shade700),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ====================== UI ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, size: 26),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),

                const SizedBox(height: 10),

                // اللوجو
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 52,
                    color: Color(0xFF1D3557),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'مرحبًا بعودتك!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D3557),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'قم بتسجيل الدخول للمتابعة إلى فاتورة عميل',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                _buildInputField(
                  controller: _contactController,
                  label: "رقم الهاتف المسجل",
                  icon: Icons.phone,
                  keyboard: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                _buildPasswordField(),

                const SizedBox(height: 24),

                // زر الدخول
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC800),
                      foregroundColor: Colors.black,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _onLogin,
                    child: _isLoading
                        ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                        : const Text(
                      "دخول",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/client/register');
                      },
                      child: const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1D3557),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('ليس لديك حساب؟', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
