// lib/models/search_product_result_model.dart
// ============================================
// موديلات شاشة البحث:
// - SearchSupplierPrice  : صف سعر مورد لوحدة معينة
// - SearchProductResult  : نتيجة بحث لمنتج + وحدة مع قائمة الموردين
// ============================================

import '../config.dart';

/// سعر مورد واحد لوحدة منتج معينة
class SearchSupplierPrice {
  final int supplierId;
  final String supplierName;
  final double price;
  final double? originalPrice; // لو فيه عرض: السعر قبل الخصم
  final bool isOffer;
  final String unitName;
  final String? unitDescription;
  final String productCode;

  SearchSupplierPrice({
    required this.supplierId,
    required this.supplierName,
    required this.price,
    this.originalPrice,
    required this.isOffer,
    required this.unitName,
    required this.productCode,
    this.unitDescription,
  });
}

/// نتيجة بحث لمنتج (اسم واحد + وحدة واحدة) مع قائمة الموردين
class SearchProductResult {
  final String productCode;
  final String productNameAr;
  final String unitName;
  final String? unitDescription;
  final List<SearchSupplierPrice> supplierPrices;

  SearchProductResult({
    required this.productCode,
    required this.productNameAr,
    required this.unitName,
    this.unitDescription,
    required this.supplierPrices,
  });

  /// رابط صورة المنتج من Supabase Storage
  /// صورك كلها PNG باسم كود الصنف → 10023001300007.png مثلاً
  String get imageUrl =>
      '${AppConfig.kStorageBaseUrl}$productCode.png';
}
