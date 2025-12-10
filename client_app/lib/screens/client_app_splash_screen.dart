// lib/screens/client_app_splash_screen.dart
// ===========================================================
// Code: client_app_screen_splash
// شاشة البداية لتطبيق "فاتورة عميل"
// ===========================================================

import 'package:flutter/material.dart';

class ClientAppSplashScreen extends StatefulWidget {
  const ClientAppSplashScreen({super.key});

  @override
  State<ClientAppSplashScreen> createState() =>
      _ClientAppSplashScreenState();
}

class _ClientAppSplashScreenState extends State<ClientAppSplashScreen> {
  @override
  void initState() {
    super.initState();

    // بعد ثانيتين → الانتقال لشاشة تسجيل الدخول
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/client/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFC800),
                Color(0xFFFFF3CC),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // شعار دائري
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF000000)
                              .withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 42,
                          color: Color(0xFF1D3557),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'فاتورة عميل',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D3557),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'مرحبًا بك في فاتورة عميل',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'منصتك لطلب المنتجات من الموردين وتتبع الفواتير بسهولة.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1D3557),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'جاري التحضير لدخولك...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
