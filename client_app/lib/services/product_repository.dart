// lib/services/product_repository.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// المصدر الجديد الأساسي من الـ VIEW
import '../models/client_app_main_product_model.dart';

import '../models/client_home_top_product_model.dart';
import '../models/supplier_coverage_model.dart';
// موديلات شاشة البحث (SearchProductResult / SearchSupplierPrice)
import '../models/search_product_result_model.dart';

class ProductRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // =========================================================
// (1) جلب المنتجات للمورد داخل صفحة العميل (من الـ VIEW الجديد)
// =========================================================
  Future<List<ClientAppMainProduct>> fetchSupplierProductsForClient({
    required String clientId,
    required int supplierId,
  }) async {
    final data = await _client
        .from('client_app_main_products_view') // 👈 اسم الـ VIEW الجديد
        .select('*')
        .eq('client_id', clientId)
        .eq('supplier_id', supplierId)
        .eq('is_available', true); // اختياري: نجيب المتاح بس

    final list = data as List<dynamic>;

    return list
        .map((row) => ClientAppMainProduct.fromJson(row as Map<String, dynamic>))
        .toList();
  }


  // =========================================================
  // (2) جلب إعدادات التغطية (min_order_value, min_items_count, markup_percentage)
  //    الآن نعتمد على نفس الـ VIEW بدل الجداول الخام
  // =========================================================
  Future<SupplierCoverage?> fetchSupplierCoverageForClient({
    required String clientId,
    required int supplierId,
  }) async {
    final data = await _client
        .from('client_app_main_products_view')
        .select('min_items_count, min_order_value, markup_percentage')
        .eq('client_id', clientId)
        .eq('supplier_id', supplierId)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;

    return SupplierCoverage.fromJson(data);
  }

  // =========================================================
  // (3) جلب المنتجات للصفحة الرئيسية (كل الموردين المتاحين للعميل)
  //    المصدر: client_app_main_products_view
  // =========================================================
  Future<List<ClientAppMainProduct>> fetchHomeProducts(String clientId) async {
    final List data = await _client
        .from('client_app_main_products_view')
        .select()
        .eq('client_id', clientId);

    return data
        .map((row) =>
        ClientAppMainProduct.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // =========================================================
  // (4) جلب الأكثر مبيعاً (RPC)
  // =========================================================
  Future<List<ClientHomeTopProductModel>> fetchTopSellingForClient(
      String clientId) async {
    try {
      final result = await _client.rpc(
        'get_top_selling_products_for_client',
        params: {'client_id_param': clientId},
      );
      if (result == null) return [];

      return (result as List<dynamic>)
          .map((row) =>
          ClientHomeTopProductModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching top selling: $e');
      return [];
    }
  }

  // =========================================================
  // (5) جلب الأكثر شراءً (RPC)
  // =========================================================
  Future<List<ClientHomeTopProductModel>> fetchTopPurchasedForClient(
      String clientId) async {
    try {
      final result = await _client.rpc(
        'get_top_client_purchased_products',
        params: {'client_id_param': clientId},
      );
      if (result == null) return [];

      return (result as List<dynamic>)
          .map((row) =>
          ClientHomeTopProductModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching top purchased: $e');
      return [];
    }
  }

  // =========================================================
  // (6) بحث المنتجات للعميل (ترجع SearchProductResult)
  //    نعتمد مباشرة على client_app_main_products_view
  //    ونحوّلها لمجموعات (منتج + وحدة) مع قائمة الموردين
  // =========================================================
  Future<List<SearchProductResult>> searchProductsForClient({
    required String clientId,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    // نستخدم ilike في Postgres + grouping في Dart
    final List data = await _client
        .from('client_app_main_products_view')
        .select()
        .eq('client_id', clientId)
        .ilike('product_name_ar', '%$trimmed%');

    final items = data
        .map((row) =>
        ClientAppMainProduct.fromJson(row as Map<String, dynamic>))
        .toList();

    // نجمع حسب (product_code + unit_id)
    final Map<String, List<ClientAppMainProduct>> grouped = {};

    for (final item in items) {
      final key = '${item.productCode}-${item.unitId}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final List<SearchProductResult> results = [];

    for (final group in grouped.values) {
      if (group.isEmpty) continue;
      final first = group.first;

      // قائمة الموردين لهذه (المنتج + الوحدة)
      final supplierPrices = group.map((item) {
        final bool isOffer = item.isOfferAvailable;
        final double price = (isOffer && item.finalOfferPriceAmount != null)
            ? item.finalOfferPriceAmount!
            : item.finalBasePriceAmount;

        final double? originalPrice =
        (isOffer && item.finalOfferPriceAmount != null)
            ? item.finalBasePriceAmount
            : null;

        return SearchSupplierPrice(
          supplierId: item.supplierId,
          supplierName: item.supplierNameAr, // اسم المورد من الـ VIEW
          price: price,
          originalPrice: originalPrice,
          isOffer: isOffer,
          unitName: item.unitNameAr, // نستخدم الاسم العربي للوحدة
          productCode: item.productCode,
          unitDescription: null, // مفيش وصف وحدة في الـ VIEW حالياً
        );
      }).toList();

      // ترتيب الموردين حسب أقل سعر
      supplierPrices.sort((a, b) => a.price.compareTo(b.price));

      results.add(
        SearchProductResult(
          productCode: first.productCode,
          productNameAr: first.productNameAr,
          unitName: first.unitNameAr,
          unitDescription: null,
          supplierPrices: supplierPrices,
        ),
      );
    }

    return results;
  }
}
