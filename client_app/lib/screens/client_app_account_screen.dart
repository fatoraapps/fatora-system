// lib/screens/client_app_account_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientAppAccountScreen extends StatefulWidget {
  final String clientId;

  const ClientAppAccountScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientAppAccountScreen> createState() => _ClientAppAccountScreenState();
}

class _ClientAppAccountScreenState extends State<ClientAppAccountScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  Uint8List? _localAvatarBytes;
  String? _avatarUrl;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _countyController;
  late final TextEditingController _areaController;
  late final TextEditingController _routeController;

  late final TextEditingController _secondManagerNameController;
  late final TextEditingController _secondManagerPhoneController;

  final ImagePicker _picker = ImagePicker();
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _countyController = TextEditingController();
    _areaController = TextEditingController();
    _routeController = TextEditingController();
    _secondManagerNameController = TextEditingController();
    _secondManagerPhoneController = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countyController.dispose();
    _areaController.dispose();
    _routeController.dispose();
    _secondManagerNameController.dispose();
    _secondManagerPhoneController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  //  ❗ تحميل بيانات العميل من قاعدة البيانات
  // -------------------------------------------------------------
  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 1) جلب بيانات العميل الأساسية من clients
      final clientRow = await _supabase
          .from('clients')
          .select(
          'trade_name, primary_mobile, secondary_contact_name, secondary_mobile, secondary_phone, area_id, route_id')
          .eq('client_id', widget.clientId)
          .maybeSingle();

      if (clientRow == null) {
        setState(() {
          _errorMessage = 'لم يتم العثور على بيانات العميل.';
          _isLoading = false;
        });
        return;
      }

      _nameController.text = clientRow['trade_name'] ?? '';
      _phoneController.text = clientRow['primary_mobile'] ?? '';
      _secondManagerNameController.text =
          clientRow['secondary_contact_name'] ?? '';
      _secondManagerPhoneController.text =
          clientRow['secondary_mobile'] ?? clientRow['secondary_phone'] ?? '';

      final int? areaId = clientRow['area_id'];
      final int? routeId = clientRow['route_id'];

      // 2) جلب المنطقة + المحافظة
      if (areaId != null) {
        final areaRow = await _supabase
            .from('areas')
            .select('area_name_ar, county_id')
            .eq('area_id', areaId)
            .maybeSingle();

        if (areaRow != null) {
          _areaController.text = areaRow['area_name_ar'] ?? '';
          final int? countyId = areaRow['county_id'];

          if (countyId != null) {
            final countyRow = await _supabase
                .from('counties')
                .select('county_name_ar')
                .eq('county_id', countyId)
                .maybeSingle();

            if (countyRow != null) {
              _countyController.text = countyRow['county_name_ar'] ?? '';
            }
          }
        }
      }

      // 3) جلب خط السير
      if (routeId != null) {
        final routeRow = await _supabase
            .from('routes')
            .select('route_name_ar')
            .eq('route_id', routeId)
            .maybeSingle();

        if (routeRow != null) {
          _routeController.text = routeRow['route_name_ar'] ?? '';
        }
      }

      // 4) جلب الصورة من Storage إن وجدت
      try {
        final bucket = _supabase.storage.from('avatars');
        _avatarUrl =
            bucket.getPublicUrl('clients/${widget.clientId}.png'); // لا مشكلة لو مش موجود
      } catch (_) {}

      setState(() => _isLoading = false);
    } catch (e, st) {
      debugPrint('LOAD ERROR: $e\n$st');
      setState(() {
        _errorMessage = 'خطأ أثناء تحميل البيانات.';
        _isLoading = false;
      });
    }
  }

  // -------------------------------------------------------------
  //  ❗ اختيار الصورة قبل رفعها
  // -------------------------------------------------------------
  Future<void> _pickAvatar() async {
    try {
      final XFile? img =
      await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

      if (img == null) return;

      final bytes = await img.readAsBytes();

      setState(() => _localAvatarBytes = bytes);
    } catch (e) {
      _showSnack('تعذر اختيار الصورة: $e', isError: true);
    }
  }

  // -------------------------------------------------------------
  //  ❗ حفظ البيانات في clients + رفع الصورة Storage
  // -------------------------------------------------------------
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final secName = _secondManagerNameController.text.trim();
    final secPhone = _secondManagerPhoneController.text.trim();

    if (name.isEmpty) {
      _showSnack('يجب إدخال الاسم التجاري.', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // تحديث بيانات العميل
      await _supabase.from('clients').update({
        'trade_name': name,
        'secondary_contact_name': secName.isEmpty ? null : secName,
        'secondary_mobile': secPhone.isEmpty ? null : secPhone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('client_id', widget.clientId);

      // رفع الصورة إن تم تغييرها
      if (_localAvatarBytes != null) {
        final storage = _supabase.storage.from('avatars');
        final path = 'clients/${widget.clientId}.png';

        await storage.uploadBinary(
          path,
          _localAvatarBytes!,
          fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
        );

        _avatarUrl = storage.getPublicUrl(path);
      }

      _showSnack('تم حفظ البيانات بنجاح ✓');
    } catch (e, st) {
      debugPrint('SAVE ERROR: $e\n$st');
      _showSnack('تعذر حفظ البيانات.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------------
  //  ❗ تسجيل الخروج
  // -------------------------------------------------------------
  Future<void> _logout() async {
    try {
      await _supabase.auth.signOut();

      if (!mounted) return;   // ⭐ الحل هنا

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/client/login',
            (route) => false,
      );
    } catch (e) {
      _showSnack('تعذر تسجيل الخروج: $e', isError: true);
    }
  }


  // -------------------------------------------------------------
  //  ❗ Widgets
  // -------------------------------------------------------------
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حسابي'),
          centerTitle: true,
          elevation: 0.4,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAvatarSection(),
          const SizedBox(height: 16),
          _buildMainInfoCard(),
          const SizedBox(height: 16),
          _buildLocationCard(),
          const SizedBox(height: 16),
          _buildSecondManagerCard(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  // ---------------- Avatar ----------------
  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _localAvatarBytes != null
                    ? MemoryImage(_localAvatarBytes!)
                    : (_avatarUrl != null
                    ? NetworkImage(_avatarUrl!)
                    : null),
                child: (_localAvatarBytes == null && _avatarUrl == null)
                    ? const Icon(Icons.store, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: InkWell(
                onTap: _pickAvatar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.6),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16),
                ),
              ),
            )
          ],
        ),
        TextButton(
          onPressed: _pickAvatar,
          child: const Text("تغيير الصورة"),
        )
      ],
    );
  }

  // ---------------- Main Info ----------------
  Widget _buildMainInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "الاسم التجاري",
                prefixIcon: Icon(Icons.storefront),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "رقم التليفون الأساسي",
                prefixIcon: Icon(Icons.phone),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------- Location ----------------
  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReadOnlyTile(Icons.location_city, "المحافظة",
                _countyController.text),
            const SizedBox(height: 6),
            _buildReadOnlyTile(
                Icons.location_on, "المنطقة", _areaController.text),
            const SizedBox(height: 6),
            _buildReadOnlyTile(
                Icons.alt_route, "خط السير", _routeController.text),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text("$label: $value"))
        ],
      ),
    );
  }

  // ---------------- Second Manager ----------------
  Widget _buildSecondManagerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _secondManagerNameController,
              decoration: const InputDecoration(
                labelText: "اسم المسؤول الثاني",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _secondManagerPhoneController,
              decoration: const InputDecoration(
                labelText: "رقم تليفون المسؤول الثاني",
                prefixIcon: Icon(Icons.phone_in_talk),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------- Buttons ----------------
  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save),
            label: const Text("حفظ التعديلات"),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text("تسجيل الخروج"),
          ),
        ),
      ],
    );
  }
}
