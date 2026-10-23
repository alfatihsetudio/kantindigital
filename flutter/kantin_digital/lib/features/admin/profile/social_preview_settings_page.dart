import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/auth/auth_session.dart';
import '../../../shared/services/tenant_service.dart';
import '../widgets/admin_drawer.dart';

class SocialPreviewSettingsPage extends StatefulWidget {
  const SocialPreviewSettingsPage({super.key});

  @override
  State<SocialPreviewSettingsPage> createState() =>
      _SocialPreviewSettingsPageState();
}

class _SocialPreviewSettingsPageState extends State<SocialPreviewSettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCompressingMeta = false;
  bool _clearMetaImage = false;

  final _metaTitleCtrl = TextEditingController();
  final _metaDescCtrl = TextEditingController();
  final _metaImageCtrl = TextEditingController();
  CompressedImageFile? _newMetaImage;

  String _tenantName = '';
  String _tenantAddress = '';
  String _tenantLogoUrl = '';
  String _primaryColorHex = '#00AA13';

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  @override
  void dispose() {
    _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose();
    _metaImageCtrl.dispose();
    super.dispose();
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.primary;
    final cleanHex = hexString.replaceAll('#', '');
    try {
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  ImageProvider? _buildImageProvider(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('data:image')) {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex != -1) {
        try {
          return MemoryImage(base64Decode(trimmed.substring(commaIndex + 1)));
        } catch (_) {}
      }
    }
    return NetworkImage(trimmed);
  }

  Future<void> _loadTenantData() async {
    setState(() => _isLoading = true);
    try {
      final tenant = await TenantService.fetchTenantInfo(forceRefresh: true);
      _tenantName = tenant.name;
      _tenantAddress = tenant.address ?? '';
      _tenantLogoUrl = tenant.logoUrl ?? '';
      _primaryColorHex = tenant.primaryColor;
      _metaTitleCtrl.text = tenant.metaTitle ?? '';
      _metaDescCtrl.text = tenant.metaDescription ?? '';
      _metaImageCtrl.text = tenant.metaImageUrl ?? '';
      _clearMetaImage = false;
    } catch (e) {
      debugPrint('Error loading tenant: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMetaImage() async {
    setState(() => _isCompressingMeta = true);
    try {
      final compressed = await ImageUploadHelper.pickAndCompressImage(
        maxDimension: 1200,
        quality: 82,
      );
      if (compressed != null) {
        setState(() {
          _newMetaImage = compressed;
          _clearMetaImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking meta image: $e');
    } finally {
      if (mounted) setState(() => _isCompressingMeta = false);
    }
  }

  void _resetMetaImageToDefault() {
    setState(() {
      _newMetaImage = null;
      _metaImageCtrl.text = '';
      _clearMetaImage = true;
    });
  }

  Future<void> _saveSocialPreview() async {
    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      final fields = <String, String>{
        'name': _tenantName.isNotEmpty ? _tenantName : 'Kantin',
        'meta_title': _metaTitleCtrl.text.trim(),
        'meta_description': _metaDescCtrl.text.trim(),
      };

      if (_clearMetaImage) {
        fields['meta_image_url'] = '';
      } else if (_newMetaImage == null) {
        fields['meta_image_url'] = _metaImageCtrl.text.trim();
      }

      final files = <http.MultipartFile>[];
      if (_newMetaImage != null) {
        files.add(
          http.MultipartFile.fromBytes(
            'meta_image',
            _newMetaImage!.bytes,
            filename: _newMetaImage!.filename,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final response = await client.postMultipart(
        '/tenant/update',
        fields: fields,
        files: files.isNotEmpty ? files : null,
      );

      if (response != null && response['data'] != null) {
        if (response['data']['meta_image'] != null) {
          _metaImageCtrl.text = response['data']['meta_image'].toString();
          _newMetaImage = null;
          _clearMetaImage = false;
        } else if (_clearMetaImage) {
          _metaImageCtrl.text = '';
          _newMetaImage = null;
          _clearMetaImage = false;
        }
      }

      TenantService.clearCache();
      final savedTenant = await TenantService.fetchTenantInfo(
        forceRefresh: true,
      );
      AuthSession().updateTenant(savedTenant);

      if (!mounted) return;
      TopNotification.show(
        message: 'Pengaturan preview link medsos berhasil disimpan!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal menyimpan preview link: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildMetaImagePreview(Color themeColor) {
    if (_newMetaImage != null) {
      return Image.memory(
        _newMetaImage!.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (!_clearMetaImage && _metaImageCtrl.text.trim().isNotEmpty) {
      final provider = _buildImageProvider(_metaImageCtrl.text.trim());
      if (provider != null) {
        return Image(
          image: provider,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildFallbackLogo(themeColor),
        );
      }
    }
    return _buildFallbackLogo(themeColor);
  }

  Widget _buildFallbackLogo(Color themeColor) {
    if (_tenantLogoUrl.trim().isNotEmpty) {
      final provider = _buildImageProvider(_tenantLogoUrl.trim());
      if (provider != null) {
        return Image(
          image: provider,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Icon(
            Icons.storefront_rounded,
            color: themeColor,
            size: 28,
          ),
        );
      }
    }
    return Icon(
      Icons.storefront_rounded,
      color: themeColor,
      size: 28,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(_primaryColorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preview Link Medsos'),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.share_rounded,
                                color: themeColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preview Link Sosial Media (WhatsApp / FB)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Kustomisasi judul, ringkasan, dan gambar saat link website kantin dibagikan di WhatsApp/Medsos.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // WhatsApp Card Simulation
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 16,
                                    color: Color(0xFF25D366),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Simulasi tampilan saat link dibagikan di chat:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        color: themeColor.withValues(alpha: 0.1),
                                        borderRadius: const BorderRadius.horizontal(
                                          left: Radius.circular(10),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.horizontal(
                                          left: Radius.circular(10),
                                        ),
                                        child: _buildMetaImagePreview(themeColor),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _metaTitleCtrl.text.isNotEmpty
                                                  ? _metaTitleCtrl.text
                                                  : (_tenantName.isNotEmpty
                                                      ? _tenantName
                                                      : 'Nama Kantin'),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _metaDescCtrl.text.isNotEmpty
                                                  ? _metaDescCtrl.text
                                                  : (_tenantAddress.isNotEmpty
                                                      ? _tenantAddress
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
                        const SizedBox(height: 20),

                        // Image Upload Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 20,
                                    color: themeColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Gambar Preview Link (Meta Image)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_isCompressingMeta)
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: themeColor,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Mengompres...',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: themeColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Gambar thumbnail khusus saat dibagikan ke WhatsApp / medsos. Resolusi optimal 1200px otomatis dikompres agar ringan.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: _buildMetaImagePreview(themeColor),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: _isCompressingMeta
                                              ? null
                                              : _pickMetaImage,
                                          icon: const Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 16,
                                          ),
                                          label: Text(
                                            _isCompressingMeta
                                                ? 'Mengompres...'
                                                : 'Upload Gambar',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (_newMetaImage != null ||
                                            (!_clearMetaImage &&
                                                _metaImageCtrl.text.isNotEmpty))
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  Colors.red.shade700,
                                              side: BorderSide(
                                                color: Colors.red.shade200,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: _resetMetaImageToDefault,
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Gunakan Logo Saja',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title Field
                        TextFormField(
                          controller: _metaTitleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Judul Preview Link (Meta Title)',
                            hintText: 'Contoh: SAY COFFEE - Ngopi Santai & Nikmat',
                            prefixIcon: Icon(Icons.title_rounded),
                            helperText:
                                'Judul link saat dibagikan. Kosongkan jika ingin sama dengan Nama Kantin.',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Description Field
                        TextFormField(
                          controller: _metaDescCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi Preview Link (Meta Description)',
                            hintText:
                                'Contoh: Pesan berbagai varian kopi susu aren, teh segar, dan camilan nikmat langsung dari smartphone.',
                            prefixIcon: Icon(Icons.description_outlined),
                            helperText:
                                'Teks deskripsi ringkasan yang muncul di bawah judul saat link dibagikan.',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 28),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isSaving ? null : _saveSocialPreview,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Simpan Preview Link',
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
                ),
              ),
            ),
    );
  }
}
