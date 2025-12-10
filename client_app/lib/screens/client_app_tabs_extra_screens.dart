// lib/screens/client_app_tabs_extra_screens.dart
// ===========================================================
// شاشات تبويب إضافية: طلباتي - تقارير - حسابي
// مبدئيًا Placeholders لحين بناءها بالتفصيل
// ===========================================================

import 'package:flutter/material.dart';

class ClientAppOrdersScreen extends StatelessWidget {
  final String clientId;

  const ClientAppOrdersScreen({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'طلباتي',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: const Center(
        child: Text(
          'هنا سيتم عرض قائمة طلبات العميل',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class ClientAppReportsScreen extends StatelessWidget {
  final String clientId;

  const ClientAppReportsScreen({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'تقارير',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: const Center(
        child: Text(
          'هنا سيتم عرض تقارير المشتريات والاستهلاك',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class ClientAppAccountScreen extends StatelessWidget {
  final String clientId;

  const ClientAppAccountScreen({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'حسابي',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: const Center(
        child: Text(
          'بيانات الحساب – العنوان – التليفونات – إلخ',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
