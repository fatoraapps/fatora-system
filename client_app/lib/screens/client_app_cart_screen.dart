// lib/screens/client_app_cart_screen.dart
// ===========================================================
// Code: client_app_cart_screen
// شاشة سلة الطلبات لتطبيق العميل
// - تجمع العناصر الموجودة في CartManager
// - تعتمد على client_app_main_products_view عن طريق fetchHomeProducts
// - تعرض السلة مجمعة حسب المورد
// - لكل مورد "شريط" ملخص + صفحة تفاصيل طلب
// - زر عام أسفل الشاشة لإرسال كل الطلبات المستوفية للشروط
// ===========================================================

import 'package:flutter/material.dart';
import '../utils/order_dialog.dart';
import '../services/cart_manager.dart';
import '../services/product_repository.dart';
import '../models/client_app_main_product_model.dart';
import 'client_app_supplier_screen.dart';

// ألوان وثيم موحد
const Color _pageBackground = Color(0xFFF4F6F8);
const Color _primaryColor = Color(0xFFFFC800);
const Color _accentColor = Color(0xFF1565C0);
const Color _successColor = Color(0xFF2E7D32);
const Color _dangerColor = Color(0xFFD32F2F);
const Color _warningColor = Color(0xFFFFA000);
const double _cardRadius = 16.0;

class ClientAppCartScreen extends StatefulWidget {
  final String clientId;
  final int? targetSupplierId;   // ← إضافة جديدة

  const ClientAppCartScreen({
    super.key,
    required this.clientId,
    this.targetSupplierId,
  });

  @override
  State<ClientAppCartScreen> createState() => _ClientAppCartScreenState();
}


class _ClientAppCartScreenState extends State<ClientAppCartScreen> {
  final CartManager _cartManager = CartManager();
  final ProductRepository _repo = ProductRepository();
  final ScrollController _scrollController = ScrollController();

  int? _targetSupplierId;
  bool _scrollHandled = false; // مهم عشان ما نعملش scroll كل مرة

  bool _isLoading = true;
  String? _errorMessage;

  List<ClientAppMainProduct> _allProducts = [];
  bool _didAutoOpenSupplier = false;
  @override
  void initState() {
    super.initState();
    _targetSupplierId = widget.targetSupplierId;
    _loadProducts();
    _cartManager.addListener(_onCartChanged);

  }

  @override
  void dispose() {
    _cartManager.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // نجيب كل المنتجات المتاحة للعميل من الـ VIEW
      final products = await _repo.fetchHomeProducts(widget.clientId);

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء تحميل بيانات السلة: $e';
      });
    }
  }



  ClientAppMainProduct? _findProduct(
      int supplierId,
      String productCode,
      String unitNameAr,
      ) {
    for (final p in _allProducts) {
      if (p.supplierId == supplierId &&
          p.productCode == productCode &&
          p.unitNameAr == unitNameAr) {
        return p;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.7,
          title: const Text(
            'سلة الطلبات',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : _buildCartBody(),
      ),
    );
  }

  // ===================== جسم الشاشة =====================

  Widget _buildCartBody() {
    final items = _cartManager.items;
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 56, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'السلة فارغة حالياً',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // 1) نجمع العناصر حسب المورد
    final Map<int, List<CartLine>> supplierLines = {};

    items.forEach((key, qty) {
      if (qty <= 0) return;

      final parts = key.split('_');
      if (parts.length < 3) return;

      final supplierId = int.tryParse(parts[0]) ?? 0;
      final productCode = parts[1];
      final unitName = parts.sublist(2).join('_');

      final product = _findProduct(supplierId, productCode, unitName);
      if (product == null) return;

      // حساب الأسعار (عرض/عادي) بنفس منطق شاشة المورد
      final bool hasOffer =
          product.isOfferAvailable && product.finalOfferPriceAmount != null;

      final double basePrice = product.finalBasePriceAmount;
      final double offerPrice =
      hasOffer ? product.finalOfferPriceAmount! : basePrice;

      final int offerLimit = hasOffer ? (product.offerMaxQty ?? 0) : 0;
      final int baseLimit = product.baseMaxQty ?? 0;
      final int totalLimit =
          (offerLimit > 0 ? offerLimit : 0) + (baseLimit > 0 ? baseLimit : 0);

      int fullQty = qty;
      int offerQty = 0;
      int baseQty = 0;
      double lineTotal = 0.0;

      if (hasOffer && offerLimit > 0 && fullQty > offerLimit) {
        offerQty = offerLimit;
        baseQty = fullQty - offerLimit;
        lineTotal = offerQty * offerPrice + baseQty * basePrice;
      } else if (hasOffer) {
        offerQty = fullQty;
        baseQty = 0;
        lineTotal = fullQty * offerPrice;
      } else {
        offerQty = 0;
        baseQty = fullQty;
        lineTotal = fullQty * basePrice;
      }

      final line = CartLine(
        cartKey: key,
        supplierId: supplierId,
        supplierName: product.supplierNameAr,
        productCode: product.productCode,
        productName: product.productNameAr,
        unitName: unitName,
        product: product,
        quantity: fullQty,
        offerQty: offerQty,
        baseQty: baseQty,
        basePrice: basePrice,
        offerPrice: hasOffer ? offerPrice : null,
        totalLimit: totalLimit,
        hasOfferLimit: hasOffer && offerLimit > 0,
        lineTotal: lineTotal,
      );

      supplierLines.putIfAbsent(supplierId, () => []).add(line);
    });

    if (supplierLines.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد بيانات مطابقة في السلة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // 2) نحسب ملخص لكل مورد
    final List<SupplierOrderSummary> supplierOrders = [];

    supplierLines.forEach((supplierId, lines) {
      final firstProduct = lines.first.product;
      final supplierName = lines.first.supplierName;

      final double totalAmount =
      lines.fold(0.0, (sum, l) => sum + l.lineTotal);
      final int itemsCount = lines.length;

      final double minOrderValue = firstProduct.minOrderValue;
      final int minItemsCount = firstProduct.minItemsCount;

      final bool meetsValue = totalAmount >= minOrderValue;
      final bool meetsItems = itemsCount >= minItemsCount;

      supplierOrders.add(
        SupplierOrderSummary(
          supplierId: supplierId,
          supplierName: supplierName,
          lines: lines,
          totalAmount: totalAmount,
          itemsCount: itemsCount,
          minOrderValue: minOrderValue,
          minItemsCount: minItemsCount,
          meetsMinValue: meetsValue,
          meetsMinItems: meetsItems,
        ),
      );
    });
    final validOrders =
    supplierOrders.where((o) => o.meetsMinItems && o.meetsMinValue).toList();

    final bool canSendAny = validOrders.isNotEmpty;

    // 👇👇👇  الجزء الجديد المهم 👇👇👇
    if (widget.targetSupplierId != null && !_didAutoOpenSupplier) {
      final int targetId = widget.targetSupplierId!;
      SupplierOrderSummary? targetOrder;

      for (final o in supplierOrders) {
        if (o.supplierId == targetId) {
          targetOrder = o;
          break;
        }
      }

      // عشان ما نحاولش نفتحها كل ما الـ build يتنادى
      _didAutoOpenSupplier = true;

      if (targetOrder != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => SupplierOrderDetailsScreen(
                order: targetOrder!,
                clientId: widget.clientId,
              ),
            ),
          );
        });
      }
    }
    // 👆👆👆  لحد هنا الإضافة الجديدة 👆👆👆



    return Column(
      children: [
        // قائمة الموردين (شريط لكل مورد)
        Expanded(
          child: ListView.builder(
            controller: _scrollController,   // ← إضافة مهمة للتحكم في الحركة
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            itemCount: supplierOrders.length,
            itemBuilder: (context, index) {
              final supplier = supplierOrders[index];

              // إذا كان هذا هو المورد المطلوب → نعمل Scroll عليه مرة واحدة فقط
              if (!_scrollHandled &&
                  _targetSupplierId != null &&
                  supplier.supplierId == _targetSupplierId) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    _scrollController.animateTo(
                      index * 220, // ارتفاع تقريبي لكارت المورد
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                });
                _scrollHandled = true;
              }

              return _buildSupplierOrderCard(supplier);
            },
          ),
        ),


        // زر إرسال كل الطلبات
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 20),
              onPressed: !canSendAny
                  ? null
                  : () {
                for (final order in validOrders) {
                  showSubmitOrderDialog(
                    context: context,
                    totalAmount: order.totalAmount,
                    supplierId: order.supplierId,
                    supplierName: order.supplierName,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                canSendAny ? _primaryColor : Colors.grey.shade400,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: canSendAny ? 3 : 0,
              ),
              label: const Text(
                'إرسال كل الطلبات',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =============== كارت ملخص الطلب لمورد واحد ===============

  Widget _buildSupplierOrderCard(SupplierOrderSummary order) {
    final bool meetsValue = order.meetsMinValue;
    final bool meetsItems = order.meetsMinItems;
    final bool meetsAll = meetsValue && meetsItems;

    final statusText =
    meetsAll ? 'الطلب مستوفي الشروط' : 'الطلب غير مكتمل';
    final Color statusColor = meetsAll ? _successColor : _warningColor;
    final IconData statusIcon =
    meetsAll ? Icons.check_circle_rounded : Icons.info_rounded;

    // نسبة التقدم نحو الحد الأدنى للقيمة
    final double progress = order.minOrderValue > 0
        ? (order.totalAmount / order.minOrderValue).clamp(0.0, 1.0)
        : 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => SupplierOrderDetailsScreen(
                order: order,
                clientId: widget.clientId,
              ),
            ),
          );
        },
        child: Column(
          children: [
            // شريط علوي بسيط للمورد
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF7D1), Color(0xFFFFFFFF)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.store_mall_directory,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.supplierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha:0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قيمة الطلب الحالية + الحد الأدنى
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile(
                          title: 'قيمة الطلب',
                          value:
                          '${order.totalAmount.toStringAsFixed(2)} ج.م',
                          valueColor: _successColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoTile(
                          title: 'الحد الأدنى للقيمة',
                          value:
                          '${order.minOrderValue.toStringAsFixed(2)} ج.م',
                          valueColor:
                          meetsValue ? _successColor : _dangerColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar للقيمة
                  if (order.minOrderValue > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'التقدم نحو الحد الأدنى للقيمة',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0 ? _successColor : _primaryColor,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // عدد الأصناف
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 16,
                        color: meetsItems ? _successColor : _dangerColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'عدد الأصناف في السلة: ${order.itemsCount} من ${order.minItemsCount} كحد أدنى',
                          style: TextStyle(
                            fontSize: 11.5,
                            color:
                            meetsItems ? Colors.grey[800] : _dangerColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 0),

            // الأزرار (عرض تفاصيل الطلب + استكمال طلب منتجات من المورد)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => SupplierOrderDetailsScreen(
                              order: order,
                              clientId: widget.clientId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text(
                        'تفاصيل الطلب',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => ClientAppSupplierScreen(
                              clientId: widget.clientId,
                              supplierId: order.supplierId,
                              supplierName: order.supplierName,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text(
                        'استكمال الطلب من المورد',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        side: BorderSide(color: _accentColor.withValues(alpha:0.6)),
                        foregroundColor: _accentColor,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ===================== شاشة تفاصيل طلب مورد واحد =====================

class SupplierOrderDetailsScreen extends StatefulWidget {
  final SupplierOrderSummary order;
  final String clientId;

  const SupplierOrderDetailsScreen({
    super.key,
    required this.order,
    required this.clientId,
  });

  @override
  State<SupplierOrderDetailsScreen> createState() =>
      _SupplierOrderDetailsScreenState();
}

class _SupplierOrderDetailsScreenState
    extends State<SupplierOrderDetailsScreen> {
  final CartManager _cartManager = CartManager();

  @override
  void initState() {
    super.initState();
    _cartManager.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartManager.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  SupplierOrderSummary _buildCurrentOrder() {
    final Map<String, CartLine> baseMap = {
      for (final l in widget.order.lines)
        '${l.productCode}_${l.unitName}': l,
    };

    final List<CartLine> currentLines = [];

    _cartManager.items.forEach((key, qty) {
      if (qty <= 0) return;

      final parts = key.split('_');
      if (parts.length < 3) return;

      final supplierId = int.tryParse(parts[0]) ?? 0;
      if (supplierId != widget.order.supplierId) return;

      final productCode = parts[1];
      final unitName = parts.sublist(2).join('_');

      final baseKey = '${productCode}_$unitName';
      final baseLine = baseMap[baseKey];
      if (baseLine == null) return;

      final product = baseLine.product;

      final bool hasOffer =
          product.isOfferAvailable && product.finalOfferPriceAmount != null;
      final double basePrice = product.finalBasePriceAmount;
      final double offerPrice =
      hasOffer ? product.finalOfferPriceAmount! : basePrice;

      final int offerLimit = hasOffer ? (product.offerMaxQty ?? 0) : 0;
      final int baseLimit = product.baseMaxQty ?? 0;
      final int totalLimit =
          (offerLimit > 0 ? offerLimit : 0) + (baseLimit > 0 ? baseLimit : 0);

      final int fullQty = qty;
      int offerQty = 0;
      int baseQty = 0;
      double lineTotal = 0.0;

      if (hasOffer && offerLimit > 0 && fullQty > offerLimit) {
        offerQty = offerLimit;
        baseQty = fullQty - offerLimit;
        lineTotal = offerQty * offerPrice + baseQty * basePrice;
      } else if (hasOffer) {
        offerQty = fullQty;
        baseQty = 0;
        lineTotal = fullQty * offerPrice;
      } else {
        offerQty = 0;
        baseQty = fullQty;
        lineTotal = fullQty * basePrice;
      }

      currentLines.add(
        CartLine(
          cartKey: key,
          supplierId: supplierId,
          supplierName: baseLine.supplierName,
          productCode: productCode,
          productName: baseLine.productName,
          unitName: unitName,
          product: product,
          quantity: fullQty,
          offerQty: offerQty,
          baseQty: baseQty,
          basePrice: basePrice,
          offerPrice: hasOffer ? offerPrice : null,
          totalLimit: totalLimit,
          hasOfferLimit: hasOffer && offerLimit > 0,
          lineTotal: lineTotal,
        ),
      );
    });

    final lines = currentLines;

    double totalAmount = lines.fold(0.0, (sum, l) => sum + l.lineTotal);
    final int itemsCount = lines.length;

    final double minOrderValue = widget.order.minOrderValue;
    final int minItemsCount = widget.order.minItemsCount;

    final bool meetsValue = totalAmount >= minOrderValue;
    final bool meetsItems = itemsCount >= minItemsCount;

    return SupplierOrderSummary(
      supplierId: widget.order.supplierId,
      supplierName: widget.order.supplierName,
      lines: lines,
      totalAmount: totalAmount,
      itemsCount: itemsCount,
      minOrderValue: minOrderValue,
      minItemsCount: minItemsCount,
      meetsMinValue: meetsValue,
      meetsMinItems: meetsItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentOrder = _buildCurrentOrder();
    final bool meetsAll =
        currentOrder.meetsMinItems && currentOrder.meetsMinValue;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.7,
          title: Text(
            'طلب ${currentOrder.supplierName}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: Column(
          children: [
            // ملخص أعلى الشاشة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade100,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'قيمة الطلب: ${currentOrder.totalAmount.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 16,
                        color: currentOrder.meetsMinValue
                            ? _successColor
                            : _dangerColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الحد الأدنى للقيمة: ${currentOrder.minOrderValue.toStringAsFixed(2)} ج.م',
                        style: TextStyle(
                          fontSize: 12,
                          color: currentOrder.meetsMinValue
                              ? _successColor
                              : _dangerColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 16,
                        color: currentOrder.meetsMinItems
                            ? _successColor
                            : _dangerColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'عدد الأصناف: ${currentOrder.itemsCount} من ${currentOrder.minItemsCount} كحد أدنى',
                        style: TextStyle(
                          fontSize: 12,
                          color: currentOrder.meetsMinItems
                              ? _successColor
                              : _dangerColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        meetsAll
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: meetsAll ? _successColor : _warningColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        meetsAll
                            ? '✅ الطلب مستوفي جميع الشروط ويمكن إرساله.'
                            : '⚠️ الطلب غير مستوفي الشروط حالياً.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: meetsAll ? _successColor : _warningColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // زر استكمال طلب منتجات من المورد من داخل صفحة الطلب
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => ClientAppSupplierScreen(
                          clientId: widget.clientId,
                          supplierId: currentOrder.supplierId,
                          supplierName: currentOrder.supplierName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text(
                    'استكمال طلب منتجات من هذا المورد',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accentColor,
                    side: BorderSide(
                      color: _accentColor.withValues(alpha:0.5),
                      width: 1.1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // قائمة الأصناف
            Expanded(
              child: currentOrder.lines.isEmpty
                  ? const Center(
                child: Text(
                  'لا توجد أصناف حالياً في هذا الطلب',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                itemCount: currentOrder.lines.length,
                itemBuilder: (context, index) {
                  final line = currentOrder.lines[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CartLineItem(
                        line: line,
                        cartManager: _cartManager,
                      ),
                    ),
                  );
                },
              ),
            ),

            // زر إرسال الطلب لهذا المورد
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 20),
                  onPressed: !meetsAll
                      ? null
                      : () {
                    showSubmitOrderDialog(
                      context: context,
                      totalAmount: currentOrder.totalAmount,
                      supplierId: currentOrder.supplierId,
                      supplierName: currentOrder.supplierName,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    meetsAll ? _successColor : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  label: const Text(
                    'إرسال هذا الطلب',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== موديلات مساعدة داخلية ======================

class CartLine {
  final String cartKey;

  final int supplierId;
  final String supplierName;

  final String productCode;
  final String productName;
  final String unitName;

  final ClientAppMainProduct product;

  final int quantity;
  final int offerQty;
  final int baseQty;

  final double basePrice;
  final double? offerPrice;

  final int totalLimit;
  final bool hasOfferLimit;

  final double lineTotal;

  CartLine({
    required this.cartKey,
    required this.supplierId,
    required this.supplierName,
    required this.productCode,
    required this.productName,
    required this.unitName,
    required this.product,
    required this.quantity,
    required this.offerQty,
    required this.baseQty,
    required this.basePrice,
    required this.offerPrice,
    required this.totalLimit,
    required this.hasOfferLimit,
    required this.lineTotal,
  });
}

class SupplierOrderSummary {
  final int supplierId;
  final String supplierName;
  final List<CartLine> lines;

  final double totalAmount;
  final int itemsCount;

  final double minOrderValue;
  final int minItemsCount;

  final bool meetsMinValue;
  final bool meetsMinItems;

  SupplierOrderSummary({
    required this.supplierId,
    required this.supplierName,
    required this.lines,
    required this.totalAmount,
    required this.itemsCount,
    required this.minOrderValue,
    required this.minItemsCount,
    required this.meetsMinValue,
    required this.meetsMinItems,
  });
}

// =============== عنصر واحد في السلة (يستخدم في شاشة التفاصيل) ===============

class CartLineItem extends StatelessWidget {
  final CartLine line;
  final CartManager cartManager;

  const CartLineItem({
    super.key,
    required this.line,
    required this.cartManager,
  });

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSplitQtyRow({
    required String label,
    required int qty,
    required double unitPrice,
    required Color color,
  }) {
    final String priceDisplay = '${unitPrice.toStringAsFixed(2)} ج.م';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == 'عرض'
                  ? Icons.local_offer
                  : Icons.shopping_bag_outlined,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          '$priceDisplay × $qty',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    final int currentQty = line.quantity;

    final bool canIncrease =
    line.totalLimit == 0 ? true : currentQty < line.totalLimit;

    final bool canShowOfferSplit =
        line.offerPrice != null && line.offerQty > 0;
    final bool canShowBaseSplit = line.baseQty > 0;
    final bool showSplitDetails =
        currentQty > 0 && (canShowOfferSplit || canShowBaseSplit);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // صورة المنتج
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: product.imageUrl.isNotEmpty
              ? Image.network(
            product.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
          )
              : const Icon(Icons.image_not_supported),
        ),
        const SizedBox(width: 8),

        // البيانات النصية + كارت التفاصيل
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.productName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      line.unitName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${line.lineTotal.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _successColor,
                    ),
                  ),
                ],
              ),
              if (showSplitDetails)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الكمية المطلوبة في السلة:',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha:0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _accentColor.withValues(alpha:0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (canShowOfferSplit && line.offerPrice != null)
                              _buildSplitQtyRow(
                                label: 'عرض',
                                qty: line.offerQty,
                                unitPrice: line.offerPrice!,
                                color: _dangerColor,
                              ),
                            if (canShowBaseSplit)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: _buildSplitQtyRow(
                                  label: 'عادي',
                                  qty: line.baseQty,
                                  unitPrice: line.basePrice,
                                  color: _successColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // أزرار الكمية
        Column(
          children: [
            Container(
              height: 32,
              width: 110,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  // +
                  InkWell(
                    onTap: !canIncrease
                        ? null
                        : () {
                      final double maxQtyForCart =
                      line.totalLimit == 0
                          ? 1000000
                          : line.totalLimit.toDouble();

                      final int oldQty = currentQty;
                      final success = cartManager.increment(
                        line.supplierId,
                        line.productCode,
                        line.unitName,
                        maxQtyForCart,
                      );

                      if (!success) return;

                      if (line.hasOfferLimit &&
                          line.offerPrice != null &&
                          oldQty < line.offerQty &&
                          oldQty + 1 > line.offerQty) {
                        _showSnack(
                          context,
                          'تم استنفاد كمية العرض. أي كمية إضافية ستكون بالسعر العادي.',
                        );
                      }
                    },
                    child: Container(
                      width: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: canIncrease
                            ? _primaryColor
                            : Colors.grey.shade300,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color: canIncrease
                            ? Colors.black
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),

                  // الكمية
                  Expanded(
                    child: Center(
                      child: Text(
                        currentQty.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // -
                  InkWell(
                    onTap: () {
                      if (currentQty > 0) {
                        cartManager.decrement(
                          line.supplierId,
                          line.productCode,
                          line.unitName,
                        );
                      }
                    },
                    child: Container(
                      width: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: currentQty > 0
                            ? Colors.grey.shade300
                            : Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.remove,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // زر حذف
            IconButton(
              onPressed: () {
                if (currentQty > 0) {
                  for (int i = 0; i < currentQty; i++) {
                    cartManager.decrement(
                      line.supplierId,
                      line.productCode,
                      line.unitName,
                    );
                  }
                }
              },
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: currentQty > 0
                    ? _dangerColor.withValues(alpha:0.8)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
