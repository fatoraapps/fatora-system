// lib/screens/client_app_search_screen.dart
// ===========================================================
// Code: client_app_search_screen
// شاشة بحث المنتجات للعميل
// تصميم محسّن:
// - كارت لكل منتج
// - صورة على اليمين
// - اسم كبير بجوار الصورة
// - لكل وحدة سطر "أقل سعر" يظهر فيه: شرح الوحدة + اسم مورد أقل سعر + السعر
//   مع سهم يفتح كارت مقارنة الموردين
// - بحث Fuzzy مع تحسينات للأخطاء الإملائية الشائعة (جهينه/جهينة – خاميرة/خميرة – كبتشينو/كابتشينو)
// ===========================================================

import 'dart:math';
import 'package:flutter/material.dart';

import '../models/search_product_result_model.dart';
import '../services/product_repository.dart';
import '../services/cart_manager.dart';
import 'client_app_supplier_screen.dart';

// ألوان ثيم بسيطة مريحة للعين
const Color _pageBgColor = Color(0xFFF4F6F8);
const Color _headerStartColor = Color(0xFFFFF8E1);
const Color _headerEndColor = Color(0xFFFFECB3);
const Color _primaryColor = Color(0xFFFFD54F);
const Color _accentColor = Color(0xFF1565C0);
const Color _priceColor = Color(0xFF2E7D32);

class ClientAppSearchScreen extends StatefulWidget {
  final String clientId;

  const ClientAppSearchScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientAppSearchScreen> createState() => _ClientAppSearchScreenState();
}

class _ClientAppSearchScreenState extends State<ClientAppSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductRepository _repo = ProductRepository();
  final CartManager _cartManager = CartManager();

  bool _isSearching = false;
  String? _errorMessage;
  List<SearchProductResult> _results = [];

  /// حالة فتح/إغلاق وحدات المنتج
  /// المفتاح: "productCode|unitName"
  final Map<String, bool> _expandedUnits = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ======================= تطبيع الحروف العربية =======================

  String _normalizeArabic(String input) {
    var s = input.trim().toLowerCase();
    const replacements = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ى': 'ي',
      'ئ': 'ي',
      'ؤ': 'و',
      'ة': 'ه',
      'ٱ': 'ا',
      'ـ': '',
    };
    replacements.forEach((from, to) {
      s = s.replaceAll(from, to);
    });
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  /// نحاول نحول "جهينه" → "جهينة" إلخ
  String _fixTaMarbutaVariants(String input) {
    final words = input.split(' ');
    final fixed = <String>[];
    for (var w in words) {
      if (w.isEmpty) {
        fixed.add(w);
        continue;
      }
      if (w.endsWith('ه')) {
        w = w.substring(0, w.length - 1) + 'ة';
      }
      fixed.add(w);
    }
    return fixed.join(' ');
  }

  /// إزالة الألف/الواو في وسط الكلمة (ينفع لـ "خاميرة" → "خميرة")
  String _stripMiddleWeakLetters(String input) {
    const weakLetters = ['ا', 'و'];
    final words = input.split(' ');
    final result = <String>[];

    for (var w in words) {
      if (w.length <= 3) {
        result.add(w);
        continue;
      }
      final buffer = StringBuffer();
      for (int i = 0; i < w.length; i++) {
        final ch = w[i];
        final isEdge = (i == 0 || i == w.length - 1);
        if (!isEdge && weakLetters.contains(ch)) {
          // نشيل الألف/الواو من جوة الكلمة
          continue;
        }
        buffer.write(ch);
      }
      result.add(buffer.toString());
    }

    return result.join(' ');
  }

  /// إضافة ألف بعد أول حرف (ينفع لـ "كبتشينو" → "كابتشينو")
  String _addAlefAfterFirstLetter(String input) {
    final words = input.split(' ');
    final result = <String>[];

    for (var w in words) {
      if (w.length < 3) {
        result.add(w);
        continue;
      }
      if (w[1] == 'ا') {
        result.add(w);
        continue;
      }
      result.add(w[0] + 'ا' + w.substring(1));
    }

    return result.join(' ');
  }

  // ======================= Levenshtein Distance =======================

  int _getLevenshteinDistance(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;

    if (m == 0) return n;
    if (n == 0) return m;

    final dp = List.generate(
      m + 1,
          (_) => List<int>.filled(n + 1, 0),
    );

    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost =
        s1.codeUnitAt(i - 1) == s2.codeUnitAt(j - 1) ? 0 : 1;

        dp[i][j] = min(
          min(
            dp[i - 1][j] + 1, // حذف
            dp[i][j - 1] + 1, // إضافة
          ),
          dp[i - 1][j - 1] + cost, // استبدال
        );
      }
    }

    return dp[m][n];
  }

  // ======================= حساب درجة التطابق =======================

  double _calculateMatchScore(String query, String target) {
    final nq = _normalizeArabic(query);
    final nt = _normalizeArabic(target);

    if (nq.isEmpty && nt.isEmpty) return 1.0;
    if (nq.isEmpty || nt.isEmpty) return 0.0;

    // تطابق كامل بعد التطبيع
    if (nq == nt) return 1.0;

    // أحدهما يحتوي الآخر → Boost عالي
    if (nt.contains(nq)) return 0.95;
    if (nq.contains(nt)) return 0.95;

    final distance = _getLevenshteinDistance(nq, nt);
    final maxLength = max(nq.length, nt.length);

    final similarity = 1.0 - (distance / maxLength);

    return similarity.clamp(0.0, 1.0);
  }

  // ======================= استعلام ذكي من السيرفر =======================

  Future<List<SearchProductResult>> _smartSearchOnServer(
      String query) async {
    final all = <SearchProductResult>[];
    final seen = <String>{};

    Future<void> addResults(String q) async {
      final trimmed = q.trim();
      if (trimmed.isEmpty) return;

      final res = await _repo.searchProductsForClient(
        clientId: widget.clientId,
        query: trimmed,
      );

      for (final r in res) {
        final key = '${r.productCode}|${r.unitName}';
        if (seen.add(key)) {
          all.add(r);
        }
      }
    }

    // 1) الكلمة زي ما العميل كتبها
    await addResults(query);

    // 2) جرّب نصحّح الهاء → تاء مربوطة (جهينه → جهينة)
    if (all.isEmpty) {
      final fixedTa = _fixTaMarbutaVariants(query);
      if (fixedTa != query) {
        await addResults(fixedTa);
      }
    }

    // 3) جرّب إزالة الألف/الواو من وسط الكلمة (خاميرة → خميرة)
    if (all.isEmpty) {
      final stripped = _stripMiddleWeakLetters(query);
      if (stripped != query) {
        await addResults(stripped);
      }
    }

    // 4) جرّب نضيف ألف بعد أول حرف (كبتشينو → كابتشينو)
    if (all.isEmpty) {
      final withAlef = _addAlefAfterFirstLetter(query);
      if (withAlef != query) {
        await addResults(withAlef);
      }
    }

    return all;
  }

  // ======================= تنفيذ البحث (Fuzzy) =======================

  Future<void> _performSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _errorMessage = null;
        _expandedUnits.clear();
        _isSearching = false;
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
        _errorMessage = null;
      });

      // 1) نجيب مرشحين من السيرفر بعدة محاولات ذكية
      final resultsFromApi = await _smartSearchOnServer(query);

      final normalizedQuery = _normalizeArabic(query);

      // 2) فلترة وترتيب حسب درجة التطابق
      final filtered = resultsFromApi.where((r) {
        final score =
        _calculateMatchScore(normalizedQuery, r.productNameAr);
        // خفّضناها لـ 0.5 عشان يتحمّل أخطاء أكتر شوية
        return score >= 0.5;
      }).toList();

      filtered.sort((a, b) {
        final sa =
        _calculateMatchScore(normalizedQuery, a.productNameAr);
        final sb =
        _calculateMatchScore(normalizedQuery, b.productNameAr);
        return sb.compareTo(sa); // الأعلى أولاً
      });

      if (!mounted) return;

      setState(() {
        _results = filtered;
        _isSearching = false;
        _expandedUnits.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _errorMessage = 'حدث خطأ أثناء البحث: $e';
      });
    }
  }

  // نجمع النتائج حسب المنتج (productCode)
  Map<String, List<SearchProductResult>> _groupResultsByProduct() {
    final Map<String, List<SearchProductResult>> grouped = {};
    for (var result in _results) {
      grouped.putIfAbsent(result.productCode, () => []).add(result);
    }
    return grouped;
  }

  void _onTapSupplierPrice(SearchSupplierPrice sp) {
    // 1) +1 في السلة
    _cartManager.increment(
      sp.supplierId,
      sp.productCode,
      sp.unitName,
      1000000,
    );

    // 2) فتح صفحة المورد على نفس المنتج
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ClientAppSupplierScreen(
          clientId: widget.clientId,
          supplierId: sp.supplierId,
          supplierName: sp.supplierName,
          initialProductCode: sp.productCode,
        ),
      ),
    );

  }

  // ======================= الـ UI الرئيسي =======================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBgColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchHeader(context),
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _buildBodyContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(
        child: Text(
          'لا توجد نتائج مطابقة لطلبك.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_results.isEmpty && _searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'ابحث عن المنتج باسم الصنف أو العلامة التجارية...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return _buildResultsList();
  }

  // ======================= الهيدر + صندوق البحث =======================

  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_headerStartColor, _headerEndColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط علوي
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'بحث عن المنتجات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 40), // توازن مع زر الرجوع
            ],
          ),
          const SizedBox(height: 8),

          // صندوق البحث
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'ابحث عن اسم المنتج أو البراند...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.grey.shade600,
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================= قائمة النتائج =======================

  Widget _buildResultsList() {
    final grouped = _groupResultsByProduct();
    final productCodes = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
      physics: const BouncingScrollPhysics(),
      itemCount: productCodes.length,
      itemBuilder: (context, index) {
        final productCode = productCodes[index];
        final units = grouped[productCode]!;
        final first = units.first;

        // ---------- نجهز قائمة وحدات المنتج ----------
        List<Widget> unitWidgets = [];

        for (final unitResult in units) {
          final key = '${unitResult.productCode}|${unitResult.unitName}';
          final bool isExpanded = _expandedUnits[key] ?? false;

          final List<SearchSupplierPrice> sortedPrices =
          [...unitResult.supplierPrices]
            ..sort((a, b) => a.price.compareTo(b.price));
          final lowestForUnit = sortedPrices.first;

          final String unitDesc =
              unitResult.unitDescription?.trim() ?? '';

          // سطر الوحدة (أقل سعر + مورد + وصف بسيط)
          unitWidgets.add(
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _expandedUnits[key] = !isExpanded;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _accentColor.withOpacity(0.15),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    // اسم الوحدة + الوصف + اسم مورد أقل سعر
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unitResult.unitName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _accentColor.withOpacity(0.9),
                            ),
                          ),
                          if (unitDesc.isNotEmpty)
                            Text(
                              unitDesc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            lowestForUnit.supplierName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // أقل سعر للوحدة
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'أقل سعر',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lowestForUnit.price.toStringAsFixed(2)} ج',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _priceColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );

          // قائمة الموردين عند فتح الوحدة
          if (isExpanded) {
            unitWidgets.add(
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 0.7,
                  ),
                ),
                child: Column(
                  children: sortedPrices.map((sp) {
                    final bool hasOffer = sp.isOffer &&
                        sp.originalPrice != null &&
                        sp.originalPrice! > sp.price;

                    return InkWell(
                      onTap: () => _onTapSupplierPrice(sp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // السعر
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      sp.price.toStringAsFixed(2),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: hasOffer
                                            ? Colors.red.shade700
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      'ج',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasOffer)
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(top: 3),
                                    child: Text(
                                      'بدلاً من ${sp.originalPrice!.toStringAsFixed(2)} ج',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red.shade600,
                                        decoration:
                                        TextDecoration.lineThrough,
                                        decorationThickness: 1.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(width: 14),

                            // اسم المورد
                            Expanded(
                              child: Text(
                                sp.supplierName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),

                            const Icon(
                              Icons.chevron_left,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }
        }

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // الصورة
                Container(
                  width: 95,
                  height: 95,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: first.imageUrl.isNotEmpty
                      ? Image.network(
                    first.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image),
                  )
                      : const Icon(Icons.image_not_supported),
                ),
                const SizedBox(width: 10),
                // باقي الكارت: اسم الصنف + كروت الوحدات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم الصنف
                      Text(
                        first.productNameAr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // كروت الوحدات
                      ...unitWidgets,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
