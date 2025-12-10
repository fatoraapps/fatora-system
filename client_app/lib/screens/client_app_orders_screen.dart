// lib/screens/client_app_orders_screen.dart
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
      body: const Center(
        child: Text(
          "📦 الطلبات (قيد التطوير)",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
