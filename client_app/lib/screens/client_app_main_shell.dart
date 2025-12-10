// lib/screens/client_app_main_shell.dart
// ===========================================================
// Shell رئيسي لتطبيق العميل مع BottomNavigationBar ثابت
// Tabs:
// 1) الرئيسية
// 2) السلة
// 3) الطلبات
// 4) التقارير
// 5) حسابي
// ===========================================================

import 'package:flutter/material.dart';

// ✅ استيراد الشاشات الخمسة
import 'client_app_home_screen.dart';
import 'client_app_cart_screen.dart';
import 'client_app_orders_screen.dart';
import 'client_app_reports_screen.dart';
import 'client_app_account_screen.dart';

class ClientAppMainShell extends StatefulWidget {
  final String clientId;

  const ClientAppMainShell({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientAppMainShell> createState() => _ClientAppMainShellState();
}

class _ClientAppMainShellState extends State<ClientAppMainShell> {
  int _selectedIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    // ✅ تأكد إن كل شاشة عندك فيها constructor يستقبل clientId: String
    _tabs = [
      ClientAppHomeScreen(clientId: widget.clientId),    // الرئيسية
      ClientAppCartScreen(clientId: widget.clientId),    // السلة
      ClientAppOrdersScreen(clientId: widget.clientId),  // الطلبات
      ClientAppReportsScreen(clientId: widget.clientId), // التقارير
      ClientAppAccountScreen(clientId: widget.clientId), // حسابي
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedItemColor: Colors.amber[800],
          unselectedItemColor: Colors.grey[500],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'السلة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'الطلبات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_outlined),
              activeIcon: Icon(Icons.insert_chart),
              label: 'تقارير',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}
