// lib/screens/client_app_supplier_screen.dart
import 'package:flutter/material.dart';

import '../services/product_repository.dart';
import '../models/client_app_main_product_model.dart';
import '../services/cart_manager.dart';

class ClientAppSupplierScreen extends StatefulWidget {
  final String clientId;
  final int supplierId;
  final String supplierName;
  final String? initialProductCode;

  const ClientAppSupplierScreen({
    super.key,
    required this.clientId,
    required this.supplierId,
    required this.supplierName,
    this.initialProductCode,
  });

  @override
  State<ClientAppSupplierScreen> createState() =>
      _ClientAppSupplierScreenState();
}

class _ClientAppSupplierScreenState extends State<ClientAppSupplierScreen> {
  final ProductRepository _repo = ProductRepository();
  final CartManager _cartManager = CartManager();

  bool _isLoading = true;
  String? _errorMessage;

  List<ClientAppMainProduct> _allProducts = [];
  List<ClientAppMainProduct> _displayedProducts = [];

  List<String> _mainCategories = ['الكل'];
  List<String> _subCategories = ['الكل'];
  List<String> _brands = ['الكل'];

  String _selectedMainCat = 'الكل';
  String _selectedSubCat = 'الكل';
  String _selectedBrand = 'الكل';

  // المتغيرات الخاصة بالتغطية
  double _minOrderValue = 0.0;
  int _minUniqueItems = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _cartManager.addListener(_updateCartSummary);
  }

  @override
  void dispose() {
    _cartManager.removeListener(_updateCartSummary);
    super.dispose();
  }

  void _updateCartSummary() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final productsFuture = _repo.fetchSupplierProductsForClient(
        clientId: widget.clientId,
        supplierId: widget.supplierId,
      );

      final coverageFuture = _repo.fetchSupplierCoverageForClient(
        clientId: widget.clientId,
        supplierId: widget.supplierId,
      );

      final products = await productsFuture;
      final coverage = await coverageFuture;

      final mainCats = <String>{'الكل'};
      final subCats = <String>{'الكل'}; // حالياً لا نفرّق رئيسي/فرعي في الـ VIEW
      final brands = <String>{'الكل'};

      for (var p in products) {
        if (p.categoryNameAr != null) mainCats.add(p.categoryNameAr!);
        if (p.brandNameAr != null) brands.add(p.brandNameAr!);
      }

      setState(() {
        _allProducts = products;
        _displayedProducts = products;
        _mainCategories = mainCats.toList();
        _subCategories = subCats.toList();
        _brands = brands.toList();

        if (coverage != null) {
          _minOrderValue = coverage.minOrderValue;
          _minUniqueItems = coverage.minItemsCount;
        } else {
          _minOrderValue = 0.0;
          _minUniqueItems = 0;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _displayedProducts = _allProducts.where((p) {
        final catName = p.categoryNameAr ?? 'أخرى';
        final brandName = p.brandNameAr ?? 'غير محدد';

        final matchMain =
            _selectedMainCat == 'الكل' || catName == _selectedMainCat;
        final matchSub = _selectedSubCat == 'الكل'; // لا يوجد Sub حقيقي الآن
        final matchBrand =
            _selectedBrand == 'الكل' || brandName == _selectedBrand;
        return matchMain && matchSub && matchBrand;
      }).toList();
    });
  }

  void _showLimitWarning(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.orange[800],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Map<String, dynamic> _getCartSummary() {
    final cartItems = _cartManager.items.keys
        .where((key) => key.startsWith('${widget.supplierId}_'))
        .toList();

    double totalValue = 0.0;
    final Set<String> uniqueProductCodes = {};

    for (var key in cartItems) {
      final parts = key.split('_');
      if (parts.length < 3) continue;

      final String productCode = parts[1];
      final String unitName = parts.sublist(2).join('_');
      final int quantity = _cartManager.items[key] ?? 0;

      if (quantity <= 0) continue;

      uniqueProductCodes.add(productCode);

      // ابحث عن الصف المناسب (منتج + وحدة) من نفس المورد
      ClientAppMainProduct? product;
      for (final p in _allProducts) {
        if (p.productCode == productCode &&
            p.unitNameAr == unitName &&
            p.supplierId == widget.supplierId) {
          product = p;
          break;
        }
      }
      if (product == null) continue;

      final bool hasOffer =
          product.isOfferAvailable && product.finalOfferPriceAmount != null;

      final double basePrice = product.finalBasePriceAmount;
      final double offerPrice =
      hasOffer ? product.finalOfferPriceAmount! : basePrice;

      final int offerLimit = hasOffer ? (product.offerMaxQty ?? 0) : 0;

      if (hasOffer && offerLimit > 0 && quantity > offerLimit) {
        final int offerQty = offerLimit;
        final int baseQty = quantity - offerQty;
        totalValue += offerQty * offerPrice + baseQty * basePrice;
      } else if (hasOffer) {
        totalValue += quantity * offerPrice;
      } else {
        totalValue += quantity * basePrice;
      }
    }

    final uniqueItemsCount = uniqueProductCodes.length;

    return {
      'totalValue': totalValue,
      'uniqueItemsCount': uniqueItemsCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildCompactStickyHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _displayedProducts.isEmpty
                    ? const Center(child: Text('لا توجد منتجات مطابقة'))
                    : _buildProductsGrid(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildCartSummaryFooter(),
      ),
    );
  }

  // ===================== الهيدر والفلاتر =====================
  Widget _buildCompactStickyHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط العنوان (Top Bar)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.store_mall_directory,
                    size: 20, color: Colors.black87),
                const SizedBox(width: 6),
                Text(
                  widget.supplierName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 1) Main categories
          if (_mainCategories.length > 1)
            SizedBox(
              height: 34,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _mainCategories.length,
                separatorBuilder: (c, i) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = _mainCategories[index];
                  return _buildCompactChip(
                    label: cat,
                    isSelected: _selectedMainCat == cat,
                    activeColor: const Color(0xFF2196F3),
                    onTap: () {
                      setState(() {
                        _selectedMainCat = cat;
                        _selectedBrand = 'الكل';
                        _applyFilters();
                      });
                    },
                  );
                },
              ),
            ),

          if (_mainCategories.length > 1 && _subCategories.length > 1)
            const SizedBox(height: 4),

          // 2) Sub categories (حاليًا فقط "الكل")
          if (_subCategories.length > 1)
            SizedBox(
              height: 30,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _subCategories.length,
                separatorBuilder: (c, i) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = _subCategories[index];
                  return _buildCompactChip(
                    label: cat,
                    isSelected: _selectedSubCat == cat,
                    activeColor: const Color(0xFF4CAF50),
                    isSmall: true,
                    onTap: () {
                      setState(() {
                        _selectedSubCat = cat;
                        _selectedBrand = 'الكل';
                        _applyFilters();
                      });
                    },
                  );
                },
              ),
            ),

          if (_subCategories.length > 1 && _brands.length > 1)
            const SizedBox(height: 4),

          // 3) Brands
          if (_brands.length > 1)
            SizedBox(
              height: 30,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _brands.length,
                separatorBuilder: (c, i) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final brand = _brands[index];
                  return _buildCompactChip(
                    label: brand,
                    isSelected: _selectedBrand == brand,
                    activeColor: const Color(0xFFFF9800),
                    isOutline: true,
                    isSmall: true,
                    onTap: () {
                      setState(() {
                        _selectedBrand = brand;
                        _selectedMainCat = 'الكل';
                        _selectedSubCat = 'الكل';
                        _applyFilters();
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ===================== شبكة المنتجات =====================

  Widget _buildProductsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _displayedProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.53,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final product = _displayedProducts[index];

        final String unitName = product.unitNameAr;
        final String productName = product.productNameAr;

        final bool hasOffer =
            product.isOfferAvailable && product.finalOfferPriceAmount != null;

        final double baseUnitPrice = product.finalBasePriceAmount;
        final double? offerUnitPrice =
        hasOffer ? product.finalOfferPriceAmount : null;

        double displayPrice = baseUnitPrice;
        double? normalPrice;

        if (hasOffer && offerUnitPrice != null && offerUnitPrice < baseUnitPrice) {
          displayPrice = offerUnitPrice;
          normalPrice = baseUnitPrice;
        }

        int currentQty = _cartManager.getQuantity(
          widget.supplierId,
          product.productCode,
          unitName,
        );

        final double offerLimit =
        hasOffer ? (product.offerMaxQty?.toDouble() ?? 0) : 0.0;
        final double baseLimit = product.baseMaxQty?.toDouble() ?? 0.0;
        final double totalLimit = (offerLimit > 0 ? offerLimit : 0) +
            (baseLimit > 0 ? baseLimit : 0);

        final bool hasOfferLimit = hasOffer && offerLimit > 0;
        bool canIncrease = true;
        if (totalLimit > 0) {
          canIncrease = currentQty < totalLimit;
        }

        int offerQty = 0;
        int baseQty = 0;
        if (hasOfferLimit && currentQty > 0) {
          final limitInt = offerLimit.toInt();
          if (currentQty <= limitInt) {
            offerQty = currentQty;
            baseQty = 0;
          } else {
            offerQty = limitInt;
            baseQty = currentQty - limitInt;
          }
        } else {
          baseQty = currentQty;
        }

        final bool showSplitDetails = hasOfferLimit && baseQty > 0;
        final bool canShowOfferSplit =
            hasOfferLimit && offerUnitPrice != null && offerQty > 0;
        final bool canShowBaseSplit = baseUnitPrice > 0 && baseQty > 0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج من Supabase باستخدام imageUrl من الموديل
              Expanded(
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFAFAFA),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // السعر
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              displayPrice.toStringAsFixed(2),
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              ' ج.م',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (normalPrice != null)
                              Text(
                                'عرض',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                          ],
                        ),
                        if (normalPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Text(
                                  'بدلاً من',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  normalPrice.toStringAsFixed(2),
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.red,
                                    decorationThickness: 2.0,
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // وحدة المنتج (بدون وصف حالياً)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            unitName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // الكارت المقسوم (عرض / عادي)
                    if (currentQty > 0 && showSplitDetails)
                      Column(
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
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (canShowOfferSplit)
                                  _buildSplitQtyRow(
                                    label: 'عرض',
                                    qty: offerQty,
                                    unitPrice: offerUnitPrice,
                                    color: Colors.red.shade700,
                                  ),
                                if (canShowBaseSplit)
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(top: 4.0),
                                    child: _buildSplitQtyRow(
                                      label: 'عادي',
                                      qty: baseQty,
                                      unitPrice: baseUnitPrice,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 10),

                    // أزرار الكمية
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border:
                            Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: !canIncrease
                                    ? null
                                    : () {
                                  final int oldQty = currentQty;
                                  final int newQty = currentQty + 1;

                                  if (totalLimit > 0 &&
                                      newQty > totalLimit) {
                                    _showLimitWarning(
                                      'وصلت للحد الأقصى للطلب: ${totalLimit.toInt()} $unitName',
                                      isError: true,
                                    );
                                    return;
                                  }

                                  final bool crossedOfferLimit =
                                      hasOfferLimit &&
                                          offerLimit > 0 &&
                                          oldQty < offerLimit &&
                                          newQty > offerLimit;

                                  setState(() {
                                    final double maxQtyForCart =
                                    totalLimit > 0
                                        ? totalLimit
                                        : 1000000.0;

                                    final success =
                                    _cartManager.increment(
                                      widget.supplierId,
                                      product.productCode,
                                      unitName,
                                      maxQtyForCart,
                                    );

                                    if (success &&
                                        crossedOfferLimit) {
                                      _showLimitWarning(
                                        'تم استخدام الحد الأقصى للعرض (${offerLimit.toInt()} $unitName). أي كمية إضافية ستكون بالسعر العادي.',
                                      );
                                    }
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: canIncrease
                                        ? const Color(0xFFFFD700)
                                        : Colors.grey[300],
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
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    currentQty.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (currentQty > 0) {
                                    setState(() {
                                      _cartManager.decrement(
                                        widget.supplierId,
                                        product.productCode,
                                        unitName,
                                      );
                                    });
                                  }
                                },
                                child: Container(
                                  width: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: currentQty > 0
                                        ? Colors.grey[300]
                                        : Colors.grey[200],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child:
                                  const Icon(Icons.remove, size: 18),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (currentQty > 0) {
                                    setState(() {
                                      for (int i = 0;
                                      i < currentQty;
                                      i++) {
                                        _cartManager.decrement(
                                          widget.supplierId,
                                          product.productCode,
                                          unitName,
                                        );
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: currentQty > 0
                                        ? Colors.red[400]
                                        : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (totalLimit > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            hasOfferLimit
                                ? 'حد العرض: ${offerLimit.toInt()} $unitName، والحد الكلي: ${totalLimit.toInt()} $unitName.'
                                : 'الحد الأقصى للطلب: ${totalLimit.toInt()} $unitName.',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== فوتر ملخص السلة =====================

  Widget _buildCartSummaryFooter() {
    final summary = _getCartSummary();
    final totalValue = summary['totalValue'] as double;
    final uniqueItemsCount = summary['uniqueItemsCount'] as int;

    final isValueMet = totalValue >= _minOrderValue && _minOrderValue > 0;
    final isItemsMet =
    _minUniqueItems > 0 ? uniqueItemsCount >= _minUniqueItems : true;
    final isOrderReady =
        isValueMet && isItemsMet && totalValue > 0;

    final progressValue = _minOrderValue > 0
        ? totalValue.clamp(0.0, _minOrderValue) / _minOrderValue
        : 1.0;

    final progressBarColor =
    isValueMet ? Colors.green.shade700 : const Color(0xFFFFD700);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إجمالي الطلب:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${totalValue.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color:
                      isOrderReady ? Colors.green.shade800 : Colors.black,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الحد الأدنى للقيمة: ${_minOrderValue.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isValueMet
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        size: 14,
                        color:
                        isValueMet ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isValueMet
                            ? 'تم استيفاء الحد الأدنى للقيمة'
                            : 'متبقي: ${(_minOrderValue - totalValue).clamp(0, double.infinity).toStringAsFixed(2)} ج.م',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isValueMet
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isItemsMet ? Icons.check_circle : Icons.info_outline,
                    size: 18,
                    color:
                    isItemsMet ? Colors.green : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _minUniqueItems > 0
                        ? (isItemsMet
                        ? 'الأصناف ($uniqueItemsCount/$_minUniqueItems) مستوفاة'
                        : 'يجب طلب $_minUniqueItems أصناف مختلفة (حالياً: $uniqueItemsCount)')
                        : 'عدد الأصناف المختلفة: $uniqueItemsCount',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isItemsMet
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: isOrderReady
                    ? () {
                  _showLimitWarning(
                    'الطلب جاهز للإرسال! (الإجمالي: ${totalValue.toStringAsFixed(2)} ج.م)',
                    isError: false,
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isOrderReady ? const Color(0xFF4CAF50) : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'إرسال الطلب',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== Widgets مساعدة =====================

  Widget _buildSplitQtyRow({
    required String label,
    required int qty,
    required Color color,
    required double unitPrice,
  }) {
    final String priceDisplay = '${unitPrice.toStringAsFixed(2)} ج.م';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == 'عرض' ? Icons.local_offer : Icons.shopping_bag_outlined,
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

  Widget _buildCompactChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    bool isSmall = false,
    bool isOutline = false,
  }) {
    Color borderColor = Colors.grey.shade400;
    if (isSelected) {
      borderColor = activeColor;
    } else if (label == 'الكل') {
      borderColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 14,
          vertical: isSmall ? 4 : 6,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isOutline ? Colors.transparent : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: isSmall ? 11.5 : 12.5,
          ),
        ),
      ),
    );
  }
}
