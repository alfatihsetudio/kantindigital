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

class LogoSettingsPage extends StatefulWidget {
  const LogoSettingsPage({super.key});

  @override
  State<LogoSettingsPage> createState() => _LogoSettingsPageState();
}

class _LogoSettingsPageState extends State<LogoSettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCompressing = false;
  String _currentLogoUrl = '';
  CompressedImageFile? _newLogo;
  String _tenantName = '';
  String _primaryColorHex = '#00AA13';

  @override
  void initState() {
    super.initState();
    _loadTenantData();
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

  ImageProvider? _buildTenantLogoProvider(String rawUrl) {
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
      _currentLogoUrl = tenant.logoUrl ?? '';
      _primaryColorHex = tenant.primaryColor;
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

  Future<void> _saveLogo() async {
    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      final fields = <String, String>{
        'name': _tenantName.isNotEmpty ? _tenantName : 'Kantin',
      };

      if (_newLogo == null) {
        fields['logo_url'] = _currentLogoUrl.trim();
      }

      final files = <http.MultipartFile>[];
      if (_newLogo != null) {
        files.add(
          http.MultipartFile.fromBytes(
            'logo',
            _newLogo!.bytes,
            filename: _newLogo!.filename,
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
        if (response['data']['logo_url'] != null) {
          _currentLogoUrl = response['data']['logo_url'].toString();
          _newLogo = null;
        }
      }

      TenantService.clearCache();
      final savedTenant = await TenantService.fetchTenantInfo(
        forceRefresh: true,
      );
      AuthSession().updateTenant(savedTenant);

      if (!mounted) return;
      TopNotification.show(
        message: 'Logo kantin berhasil disimpan!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal menyimpan logo: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildLogoPreview(Color themeColor) {
    if (_newLogo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          _newLogo!.bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    if (_currentLogoUrl.trim().isNotEmpty) {
      final provider = _buildTenantLogoProvider(_currentLogoUrl);
      if (provider != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image(
            image: provider,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Icon(
              Icons.storefront_rounded,
              color: themeColor,
              size: 40,
            ),
          ),
        );
      }
    }
    return Icon(
      Icons.storefront_rounded,
      color: themeColor,
      size: 48,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(_primaryColorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Logo Kantin'),
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
                                Icons.image_rounded,
                                color: themeColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Logo Kantin / Brand',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Logo ini akan tampil di header aplikasi pemesanan dan struk kasir.',
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
                        const SizedBox(height: 24),

                        // Logo Preview Box
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: themeColor.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _buildLogoPreview(themeColor),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _newLogo != null
                                    ? '⚡ Gambar baru siap disimpan'
                                    : (_currentLogoUrl.isNotEmpty
                                        ? 'Logo aktif tersimpan di server'
                                        : 'Belum ada logo (menggunakan icon default)'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _newLogo != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _newLogo != null
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _isCompressing ? null : _pickLogo,
                                icon: _isCompressing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                                label: Text(
                                  _isCompressing ? 'Mengompres...' : 'Pilih & Upload Logo',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            if (_newLogo != null || _currentLogoUrl.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.dangerLight),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _newLogo = null;
                                    _currentLogoUrl = '';
                                  });
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                label: const Text('Hapus'),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 20,
                                color: Color(0xFF16A34A),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Gambar otomatis dikompres ke ukuran optimal (< 50 KB) sebelum disimpan ke server agar loading di HP pelanggan tetap super cepat.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF166534),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            onPressed: _isSaving ? null : _saveLogo,
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
                                        'Simpan Logo Kantin',
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
