class ClientHomeTopProductModel {
  final int productId;
  final String productCode;
  final String nameAr;
  final double totalQtyLast30Days;
  final double bestPrice;
  final int bestSupplierId;
  final String bestSupplierName;

  ClientHomeTopProductModel({
    required this.productId,
    required this.productCode,
    required this.nameAr,
    required this.totalQtyLast30Days,
    required this.bestPrice,
    required this.bestSupplierId,
    required this.bestSupplierName,
  });

  String get imageUrl {
    return ''; // سيتم ربطها بالصور لاحقاً
  }

  factory ClientHomeTopProductModel.fromMap(Map<String, dynamic> map) {
    return ClientHomeTopProductModel(
      productId: map['product_id'] as int,
      productCode: (map['product_code'] ?? '') as String,
      nameAr: (map['product_name_ar'] ?? '') as String,
      totalQtyLast30Days:
      (map['total_qty_30d'] as num?)?.toDouble() ?? 0.0,
      bestPrice: (map['best_price'] as num?)?.toDouble() ?? 0.0,
      bestSupplierId: map['best_supplier_id'] as int,
      bestSupplierName: (map['best_supplier_name'] ?? '') as String,
    );
  }
}
