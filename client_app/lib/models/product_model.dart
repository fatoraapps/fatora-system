// lib/models/product_model.dart

import '../config.dart';

class PriceDetail {
  final int supplierId;
  final String supplier;
  final double price;          // سعر البيع الحالي
  final double? originalPrice; // السعر قبل الخصم
  final bool isOffer;

  // الكميات القصوى من قاعدة البيانات
  final double baseMaxQty;
  final double offerMaxQty;

  PriceDetail({
    required this.supplierId,
    required this.supplier,
    required this.price,
    this.originalPrice,
    required this.isOffer,
    required this.baseMaxQty,
    required this.offerMaxQty,
  });

  String get supplierImageUrl =>
      '${AppConfig.kSupplierImagesBaseUrl}$supplierId.png';

  factory PriceDetail.fromJson(Map<String, dynamic> json) {
    return PriceDetail(
      supplierId: json['supplier_id'] as int? ?? 0,
      supplier: json['supplier_name'] as String? ?? '',
      price: (json['price'] as num? ?? 0.0).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      isOffer: json['offer'] as bool? ?? false,
      baseMaxQty: (json['base_max_qty'] as num? ?? 0.0).toDouble(),
      offerMaxQty: (json['offer_max_qty'] as num? ?? 0.0).toDouble(),
    );
  }
}

class UnitModel {
  final String unitName;

  // --- الحقول الجديدة لحساب الوصف ---
  final int unitLevel;
  final double conversionFactor;
  final String? baseUnitNameAr;
  // ----------------------------------

  final double bestPrice;
  final String bestSupplier;
  final List<PriceDetail> prices;

  UnitModel({
    required this.unitName,
    required this.unitLevel,
    required this.conversionFactor,
    this.baseUnitNameAr,
    required this.bestPrice,
    required this.bestSupplier,
    required this.prices,
  });

  /// --- هذا هو الحل السحري ---
  /// يقوم بحساب الوصف بدلاً من انتظاره من قاعدة البيانات
  String get unitDescription {
    // 1. إذا كانت الوحدة هي الأصغر (مستوى 1) أو معامل التحويل 1، لا نحتاج لوصف
    if (unitLevel <= 1 || conversionFactor <= 1) {
      return ''; // نرجع نص فارغ لكي لا يظهر شيء
    }

    // 2. التأكد من وجود اسم للوحدة الأصغر
    final baseName = baseUnitNameAr;
    if (baseName == null || baseName.isEmpty) {
      return '';
    }

    // 3. تنسيق الرقم (لإزالة الكسور الصفرية مثل 12.0 تصبح 12)
    final cf = conversionFactor % 1 == 0
        ? conversionFactor.toInt().toString()
        : conversionFactor.toString();

    // النتيجة: "تحتوي 12 قطعة"
    // ملاحظة: جعلتها مختصرة لأنها ستظهر بجانب اسم الوحدة في الواجهة
    // الشكل النهائي في التطبيق سيكون: كرتونة (12 قطعة)
    return '$cf $baseName';
  }

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> pricesData = json['prices'] as List<dynamic>? ?? [];

    return UnitModel(
      unitName: json['unit_name'] as String? ?? '',

      // قراءة بيانات التحويل من الـ JSON
      // تأكد أن الـ View في قاعدة البيانات يرجع هذه الأعمدة داخل مصفوفة units
      unitLevel: json['unit_level'] as int? ?? 1,
      conversionFactor: (json['conversion_factor'] as num? ?? 1.0).toDouble(),
      baseUnitNameAr: json['base_unit_name_ar'] as String?,

      bestPrice: (json['best_price'] as num? ?? 0.0).toDouble(),
      bestSupplier: json['best_supplier'] as String? ?? 'N/A',
      prices: pricesData
          .map((i) => PriceDetail.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductModel {
  final String name;
  final String nameAr;
  final String productCode;
  final List<UnitModel> units;

  final String? mainCategoryNameAr;
  final String? subCategoryNameAr;
  final String? brandNameAr;

  ProductModel({
    required this.nameAr,
    required this.productCode,
    required this.units,
    this.mainCategoryNameAr,
    this.subCategoryNameAr,
    this.brandNameAr,
  }) : name = nameAr;

  String get imageUrl {
    if (productCode.isEmpty) return '';
    return '${AppConfig.kStorageBaseUrl}$productCode.png';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> unitsData = json['units'] as List<dynamic>? ?? [];

    return ProductModel(
      nameAr: json['product_name_ar'] as String? ?? 'Unknown Product',
      productCode: json['product_code'] as String? ?? '',
      units: unitsData
          .map((i) => UnitModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      mainCategoryNameAr: json['main_category_name_ar'] as String?,
      subCategoryNameAr: json['sub_category_name_ar'] as String?,
      brandNameAr: json['brand_name_ar'] as String?,
    );
  }
}