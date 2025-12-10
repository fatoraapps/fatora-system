// lib/models/supplier_coverage_model.dart
// ======================================
// Model: SupplierCoverage
// يمثل إعدادات تغطية المورد في منطقة معينة للعميل:
// - min_order_value     : الحد الأدنى لقيمة الطلب
// - min_items_count     : الحد الأدنى لعدد الأصناف المختلفة
// - markup_percentage   : نسبة الرفع على الأسعار (مثلاً 5 = 5%)

class SupplierCoverage {
  final double minOrderValue;
  final int minItemsCount;
  final double markupPercentage; // كنسبة مئوية (مثلاً 10 = 10%)

  SupplierCoverage({
    required this.minOrderValue,
    required this.minItemsCount,
    required this.markupPercentage,
  });

  factory SupplierCoverage.fromJson(Map<String, dynamic> json) {
    return SupplierCoverage(
      minOrderValue: (json['min_order_value'] as num?)?.toDouble() ?? 0.0,
      minItemsCount: (json['min_items_count'] as int?) ?? 0,
      markupPercentage: (json['markup_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
