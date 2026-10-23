import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/auth/auth_session.dart';
import '../../../shared/services/tenant_service.dart';
import '../widgets/admin_drawer.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedColor = '#6F4E37';
  final _colorCtrl = TextEditingController();
  String _tenantName = '';
  String _openingHours = '';
  String _address = '';
  String _logoUrl = '';

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
    _colorCtrl.dispose();
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
      _openingHours = tenant.openingHours;
      _address = tenant.address ?? '';
      _logoUrl = tenant.logoUrl ?? '';
      _selectedColor = tenant.primaryColor;
      _colorCtrl.text = tenant.primaryColor;
    } catch (e) {
      debugPrint('Error loading tenant: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAppearance() async {
    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      final fields = <String, String>{
        'name': _tenantName.isNotEmpty ? _tenantName : 'Kantin',
        'primary_color': _selectedColor.toUpperCase(),
      };

      await client.postMultipart(
        '/tenant/update',
        fields: fields,
      );

      TenantService.clearCache();
      final savedTenant = await TenantService.fetchTenantInfo(
        forceRefresh: true,
      );
      AuthSession().updateTenant(savedTenant);

      if (!mounted) return;
      TopNotification.show(
        message: 'Warna tema dan tampilan berhasil disimpan!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal menyimpan tampilan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildLogoPreview(Color themeColor) {
    if (_logoUrl.trim().isNotEmpty) {
      final provider = _buildTenantLogoProvider(_logoUrl);
      if (provider != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image(
            image: provider,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Icon(
              Icons.storefront_rounded,
              color: themeColor,
              size: 28,
            ),
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
    final activeThemeColor = _parseColor(_selectedColor);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tampilan & Tema'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LIVE PREVIEW HEADER
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
                                    _tenantName.isEmpty
                                        ? 'Nama Kantin Anda'
                                        : _tenantName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'Jam buka: ${_openingHours.isNotEmpty ? _openingHours : "08:00 - 22:00"}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_address.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            _address,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // COLOR PICKER CARD
                      Container(
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
                                    color: activeThemeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.palette_rounded,
                                    color: activeThemeColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Warna Identitas Brand',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Warna ini diterapkan pada tombol, badge promo, dan aksen website menu pelanggan.',
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

                            const Text(
                              'Pilihan Preset Warna Populer:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                      horizontal: 14,
                                      vertical: 10,
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
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: preset['color'] as Color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
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

                            // Custom Color Hex Field
                            TextFormField(
                              controller: _colorCtrl,
                              decoration: InputDecoration(
                                labelText: 'Kode Warna Hex Custom',
                                hintText: '#00AA13',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: activeThemeColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                                helperText:
                                    'Anda dapat mengetikkan kode warna HEX apa saja sesuai brand toko.',
                              ),
                              onChanged: (val) {
                                if (val.startsWith('#') &&
                                    (val.length == 7 || val.length == 9)) {
                                  setState(() {
                                    _selectedColor = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 28),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeThemeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _isSaving ? null : _saveAppearance,
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
                                            'Simpan Warna Tema',
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
            ),
    );
  }
}
