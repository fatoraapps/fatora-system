// lib/screens/client_app_reports_screen.dart
import 'package:flutter/material.dart';

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
      body: const Center(
        child: Text(
          "📊 تقارير المشتريات (قيد التطوير)",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
