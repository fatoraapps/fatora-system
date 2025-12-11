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

// الشاشات
import 'client_app_home_screen.dart';
import 'client_app_cart_screen.dart';
import 'client_app_orders_screen.dart';
import 'client_app_reports_screen.dart';
import 'client_app_account_screen.dart';

class ClientAppMainShell extends StatefulWidget {
  final String clientId;

  /// openCart = فتح شاشة السلة تلقائيًا
  final bool openCart;

  /// targetSupplierId = افتح طلب مورد معيّن داخل السلة
  final int? targetSupplierId;

  const ClientAppMainShell({
    super.key,
    required this.clientId,
    this.openCart = false,
    this.targetSupplierId,
  });

  @override
  State<ClientAppMainShell> createState() => _ClientAppMainShellState();
}

class _ClientAppMainShellState extends State<ClientAppMainShell> {
  int _selectedIndex = 0;

  late List<Widget> _tabs;

  bool _cartAutoOpened = false;

  @override
  void initState() {
    super.initState();

    _tabs = [
      ClientAppHomeScreen(clientId: widget.clientId),
      ClientAppCartScreen(
        clientId: widget.clientId,
        targetSupplierId: widget.targetSupplierId, // ⭐ مهم جدًا
      ),
      ClientAppOrdersScreen(clientId: widget.clientId),
      ClientAppReportsScreen(clientId: widget.clientId),
      ClientAppAccountScreen(clientId: widget.clientId),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // اقرأ arguments من Route
    final args = ModalRoute.of(context)?.settings.arguments;

    if (!_cartAutoOpened && args is Map) {
      if (args['openCart'] == true) {
        setState(() {
          _selectedIndex = 1; // السلة
        });
        _cartAutoOpened = true;
      }

      if (args['supplierId'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tabs[1] = ClientAppCartScreen(
            clientId: widget.clientId,
            targetSupplierId: args['supplierId'],
          );

          setState(() {
            _selectedIndex = 1;
          });
        });
      }
    }
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
