// lib/screens/client_app_home_screen.dart
// ===========================================================
// Code: client_app_home_screen
// الشاشة الرئيسية لتطبيق العميل (Client App Home)
// - تظهر:
//   1) المنتجات الأكثر مبيعاً في المحافظة
//   2) طلبات العميل المتكررة
//   3) قائمة الموردين المتاحين
// ===========================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'client_app_supplier_screen.dart';
import 'client_app_search_screen.dart';

import '../models/client_app_main_product_model.dart';
import '../models/client_home_top_product_model.dart';
import '../services/product_repository.dart';

class ClientAppHomeScreen extends StatefulWidget {
  final String clientId;

  const ClientAppHomeScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientAppHomeScreen> createState() => _ClientAppHomeScreenState();
}

class _ClientAppHomeScreenState extends State<ClientAppHomeScreen> {
  late final String _clientId;
  late final ProductRepository _productRepository;

  late Future<List<ClientHomeTopProductModel>> _futureTopSelling;
  late Future<List<ClientHomeTopProductModel>> _futureTopPurchased;
  late Future<List<ClientAppMainProduct>> _futureProductsForSuppliers;

  @override
  void initState() {
    super.initState();
    _productRepository = ProductRepository();
    _clientId = widget.clientId;

    // تجهيز الـ Futures مرة واحدة
    _futureTopSelling = _productRepository.fetchTopSellingForClient(_clientId);
    _futureTopPurchased =
        _productRepository.fetchTopPurchasedForClient(_clientId);
    _futureProductsForSuppliers =
        _productRepository.fetchHomeProducts(_clientId);
  }

  void _openSupplierPage({
    required int supplierId,
    required String supplierName,
    required String productCode,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ClientAppSupplierScreen(
          clientId: _clientId,
          supplierId: supplierId,
          supplierName: supplierName,
          initialProductCode: productCode,
        ),
      ),
    );
  }

  // --- عنوان القسم ---
  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
              fontFamily: 'Cairo',
            ),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- كارت المنتج الأفقي (للصفوف 1 و 2) ---
  Widget _buildProductCard(ClientHomeTopProductModel product) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _openSupplierPage(
              supplierId: product.bestSupplierId,
              supplierName: product.bestSupplierName,
              productCode: product.productCode,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
                    )
                        : const Icon(
                      Icons.image,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              // تفاصيل المنتج
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المنتج
                    Text(
                      product.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // اسم المورد الأفضل
                    Text(
                      product.bestSupplierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // السعر
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.bestPrice.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue[800],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- القسم 1: الأكثر مبيعاً ---
  Widget _buildTopSellingSection() {
    return FutureBuilder<List<ClientHomeTopProductModel>>(
      future: _futureTopSelling,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            _buildSectionTitle('الأكثر مبيعاً في محافظتك'),
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(items[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- القسم 2: الأكثر شراءً (طلبات متكررة) ---
  Widget _buildTopPurchasedSection() {
    return FutureBuilder<List<ClientHomeTopProductModel>>(
      future: _futureTopPurchased,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            _buildSectionTitle('طلباتك المتكررة'),
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(items[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- كارت المورد في قائمة "الموردون المتاحون" ---
  Widget _buildSupplierCard(ClientAppMainProduct item) {
    final supplierName = item.supplierNameAr;
    final firstLetter =
    supplierName.isNotEmpty ? supplierName.characters.first : 'م';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[50],
          child: Text(
            firstLetter,
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          supplierName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'حد أدنى: ${item.minOrderValue.toStringAsFixed(2)} ج.م - عدد أصناف: ${item.minItemsCount}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _openSupplierPage(
              supplierId: item.supplierId,
              supplierName: supplierName,
              productCode: '',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue[800],
            elevation: 0,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('تسوق'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // --- الهيدر ---
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مرحباً بك 👋',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'تطبيق العميل',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // شريط البحث
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => ClientAppSearchScreen(
                                clientId: _clientId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border:
                            Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 12),
                              Text(
                                'ابحث عن منتج أو مورد...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // --- المحتوى ---
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildTopSellingSection(),
                      const SizedBox(height: 24),
                      _buildTopPurchasedSection(),
                      const SizedBox(height: 24),

                      _buildSectionTitle('الموردون المتاحون'),
                      FutureBuilder<List<ClientAppMainProduct>>(
                        future: _futureProductsForSuppliers,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'حدث خطأ أثناء تحميل الموردين',
                                style: TextStyle(
                                  color: Colors.red[700],
                                ),
                              ),
                            );
                          }

                          final products = snapshot.data ?? [];
                          if (products.isEmpty) {
                            return const Center(
                              child: Text('لا يوجد موردون متاحون حالياً'),
                            );
                          }

                          // تجميع بيانات الموردين بدون تكرار
                          final Map<int, ClientAppMainProduct> suppliersMap =
                          {};
                          for (final item in products) {
                            suppliersMap.putIfAbsent(
                              item.supplierId,
                                  () => item,
                            );
                          }

                          final suppliersList =
                          suppliersMap.values.toList()
                            ..sort((a, b) => a.supplierNameAr
                                .compareTo(b.supplierNameAr));

                          return ListView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            itemCount: suppliersList.length,
                            itemBuilder: (context, index) {
                              return _buildSupplierCard(
                                suppliersList[index],
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
