import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/services/tenant_service.dart';
import '../widgets/admin_drawer.dart';

class AdminTenantProfilePage extends StatefulWidget {
  const AdminTenantProfilePage({super.key});

  @override
  State<AdminTenantProfilePage> createState() => _AdminTenantProfilePageState();
}

class _AdminTenantProfilePageState extends State<AdminTenantProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _metaTitleCtrl = TextEditingController();
  final _metaDescCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCompressing = false;
  CompressedImageFile? _newLogo;
  String _selectedColor = '#6F4E37';

  // Preset warna populer untuk brand makanan / kafe
  final List<Map<String, dynamic>> _colorPresets = [
    {
      'name': 'Kopi / Espresso',
      'hex': '#6F4E37',
      'color': const Color(0xFF6F4E37),
    },
    {'name': 'Coklat Tua', 'hex': '#3E2723', 'color': const Color(0xFF3E2723)},
    {'name': 'Hijau Fresh', 'hex': '#00AA13', 'color': const Color(0xFF00AA13)},
    {
      'name': 'Teal Emerald',
      'hex': '#0D9488',
      'color': const Color(0xFF0D9488),
    },
    {'name': 'Orange Warm', 'hex': '#EA580C', 'color': const Color(0xFFEA580C)},
    {
      'name': 'Merah Selera',
      'hex': '#DC2626',
      'color': const Color(0xFFDC2626),
    },
    {'name': 'Biru Modern', 'hex': '#0284C7', 'color': const Color(0xFF0284C7)},
    {'name': 'Ungu Royal', 'hex': '#7C3AED', 'color': const Color(0xFF7C3AED)},
  ];

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _logoCtrl.dispose();
    _colorCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTenantData() async {
    setState(() => _isLoading = true);
    try {
      final tenant = await TenantService.fetchTenantInfo();
      _nameCtrl.text = tenant.name;
      _logoCtrl.text = tenant.logoUrl ?? '';
      _selectedColor = tenant.primaryColor;
      _colorCtrl.text = tenant.primaryColor;
      _addressCtrl.text = tenant.address ?? '';
      _phoneCtrl.text = tenant.phone ?? '';
      _whatsappCtrl.text = tenant.whatsapp ?? '';
      _metaTitleCtrl.text = tenant.metaTitle ?? '';
      _metaDescCtrl.text = tenant.metaDescription ?? '';
    } catch (e) {
      debugPrint('Error loading tenant: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    setState(() => _isCompressing = true);
    try {
      final compressedLogo = await ImageUploadHelper.pickAndCompressImage(
        maxDimension: 400,
        quality: 82,
      );
      if (compressedLogo != null) {
        setState(() {
          _newLogo = compressedLogo;
        });
      }
    } catch (e) {
      debugPrint('Error picking logo: $e');
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      final fields = <String, String>{
        'name': _nameCtrl.text.trim(),
        'primary_color': _selectedColor,
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'meta_title': _metaTitleCtrl.text.trim(),
        'meta_description': _metaDescCtrl.text.trim(),
      };

      if (_newLogo == null) {
        fields['logo_url'] = _logoCtrl.text.trim();
      }

      final response = await client.postMultipart(
        '/tenant/update',
        fields: fields,
        fileField: _newLogo == null ? null : 'logo',
        fileBytes: _newLogo?.bytes,
        filename: _newLogo?.filename,
        contentType: _newLogo?.mimeType,
      );

      // Update URL dari server jika baru diupload
      if (response != null &&
          response['data'] != null &&
          response['data']['logo_url'] != null) {
        _logoCtrl.text = response['data']['logo_url'].toString();
        _newLogo = null;
      }

      // Clear cache agar data baru diambil kembali
      TenantService.clearCache();
      await TenantService.fetchTenantInfo();

      if (!mounted) return;
      TopNotification.show(
        message: 'Profil kantin & logo berhasil disimpan ke server!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal menyimpan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Widget _buildLogoPreview(Color activeThemeColor) {
    if (_newLogo != null) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _newLogo!.bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.storefront_rounded,
              color: activeThemeColor,
              size: 26,
            ),
          ),
        );
      } catch (_) {}
    }

    if (_logoCtrl.text.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _logoCtrl.text,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.storefront_rounded, color: activeThemeColor, size: 26),
        ),
      );
    }

    return Icon(Icons.storefront_rounded, color: activeThemeColor, size: 26);
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeColor = _parseColor(_selectedColor);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil & Logo Kantin'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PREVIEW HEADER PELANGGAN (LIVE PREVIEW)
                    const Text(
                      'Preview Tampilan di HP Pelanggan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Logo / Icon Preview
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: activeThemeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: activeThemeColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: _buildLogoPreview(activeThemeColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameCtrl.text.isEmpty
                                      ? 'Nama Kantin Anda'
                                      : _nameCtrl.text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Buka',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_addressCtrl.text.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      const Text(
                                        '•',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _addressCtrl.text,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // FORM SETTINGS
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Usaha & Tampilan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 1. NAMA KANTIN
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nama Kantin / Brand *',
                              hintText: 'Contoh: SAY COFFEE',
                              prefixIcon: Icon(Icons.storefront_rounded),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Nama kantin wajib diisi'
                                : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 20),

                          // 2. UPLOAD LOGO KANTIN
                          const Text(
                            'Logo Kantin (Upload & Kompres Otomatis)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Mini Preview
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: _buildLogoPreview(
                                        activeThemeColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: activeThemeColor,
                                              side: BorderSide(
                                                color: activeThemeColor,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            icon: _isCompressing
                                                ? SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              activeThemeColor,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.cloud_upload_rounded,
                                                    size: 20,
                                                  ),
                                            label: Text(
                                              _isCompressing
                                                  ? 'Mengompres...'
                                                  : 'Pilih & Upload Logo',
                                            ),
                                            onPressed: _isCompressing
                                                ? null
                                                : _pickLogo,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _newLogo != null
                                                ? '⚡ Gambar terpilih (Siap disimpan)'
                                                : (_logoCtrl.text.isNotEmpty
                                                      ? 'Logo aktif tersimpan di server'
                                                      : 'Pilih gambar dari HP atau Laptop'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _newLogo != null
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                              fontWeight: _newLogo != null
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_newLogo != null ||
                                        _logoCtrl.text.isNotEmpty)
                                      IconButton(
                                        tooltip: 'Hapus Logo',
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.danger,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _newLogo = null;
                                            _logoCtrl.clear();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Gambar otomatis dikompres ke ukuran optimal (< 50 KB) sebelum disimpan ke server agar loading cepat di HP pelanggan.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3. WARNA BRAND
                          const Text(
                            'Warna Identitas Brand',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _colorPresets.map((preset) {
                              final isSelected =
                                  _selectedColor.toUpperCase() == preset['hex'];
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = preset['hex'];
                                    _colorCtrl.text = preset['hex'];
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (preset['color'] as Color)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? (preset['color'] as Color)
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: preset['color'] as Color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        preset['name'] as String,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.grey.shade700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // 4. WHATSAPP
                          TextFormField(
                            controller: _whatsappCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Nomor WhatsApp Konfirmasi',
                              hintText: '628123456789 (format 62)',
                              prefixIcon: Icon(
                                Icons.chat_bubble_outline_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '💡 Nomor WA ini akan dipakai konsumen saat menekan tombol "Konfirmasi Bukti Transfer via WhatsApp".',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 5. ALAMAT
                          TextFormField(
                            controller: _addressCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Alamat Kantin / Usaha',
                              hintText: 'Contoh: Lantai 2 Gedung Utama...',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          // 6. PREVIEW LINK SOSIAL MEDIA (META TAGS)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: activeThemeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.share_rounded,
                                  size: 18,
                                  color: activeThemeColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Preview Link Sosial Media (WhatsApp / FB)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Kustomisasi judul dan teks ringkasan yang muncul saat link website kantin Anda dibagikan ke WhatsApp, Telegram, Facebook, dll.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // WhatsApp Style Link Preview
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 14,
                                      color: Color(0xFF25D366),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Simulasi tampilan saat link dibagikan di chat:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: activeThemeColor.withValues(alpha: 0.1),
                                          borderRadius: const BorderRadius.horizontal(
                                            left: Radius.circular(10),
                                          ),
                                        ),
                                        child: _buildLogoPreview(activeThemeColor),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _metaTitleCtrl.text.isNotEmpty
                                                    ? _metaTitleCtrl.text
                                                    : (_nameCtrl.text.isNotEmpty
                                                        ? _nameCtrl.text
                                                        : 'Nama Kantin'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                _metaDescCtrl.text.isNotEmpty
                                                    ? _metaDescCtrl.text
                                                    : (_addressCtrl.text.isNotEmpty
                                                        ? _addressCtrl.text
                                                        : 'Pesan menu favorit Anda langsung dari smartphone tanpa perlu antre.'),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                  height: 1.25,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'ekasir.my.id',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 6a. Judul Preview Link (Meta Title)
                          TextFormField(
                            controller: _metaTitleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Judul Preview Link (Meta Title)',
                              hintText: 'Contoh: SAY COFFEE - Ngopi Santai & Nikmat',
                              prefixIcon: Icon(Icons.title_rounded),
                              helperText: 'Judul link saat dibagikan. Kosongkan jika ingin sama dengan Nama Kantin.',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),

                          // 6b. Deskripsi Preview Link (Meta Description)
                          TextFormField(
                            controller: _metaDescCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Deskripsi Preview Link (Meta Description)',
                              hintText: 'Contoh: Pesan berbagai macam varian kopi susu aren, teh segar, dan camilan nikmat langsung dari smartphone Anda.',
                              prefixIcon: Icon(Icons.description_outlined),
                              helperText: 'Teks deskripsi ringkasan yang muncul di bawah judul saat link dibagikan.',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 24),

                          // TOMBOL SIMPAN
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeThemeColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isSaving ? null : _saveTenant,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_rounded, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Simpan Profil Kantin',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
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
}
