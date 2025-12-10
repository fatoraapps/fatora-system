// lib/models/client_app_main_product_model.dart
// ===========================================================
// Model: ClientAppMainProduct
// يمثل صف واحد من الـ VIEW: client_app_main_products_view
// ===========================================================

import '../config.dart';

class ClientAppMainProduct {
  // ---------- بيانات العميل والمنطقة ----------
  // client_id في الداتا بيز نص (UUID) → String
  final String clientId;
  final int areaId;

  // ---------- إعدادات تغطية المورد ----------
  final int supplierAreaCoverageId;
  final int minItemsCount;
  final double minOrderValue;
  final double markupPercentage;

  // ---------- بيانات المورد ----------
  final int supplierId;
  final String supplierCode;
  final String supplierNameAr;
  final String supplierNameEn;
  final String supplierRating;

  // ---------- بيانات المنتج ----------
  final int productId;
  final String productCode;
  final String productNameAr;
  final String productNameEn;
  final int productStatus;

  // ---------- البراند / صاحب البراند ----------
  final int? brandId;
  final String? brandNameAr;
  final String? brandNameEn;
  final int? brandOwnerId;
  final String? brandOwnerNameAr;
  final String? brandOwnerNameEn;

  // ---------- التصنيف ----------
  final int? categoryId;
  final int? parentCategoryId;
  final int? categoryLevel;
  final String? categoryNameAr;
  final String? categoryNameEn;

  // ---------- وحدة المنتج ----------
  final int productUnitId;
  final int unitLevel;
  final double conversionFactor;
  final bool isSellingUnit;
  final int unitStatus;

  final int unitId;
  final String unitNameAr;
  final String unitNameEn;
  final String unitCode;

  // ---------- سعر المورد الخام ----------
  final int supplierPriceId;
  final bool isAvailable;
  final double basePriceAmount;
  final int? baseMaxQty;
  final bool isOfferAvailable;
  final double? offerPriceAmount;
  final int? offerMaxQty;

  // ---------- سعر البيع بعد إضافة نسبة الرفع ----------
  final double finalBasePriceAmount;
  final double? finalOfferPriceAmount;

  ClientAppMainProduct({
    // العميل والمنطقة
    required this.clientId,
    required this.areaId,

    // تغطية المورد
    required this.supplierAreaCoverageId,
    required this.minItemsCount,
    required this.minOrderValue,
    required this.markupPercentage,

    // المورد
    required this.supplierId,
    required this.supplierCode,
    required this.supplierNameAr,
    required this.supplierNameEn,
    required this.supplierRating,

    // المنتج
    required this.productId,
    required this.productCode,
    required this.productNameAr,
    required this.productNameEn,
    required this.productStatus,

    // البراند / صاحب البراند
    this.brandId,
    this.brandNameAr,
    this.brandNameEn,
    this.brandOwnerId,
    this.brandOwnerNameAr,
    this.brandOwnerNameEn,

    // التصنيف
    this.categoryId,
    this.parentCategoryId,
    this.categoryLevel,
    this.categoryNameAr,
    this.categoryNameEn,

    // وحدة المنتج
    required this.productUnitId,
    required this.unitLevel,
    required this.conversionFactor,
    required this.isSellingUnit,
    required this.unitStatus,
    required this.unitId,
    required this.unitNameAr,
    required this.unitNameEn,
    required this.unitCode,

    // السعر الخام
    required this.supplierPriceId,
    required this.isAvailable,
    required this.basePriceAmount,
    this.baseMaxQty,
    required this.isOfferAvailable,
    this.offerPriceAmount,
    this.offerMaxQty,

    // السعر بعد الرفع
    required this.finalBasePriceAmount,
    this.finalOfferPriceAmount,
  });

  // =============== fromJson ===============

  factory ClientAppMainProduct.fromJson(Map<String, dynamic> json) {
    num _num(dynamic v) => (v ?? 0) as num;

    return ClientAppMainProduct(
      // العميل والمنطقة
      clientId: json['client_id']?.toString() ?? '',
      areaId: json['area_id'] as int,

      // تغطية المورد
      supplierAreaCoverageId: json['supplier_area_coverage_id'] as int,
      minItemsCount: json['min_items_count'] as int,
      minOrderValue: _num(json['min_order_value']).toDouble(),
      markupPercentage: _num(json['markup_percentage']).toDouble(),

      // بيانات المورد
      supplierId: json['supplier_id'] as int,
      supplierCode: json['supplier_code']?.toString() ?? '',
      supplierNameAr: json['supplier_name_ar']?.toString() ?? '',
      supplierNameEn: json['supplier_name_en']?.toString() ?? '',
      supplierRating: json['supplier_rating']?.toString() ?? '0',

      // بيانات المنتج
      productId: json['product_id'] as int,
      productCode: json['product_code']?.toString() ?? '',
      productNameAr: json['product_name_ar']?.toString() ?? '',
      productNameEn: json['product_name_en']?.toString() ?? '',
      productStatus: json['product_status'] as int,

      // البراند / صاحب البراند (اختياري)
      brandId: json['brand_id'] as int?,
      brandNameAr: json['brand_name_ar'] as String?,
      brandNameEn: json['brand_name_en'] as String?,
      brandOwnerId: json['brand_owner_id'] as int?,
      brandOwnerNameAr: json['brand_owner_name_ar'] as String?,
      brandOwnerNameEn: json['brand_owner_name_en'] as String?,

      // التصنيف (اختياري)
      categoryId: json['category_id'] as int?,
      parentCategoryId: json['parent_category_id'] as int?,
      categoryLevel: json['category_level'] as int?,
      categoryNameAr: json['category_name_ar'] as String?,
      categoryNameEn: json['category_name_en'] as String?,

      // وحدة المنتج
      productUnitId: json['product_unit_id'] as int,
      unitLevel: json['unit_level'] as int,
      conversionFactor: _num(json['conversion_factor']).toDouble(),
      isSellingUnit: json['is_selling_unit'] as bool,
      unitStatus: json['unit_status'] as int,
      unitId: json['unit_id'] as int,
      unitNameAr: json['unit_name_ar']?.toString() ?? '',
      unitNameEn: json['unit_name_en']?.toString() ?? '',
      unitCode: json['unit_code']?.toString() ?? '',

      // السعر الخام
      supplierPriceId: json['supplier_price_id'] as int,
      isAvailable: json['is_available'] as bool,
      basePriceAmount: _num(json['base_price_amount']).toDouble(),
      baseMaxQty: json['base_max_qty'] as int?,
      isOfferAvailable: json['is_offer_available'] as bool,
      offerPriceAmount: json['offer_price_amount'] == null
          ? null
          : _num(json['offer_price_amount']).toDouble(),
      offerMaxQty: json['offer_max_qty'] as int?,

      // السعر بعد الرفع
      finalBasePriceAmount:
      _num(json['final_base_price_amount']).toDouble(),
      finalOfferPriceAmount: json['final_offer_price_amount'] == null
          ? null
          : _num(json['final_offer_price_amount']).toDouble(),
    );
  }

  // ===================== روابط الصور من Supabase =====================

  /// رابط صورة المنتج (كلها PNG)
  String get imageUrl =>
      '${AppConfig.kStorageBaseUrl}$productCode.png';

  /// رابط لوجو المورد (PNG برضه)
  String get supplierImageUrl =>
      '${AppConfig.kSupplierImagesBaseUrl}$supplierCode.png';
}
