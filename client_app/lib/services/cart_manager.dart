// lib/services/cart_manager.dart
import 'package:flutter/foundation.dart';

class CartManager extends ChangeNotifier {
  // Singleton Pattern: لضمان وجود نسخة واحدة فقط في التطبيق
  static final CartManager _instance = CartManager._internal();

  factory CartManager() {
    return _instance;
  }

  CartManager._internal();

  // المخزن: المفتاح (Key) والقيمة (الكمية)
  final Map<String, int> _items = {};

  // 💡 إضافة الـ Getter 'items' لتصحيح الخطأ السابق
  // السماح بالوصول للقراءة إلى المخزن الداخلي
  Map<String, int> get items => _items;
  // ---------------------------------------------


  // دالة مساعدة لتكوين المفتاح الفريد
  String _getKey(int supplierId, String productCode, String unitName) {
    // 💡 ملاحظة: يجب أن يحتوي المفتاح على معلومات الوحدة لتكون فريدة
    // بما أننا نستخدم Map<String, int>، فنحن نخزن الكمية مباشرة.
    return '${supplierId}_${productCode}_$unitName';
  }

  // جلب الكمية الحالية
  int getQuantity(int supplierId, String productCode, String unitName) {
    final key = _getKey(supplierId, productCode, unitName);
    return _items[key] ?? 0;
  }

  // --- التعديل للمهمة 3: إضافة التحقق من الحد الأقصى ---
  // الدالة ترجع True إذا نجحت الإضافة، و False إذا وصلنا للحد الأقصى
  bool increment(int supplierId, String productCode, String unitName, double maxLimit) {
    final key = _getKey(supplierId, productCode, unitName);
    int current = _items[key] ?? 0;

    // الشرط الأمني: مقارنة الكمية الحالية مع الحد الأقصى
    // ملاحظة: قمنا بتحويل maxLimit إلى int للمقارنة الصحيحة
    if (current < maxLimit.toInt()) {
      _items[key] = current + 1;

      notifyListeners(); // تحديث الواجهة فوراً
      return true; // تمت الزيادة بنجاح
    } else {
      return false; // فشل: وصلنا للحد الأقصى
    }
  }
  // -----------------------------------------------------

  // إنقاص الكمية
  void decrement(int supplierId, String productCode, String unitName) {
    final key = _getKey(supplierId, productCode, unitName);
    int current = _items[key] ?? 0;

    if (current > 0) {
      _items[key] = current - 1;

      // إذا وصلت للصفر، نحذف المنتج من السلة لتوفير الذاكرة
      if (_items[key] == 0) {
        _items.remove(key);
      }

      notifyListeners(); // تحديث الواجهة فوراً
    }
  }

  // دالة اختيارية لتفريغ السلة
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}