// lib/screens/client_app_register_screen.dart
// ===========================================================
// Code: client_app_register_screen
// شاشة إنشاء حساب عميل جديد (Client App)
// ===========================================================

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientAppRegisterScreen extends StatefulWidget {
  const ClientAppRegisterScreen({super.key});

  @override
  State<ClientAppRegisterScreen> createState() =>
      _ClientAppRegisterScreenState();
}

class _ClientAppRegisterScreenState extends State<ClientAppRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // عشان نفعّل الـ validation بعد أول محاولة تسجيل
  bool _autoValidate = false;

  // ====================== Controllers ======================
  final TextEditingController _tradeName = TextEditingController();
  final TextEditingController _managerName = TextEditingController();
  final TextEditingController _phone1 = TextEditingController();

  final TextEditingController _manager2 = TextEditingController();
  final TextEditingController _phone2 = TextEditingController();
  final TextEditingController _phone2Landline = TextEditingController();

  final TextEditingController _address = TextEditingController();
  final TextEditingController _gpsLat = TextEditingController();
  final TextEditingController _gpsLng = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _loading = false;
  bool _hidePass = true;
  bool _hideConfirm = true;

  // ====================== Lookups ======================
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _counties = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _categories = []; // مستوى 1 و 2

  int? _selectedActivityId;
  int? _selectedCountyId;
  int? _selectedAreaId;
  int? _selectedRouteId;

  // نخزن IDs للفروع فقط (level 2)
  final Set<int> _selectedCategoryIds = {};

  bool _lookupsLoading = false;
  bool _areasLoading = false;
  bool _routesLoading = false;
  bool _categoriesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialLookups();
  }

  @override
  void dispose() {
    _tradeName.dispose();
    _managerName.dispose();
    _phone1.dispose();
    _manager2.dispose();
    _phone2.dispose();
    _phone2Landline.dispose();
    _address.dispose();
    _gpsLat.dispose();
    _gpsLng.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // ====================== Helpers ======================

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
    );
  }

  String _hash(String pass) {
    final bytes = utf8.encode(pass.trim());
    return sha256.convert(bytes).toString();
  }

  String? _required(String? v, String field) {
    if (v == null || v.trim().isEmpty) {
      return 'من فضلك أدخل $field';
    }
    return null;
  }

  String? _requiredPhone(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'من فضلك أدخل رقم التليفون';
    }
    final p = v.trim();

    if (!RegExp(r'^[0-9]+$').hasMatch(p)) {
      return 'رقم التليفون يجب أن يكون أرقام فقط';
    }
    if (p.length != 11) {
      return 'رقم التليفون يجب أن يكون 11 رقمًا';
    }

    return null;
  }

  String? _requiredPassword(String? v) {
    if (v == null || v.trim().isEmpty) return 'من فضلك أدخل كلمة المرور';
    if (v.trim().length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف/أرقام على الأقل';
    }
    return null;
  }

  // ====================== GPS ======================

  Future<void> _fillCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _msg('خدمة تحديد الموقع مغلقة على الجهاز.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _msg('تم رفض إذن الوصول للموقع.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _msg('تم رفض إذن الموقع بشكل دائم، عدّل الصلاحيات من إعدادات الجهاز.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _gpsLat.text = position.latitude.toStringAsFixed(6);
      _gpsLng.text = position.longitude.toStringAsFixed(6);

      _msg('تم تحديد موقعك الحالي بنجاح.');
    } catch (e) {
      debugPrint('GPS ERROR: $e');
      _msg('تعذر الحصول على الموقع الحالي، حاول مرة أخرى.');
    }
  }

  // ====================== Load Lookups ======================

  Future<void> _loadInitialLookups() async {
    setState(() => _lookupsLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // الأنشطة
      final activities = await supabase
          .from('client_activities')
          .select('activity_id, activity_name_ar, activity_status')
          .eq('activity_status', 1)
          .order('sort_order', ascending: true);

      // المحافظات
      final counties = await supabase
          .from('counties')
          .select('county_id, county_name_ar, county_status')
          .eq('county_status', 1)
          .order('county_name_ar', ascending: true);

      // كل التصنيفات (مستوى 1 و 2)
      setState(() => _categoriesLoading = true);
      final categories = await supabase
          .from('product_categories')
          .select(
        'category_id, parent_category_id, category_name_ar, category_level, category_status',
      )
          .eq('category_status', 1)
          .order('category_level', ascending: true)
          .order('category_name_ar', ascending: true);

      if (!mounted) return;

      setState(() {
        _activities = List<Map<String, dynamic>>.from(activities);
        _counties = List<Map<String, dynamic>>.from(counties);
        _categories = List<Map<String, dynamic>>.from(categories);

        if (_activities.isNotEmpty) {
          _selectedActivityId = _activities.first['activity_id'] as int;
        }
        if (_counties.isNotEmpty) {
          _selectedCountyId = _counties.first['county_id'] as int;
        }
      });

      if (_selectedCountyId != null) {
        await _loadAreasForCounty(_selectedCountyId!);
      }

      if (_selectedActivityId != null) {
        await _loadDefaultCategoriesForActivity(_selectedActivityId!);
      }
    } catch (e) {
      debugPrint('LOOKUPS ERROR: $e');
      _msg('تعذر تحميل بيانات الأنشطة/المحافظات/التصنيفات.');
    } finally {
      if (mounted) {
        setState(() {
          _lookupsLoading = false;
          _categoriesLoading = false;
        });
      }
    }
  }

  Future<void> _loadAreasForCounty(int countyId) async {
    setState(() {
      _areasLoading = true;
      _areas = [];
      _routes = [];
      _selectedAreaId = null;
      _selectedRouteId = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final areas = await supabase
          .from('areas')
          .select('area_id, area_name_ar, area_status')
          .eq('county_id', countyId)
          .eq('area_status', 1)
          .order('area_name_ar', ascending: true);

      if (!mounted) return;

      setState(() {
        _areas = List<Map<String, dynamic>>.from(areas);
        if (_areas.isNotEmpty) {
          _selectedAreaId = _areas.first['area_id'] as int;
        }
      });

      if (_selectedAreaId != null) {
        await _loadRoutesForArea(_selectedAreaId!);
      }
    } catch (e) {
      debugPrint('AREAS ERROR: $e');
      _msg('تعذر تحميل بيانات المناطق.');
    } finally {
      if (mounted) setState(() => _areasLoading = false);
    }
  }

  Future<void> _loadRoutesForArea(int areaId) async {
    setState(() {
      _routesLoading = true;
      _routes = [];
      _selectedRouteId = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final routes = await supabase
          .from('routes')
          .select('route_id, route_name_ar, route_status')
          .eq('area_id', areaId)
          .eq('route_status', 1)
          .order('route_name_ar', ascending: true);

      if (!mounted) return;

      setState(() {
        _routes = List<Map<String, dynamic>>.from(routes);
        if (_routes.isNotEmpty) {
          _selectedRouteId = _routes.first['route_id'] as int;
        }
      });
    } catch (e) {
      debugPrint('ROUTES ERROR: $e');
      _msg('تعذر تحميل بيانات خطوط السير.');
    } finally {
      if (mounted) setState(() => _routesLoading = false);
    }
  }

  Future<void> _loadDefaultCategoriesForActivity(int activityId) async {
    try {
      final supabase = Supabase.instance.client;

      final defaults = await supabase
          .from('activity_default_categories')
          .select('category_id')
          .eq('activity_id', activityId);

      if (!mounted) return;

      setState(() {
        _selectedCategoryIds.clear();

        for (final row in defaults) {
          final int catId = row['category_id'] as int;

          final matches =
          _categories.where((c) => c['category_id'] == catId).toList();
          if (matches.isEmpty) continue;

          final cat = matches.first;
          final int level = cat['category_level'] as int;

          if (level == 1) {
            // لو التصنيف الافتراضي رئيسي → نختار كل الفروع تحته
            final children = _categories.where(
                  (c) =>
              c['parent_category_id'] == catId &&
                  c['category_level'] == 2,
            );
            for (final ch in children) {
              _selectedCategoryIds.add(ch['category_id'] as int);
            }
          } else if (level == 2) {
            _selectedCategoryIds.add(catId);
          }
        }
      });
    } catch (e) {
      debugPrint('DEFAULT CATS ERROR: $e');
    }
  }

  // ====================== Register Logic ======================

  Future<void> _onRegister() async {
    // نفعل الـ auto validate بعد أول ضغط على الزر
    setState(() {
      _autoValidate = true;
    });

    // هيعمل فحص لكل الفاليديتور ويخلي الحقول الغلط إطارها أحمر
    if (!_formKey.currentState!.validate()) return;

    if (_selectedActivityId == null) {
      _msg('من فضلك اختر النشاط.');
      return;
    }
    if (_selectedCountyId == null) {
      _msg('من فضلك اختر المحافظة.');
      return;
    }
    if (_selectedAreaId == null) {
      _msg('من فضلك اختر المنطقة.');
      return;
    }
    if (_selectedRouteId == null) {
      _msg('من فضلك اختر خط السير.');
      return;
    }

    // تأكيد كلمة المرور
    final pass = _pass.text.trim();
    final confirm = _confirm.text.trim();
    if (pass != confirm) {
      _msg('كلمة المرور غير متطابقة.');
      return;
    }

    // لازم فئة فرعية واحدة على الأقل
    final selectedLeafCount = _categories
        .where(
          (c) =>
      c['category_level'] == 2 &&
          _selectedCategoryIds.contains(c['category_id'] as int),
    )
        .length;
    if (selectedLeafCount == 0) {
      _msg('من فضلك اختر على الأقل فئة فرعية واحدة من التصنيفات.');
      return;
    }

    setState(() => _loading = true);

    String? createdUserId;
    bool clientCreated = false;

    try {
      final supabase = Supabase.instance.client;

      final trade = _tradeName.text.trim();
      final manager = _managerName.text.trim();
      final p1 = _phone1.text.trim();

      final manager2 = _manager2.text.trim();
      final p2 = _phone2.text.trim();
      final landline = _phone2Landline.text.trim();

      final addr = _address.text.trim();
      final latText = _gpsLat.text.trim();
      final lngText = _gpsLng.text.trim();

      // تأكد أن الموبايل غير مسجَّل
      final existingUser = await supabase
          .from('users')
          .select('user_id')
          .eq('user_mobile', p1)
          .maybeSingle();

      if (existingUser != null) {
        _msg('هذا الرقم مسجَّل بالفعل، يمكنك تسجيل الدخول مباشرة.');
        setState(() => _loading = false);
        return;
      }

      // إنشاء user
      final newUser = await supabase
          .from('users')
          .insert({
        'user_mobile': p1,
        'user_password_hash': _hash(pass),
        'user_type': 1, // عميل
        'user_status': 1,
      })
          .select('user_id')
          .single();

      final String userId = newUser['user_id'];
      createdUserId = userId;

      // GPS (اختياري)
      num? gpsLat;
      num? gpsLng;
      if (latText.isNotEmpty) {
        gpsLat = num.tryParse(latText);
      }
      if (lngText.isNotEmpty) {
        gpsLng = num.tryParse(lngText);
      }

      // إنشاء client
      await supabase.from('clients').insert({
        'client_id': userId,
        'trade_name': trade,
        'primary_contact_name': manager,
        'primary_mobile': p1,
        'secondary_contact_name': manager2.isEmpty ? null : manager2,
        'secondary_mobile': p2.isEmpty ? null : p2,
        'secondary_phone': landline.isEmpty ? null : landline,
        'detailed_address': addr,
        'gps_lat': gpsLat,
        'gps_lng': gpsLng,
        'activity_id': _selectedActivityId,
        'area_id': _selectedAreaId,
        'route_id': _selectedRouteId,
        'client_status': 1,
        'created_by': userId,
      });

      clientCreated = true;

      // ربط التصنيفات (فروع فقط) - upsert لتفادي تكرار uq_client_category
      final rowsToInsert = _selectedCategoryIds.map((catId) {
        return {
          'client_id': userId,
          'category_id': catId,
          'is_default': true,
        };
      }).toList();

      if (rowsToInsert.isNotEmpty) {
        await supabase
            .from('client_categories')
            .upsert(rowsToInsert, onConflict: 'client_id,category_id');
      }

      if (!mounted) return;

      _msg('تم إنشاء الحساب وربط التصنيفات بنجاح 🎉');

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/client/home',
            (route) => false,
        arguments: userId,
      );
    } catch (e, stack) {
      debugPrint('REGISTER ERROR: $e');
      debugPrint('STACK: $stack');

      if (createdUserId != null && !clientCreated) {
        try {
          final supabase = Supabase.instance.client;
          await supabase.from('users').delete().eq('user_id', createdUserId);
        } catch (cleanupError) {
          debugPrint('CLEANUP ERROR (delete user): $cleanupError');
        }
      }

      _msg('حدث خطأ أثناء إنشاء الحساب، حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ====================== UI Helpers ======================

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.deepPurple, width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.red, width: 1.4),
      ),
      prefixIcon: icon != null ? Icon(icon) : null,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required bool isRequired,
    required T? value,
    required List<Map<String, dynamic>> items,
    required String valueKey,
    required String labelKey,
    required void Function(T?) onChanged,
    bool isLoading = false,
    IconData? icon,
  }) {
    final effectiveLabel =
    isRequired ? '$label *' : '$label (اختياري)';

    if (isLoading) {
      return InputDecorator(
        decoration: _inputDecoration(label: effectiveLabel, icon: icon),
        child: const SizedBox(
          height: 24,
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return DropdownButtonFormField<T>(
      decoration: _inputDecoration(label: effectiveLabel, icon: icon),
      isExpanded: true,
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
          value: e[valueKey] as T,
          child: Text(e[labelKey] as String),
        ),
      )
          .toList(),
      initialValue: value,
      onChanged: onChanged,
      validator: isRequired
          ? (v) => v == null ? 'من فضلك اختر $label' : null
          : null,
    );
  }

  Widget _buildCategoriesTree() {
    if (_categoriesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Text(
        'لا توجد تصنيفات متاحة حالياً.',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      );
    }

    final parents =
    _categories.where((c) => (c['category_level'] as int) == 1).toList();

    final childrenByParent = <int, List<Map<String, dynamic>>>{};
    for (final cat
    in _categories.where((c) => (c['category_level'] as int) == 2)) {
      final parentId = cat['parent_category_id'] as int?;
      if (parentId == null) continue;
      childrenByParent.putIfAbsent(parentId, () => []);
      childrenByParent[parentId]!.add(cat);
    }

    return ListView.builder(
      itemCount: parents.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final parent = parents[index];
        final int parentId = parent['category_id'] as int;
        final String parentName = parent['category_name_ar'] as String;
        final children = childrenByParent[parentId] ?? [];

        final int selectedChildrenCount = children
            .where(
              (c) => _selectedCategoryIds.contains(
            c['category_id'] as int,
          ),
        )
            .length;

        bool? parentCheckboxValue;
        if (children.isEmpty) {
          parentCheckboxValue = false;
        } else if (selectedChildrenCount == 0) {
          parentCheckboxValue = false;
        } else if (selectedChildrenCount == children.length) {
          parentCheckboxValue = true;
        } else {
          parentCheckboxValue = null; // حالة متوسطة
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              title: Row(
                children: [
                  Checkbox(
                    tristate: true,
                    value: parentCheckboxValue,
                    onChanged: (v) {
                      setState(() {
                        if (children.isEmpty) return;

                        if (v == true) {
                          for (final ch in children) {
                            _selectedCategoryIds
                                .add(ch['category_id'] as int);
                          }
                        } else {
                          for (final ch in children) {
                            _selectedCategoryIds
                                .remove(ch['category_id'] as int);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      parentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              children: children.isEmpty
                  ? [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'لا توجد فئات فرعية.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ]
                  : children
                  .map(
                    (child) => CheckboxListTile(
                  value: _selectedCategoryIds
                      .contains(child['category_id'] as int),
                  onChanged: (v) {
                    setState(() {
                      final id = child['category_id'] as int;
                      if (v == true) {
                        _selectedCategoryIds.add(id);
                      } else {
                        _selectedCategoryIds.remove(id);
                      }
                    });
                  },
                  dense: true,
                  title: Text(
                    child['category_name_ar'] as String,
                    style: const TextStyle(fontSize: 13),
                  ),
                  controlAffinity:
                  ListTileControlAffinity.leading,
                ),
              )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  // ====================== UI ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تسجيل حساب عميل"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          color: const Color(0xFFF7F2F9),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.always
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          Column(
                            children: const [
                              Icon(
                                Icons.receipt_long,
                                size: 60,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "فاتورتك - عميل",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "مرحباً بك! من فضلك أدخل بيانات نشاطك بدقة.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ========= بيانات النشاط =========
                          const Text(
                            "بيانات النشاط",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _tradeName,
                            decoration: _inputDecoration(
                              label: "الاسم التجاري (اسم المحل) *",
                              icon: Icons.storefront,
                            ),
                            validator: (v) => _required(v, "الاسم التجاري"),
                          ),
                          const SizedBox(height: 12),

                          _buildDropdown<int>(
                            label: "النشاط",
                            isRequired: true,
                            value: _selectedActivityId,
                            items: _activities,
                            valueKey: 'activity_id',
                            labelKey: 'activity_name_ar',
                            onChanged: (val) {
                              setState(() => _selectedActivityId = val);
                              if (val != null) {
                                _loadDefaultCategoriesForActivity(val);
                              }
                            },
                            isLoading: _lookupsLoading,
                            icon: Icons.category,
                          ),

                          const SizedBox(height: 20),

                          // ========= المسؤول الأساسي =========
                          const Text(
                            "المسؤول الأساسي",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _managerName,
                            decoration: _inputDecoration(
                              label: "اسم المسؤول الأساسي *",
                              icon: Icons.person,
                            ),
                            validator: (v) => _required(v, "اسم المسؤول"),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _phone1,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              label: "رقم التليفون الأساسي *",
                              icon: Icons.phone_android,
                            ),
                            validator: _requiredPhone,
                          ),

                          const SizedBox(height: 20),

                          // ========= مسؤول ثاني اختياري =========
                          const Text(
                            "مسؤول ثاني (اختياري)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _manager2,
                            decoration: _inputDecoration(
                              label: "اسم المسؤول الثاني (اختياري)",
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _phone2,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              label:
                              "رقم تليفون المسؤول الثاني (موبايل) (اختياري)",
                              icon: Icons.phone,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _phone2Landline,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              label: "رقم تليفون أرضي / ثابت (اختياري)",
                              icon: Icons.call,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ========= الموقع الجغرافي =========
                          const Text(
                            "الموقع الجغرافي",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          _buildDropdown<int>(
                            label: "المحافظة",
                            isRequired: true,
                            value: _selectedCountyId,
                            items: _counties,
                            valueKey: 'county_id',
                            labelKey: 'county_name_ar',
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => _selectedCountyId = val);
                              _loadAreasForCounty(val);
                            },
                            isLoading: _lookupsLoading,
                            icon: Icons.location_city,
                          ),
                          const SizedBox(height: 12),

                          _buildDropdown<int>(
                            label: "المنطقة",
                            isRequired: true,
                            value: _selectedAreaId,
                            items: _areas,
                            valueKey: 'area_id',
                            labelKey: 'area_name_ar',
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => _selectedAreaId = val);
                              _loadRoutesForArea(val);
                            },
                            isLoading: _areasLoading,
                            icon: Icons.map,
                          ),
                          const SizedBox(height: 12),

                          _buildDropdown<int>(
                            label: "خط السير",
                            isRequired: true,
                            value: _selectedRouteId,
                            items: _routes,
                            valueKey: 'route_id',
                            labelKey: 'route_name_ar',
                            onChanged: (val) {
                              setState(() => _selectedRouteId = val);
                            },
                            isLoading: _routesLoading,
                            icon: Icons.alt_route,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _address,
                            decoration: _inputDecoration(
                              label: "العنوان التفصيلي *",
                              icon: Icons.home,
                            ),
                            maxLines: 2,
                            validator: (v) => _required(v, "العنوان التفصيلي"),
                          ),
                          const SizedBox(height: 8),

                          TextButton.icon(
                            onPressed: _fillCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text(
                              'اختياري: استخدام موقعي الحالي لتسهيل التوصيل',
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ========= التصنيفات =========
                          const Text(
                            "التصنيفات المرتبطة بالنشاط",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "اختر التصنيفات الفرعية التي تهمك (يجب اختيار فئة فرعية واحدة على الأقل).",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),

                          _buildCategoriesTree(),

                          const SizedBox(height: 20),

                          // ========= بيانات الدخول =========
                          const Text(
                            "بيانات الدخول",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _pass,
                            obscureText: _hidePass,
                            decoration: _inputDecoration(
                              label: "كلمة المرور *",
                              icon: Icons.lock,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _hidePass
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                      () => _hidePass = !_hidePass,
                                ),
                              ),
                            ),
                            validator: _requiredPassword,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _confirm,
                            obscureText: _hideConfirm,
                            decoration: _inputDecoration(
                              label: "تأكيد كلمة المرور *",
                              icon: Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _hideConfirm
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                      () => _hideConfirm = !_hideConfirm,
                                ),
                              ),
                            ),
                            validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? "من فضلك أكد كلمة المرور"
                                : null,
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _onRegister,
                              child: _loading
                                  ? const CircularProgressIndicator()
                                  : const Text("إنشاء حساب جديد"),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/client/login'),
                            child: const Text("لديك حساب؟ تسجيل الدخول"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
