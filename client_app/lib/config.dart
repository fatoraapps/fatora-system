// lib/config.dart

class AppConfig {
  /// رابط مشروع Supabase الأساسي
  static const String kSupabaseUrl =
      'https://khwddssianwaxxhbqrxj.supabase.co';

  /// رابط الـ API (حاليًا نفس رابط Supabase، ويمكن تغييره لاحقًا لو نقلت السيرفر)
  static const String kBaseApiUrl = kSupabaseUrl;

  /// مفتاح Supabase Anon (خاص بالفرونت فقط، لا يُستخدم في السيرفر)
  static const String kSupabaseAnonKey =
      'sb_publishable_ACF1K95oMY2xwgd5BUqVsQ_gum1XOd4';

  /// رابط مجلد صور المنتجات في Supabase Storage
  /// ملاحظة: ننهيه بـ "/" عشان نقدر نضيف كود المنتج مباشرة بعده
  ///
  /// مثال ناتج:
  /// https://.../storage/v1/object/public/product_images/10023001300007.png
  static const String kStorageBaseUrl =
      '$kSupabaseUrl/storage/v1/object/public/product_images/';

  /// رابط سلة صور الموردين
  /// bucket name: supplier_images
  static const String kSupplierImagesBaseUrl =
      '$kSupabaseUrl/storage/v1/object/public/supplier_images/';


}

