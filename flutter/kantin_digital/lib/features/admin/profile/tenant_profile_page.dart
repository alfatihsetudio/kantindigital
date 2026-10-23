import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/auth/auth_session.dart';
import '../../../shared/services/tenant_service.dart';
import '../../../shared/utils/store_opening_hours.dart';
import '../widgets/admin_drawer.dart';

class AdminTenantProfilePage extends StatefulWidget {
  const AdminTenantProfilePage({super.key});

  @override
  State<AdminTenantProfilePage> createState() => _AdminTenantProfilePageState();
}

class _AdminTenantProfilePageState extends State<AdminTenantProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _menuCodePrefixCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openingHoursCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _logoUrl = '';
  String _selectedColor = '#00AA13';

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _menuCodePrefixCtrl.dispose();
    _addressCtrl.dispose();
    _openingHoursCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
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
      _nameCtrl.text = tenant.name;
      _menuCodePrefixCtrl.text = tenant.menuCodePrefix ?? 'SAY';
      _logoUrl = tenant.logoUrl ?? '';
      _selectedColor = tenant.primaryColor;
      _addressCtrl.text = tenant.address ?? '';
      _openingHoursCtrl.text = tenant.openingHours.trim().isNotEmpty
          ? tenant.openingHours
          : 'Setiap hari, 08:00 - 22:00';
      _phoneCtrl.text = tenant.phone ?? '';
      _whatsappCtrl.text = tenant.whatsapp ?? '';
    } catch (e) {
      debugPrint('Error loading tenant: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TimeOfDay? _parseTimeOfDay(String? text) {
    if (text == null) return null;
    final clean = text.replaceAll('.', ':').trim();
    final parts = clean.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDailyOpeningHours() async {
    final currentRange = RegExp(
      r'(\d{1,2}[:.]\d{2})\s*[-–]\s*(\d{1,2}[:.]\d{2})',
    ).firstMatch(_openingHoursCtrl.text);
    final openingTime =
        _parseTimeOfDay(currentRange?.group(1)) ??
        const TimeOfDay(hour: 10, minute: 0);
    final closingTime =
        _parseTimeOfDay(currentRange?.group(2)) ??
        const TimeOfDay(hour: 21, minute: 0);

    final initialOpenDays =
        StoreOpeningHours.getOpenDays(_openingHoursCtrl.text);

    final result = await showDialog<dynamic>(
      context: context,
      builder: (ctx) {
        final dialogOpenDays = Set<int>.from(initialOpenDays);
        TimeOfDay dialogOpen = openingTime;
        TimeOfDay dialogClose = closingTime;

        final todayWeekday =
            DateTime.now().toUtc().add(const Duration(hours: 7)).weekday;

        const dayList = [
          (1, 'Senin'),
          (2, 'Selasa'),
          (3, 'Rabu'),
          (4, 'Kamis'),
          (5, 'Jumat'),
          (6, 'Sabtu'),
          (7, 'Minggu'),
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            final previewStr = StoreOpeningHours.formatScheduleFromOpenDays(
              openDays: dialogOpenDays,
              openTime: _formatTimeOfDay(dialogOpen),
              closeTime: _formatTimeOfDay(dialogClose),
            );

            final isTodayOpen = dialogOpenDays.contains(todayWeekday);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Atur Hari Buka & Hari Libur',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih status tiap hari (Tap untuk ubah Buka / Libur):',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dayList.map((d) {
                          final dayNum = d.$1;
                          final dayName = d.$2;
                          final isOpen = dialogOpenDays.contains(dayNum);
                          final isToday = dayNum == todayWeekday;

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setModalState(() {
                                if (isOpen) {
                                  if (dialogOpenDays.length > 1) {
                                    dialogOpenDays.remove(dayNum);
                                  } else {
                                    TopNotification.show(
                                      message:
                                          'Minimal harus ada 1 hari buka toko!',
                                      backgroundColor: AppColors.warning,
                                      icon: Icons.info_outline_rounded,
                                    );
                                  }
                                } else {
                                  dialogOpenDays.add(dayNum);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isOpen
                                      ? AppColors.primary
                                      : Colors.red.shade200,
                                  width: isToday ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOpen
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 15,
                                    color: isOpen
                                        ? AppColors.primary
                                        : Colors.red.shade600,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    dayName + (isToday ? ' (Hari ini)' : ''),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isToday
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isOpen
                                          ? AppColors.primary
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'Jam Operasional (WIB):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: dialogOpen,
                                );
                                if (picked != null) {
                                  setModalState(() => dialogOpen = picked);
                                }
                              },
                              icon: const Icon(Icons.wb_sunny_outlined, size: 16),
                              label: Text('Buka: ${_formatTimeOfDay(dialogOpen)}'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: dialogClose,
                                );
                                if (picked != null) {
                                  setModalState(() => dialogClose = picked);
                                }
                              },
                              icon: const Icon(Icons.nightlight_outlined, size: 16),
                              label: Text('Tutup: ${_formatTimeOfDay(dialogClose)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTodayOpen
                              ? const Color(0xFFF0FDF4)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTodayOpen
                                ? const Color(0xFFBBF7D0)
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasil Jadwal: $previewStr',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isTodayOpen
                                  ? '✅ Toko Anda BUKA pada hari ini.'
                                  : '⛔ Toko Anda LIBUR / TUTUP pada hari ini.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isTodayOpen
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx, previewStr);
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result is String) {
      setState(() {
        _openingHoursCtrl.text = result;
      });
    }
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) {
      TopNotification.show(
        message: 'Mohon periksa kembali kolom yang belum valid bertanda merah.',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      final fields = <String, String>{
        'name': _nameCtrl.text.trim(),
        'menu_code_prefix': _menuCodePrefixCtrl.text.trim().toUpperCase(),
        'address': _addressCtrl.text.trim(),
        'opening_hours': _openingHoursCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
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
        message: 'Informasi usaha berhasil disimpan!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal menyimpan info usaha: $e',
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
          borderRadius: BorderRadius.circular(14),
          child: Image(
            image: provider,
            fit: BoxFit.cover,
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
        title: const Text('Info Usaha'),
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
                  child: Form(
                    key: _formKey,
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
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Jam buka: ${_openingHoursCtrl.text}',
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
                                    if (_addressCtrl.text.isNotEmpty) ...[
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
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // FORM CARD
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
                                      Icons.storefront_rounded,
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
                                          'Informasi Usaha & Kontak',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Identitas dasar brand, alamat, jam operasional, dan nomor WhatsApp toko.',
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
                              const SizedBox(height: 16),

                              // 2. PREFIX KODE MENU
                              TextFormField(
                                controller: _menuCodePrefixCtrl,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Prefix / Singkatan Kode Menu',
                                  hintText: 'Contoh: SAY (Hasil: SAY-01, SAY-02)',
                                  prefixIcon: Icon(Icons.tag_rounded),
                                  helperText:
                                      'Awalan kode unik menu di flyer & aplikasi agar pesanan tidak tertukar.',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 16),

                              // 3. WHATSAPP
                              TextFormField(
                                controller: _whatsappCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Nomor WhatsApp Konfirmasi',
                                  hintText: '628123456789 (format 62)',
                                  prefixIcon: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                  ),
                                  helperText:
                                      'Nomor WA ini akan dipakai konsumen saat menekan tombol "Konfirmasi Bukti Transfer via WhatsApp".',
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 4. TELEPON
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Nomor Telepon Toko (Opsional)',
                                  hintText: 'Contoh: 08123456789',
                                  prefixIcon: Icon(Icons.phone_outlined),
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
                              const SizedBox(height: 16),

                              // 6. JAM BUKA
                              TextFormField(
                                controller: _openingHoursCtrl,
                                maxLength: 255,
                                decoration: const InputDecoration(
                                  labelText: 'Jam buka toko (WIB)',
                                  hintText: 'Contoh: Setiap hari, 08:00 - 22:00',
                                  prefixIcon: Icon(Icons.access_time_rounded),
                                  helperText:
                                      'Gunakan WIB (Asia/Jakarta). Klik tombol di bawah untuk mengatur jam operasional toko.',
                                ),
                                validator: (value) =>
                                    StoreOpeningHours.isValid(value ?? '')
                                        ? null
                                        : 'Format jam tidak valid. Contoh: Setiap hari, 08:00 - 22:00',
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: _pickDailyOpeningHours,
                                  icon: const Icon(Icons.calendar_month_rounded),
                                  label: const Text(
                                    'Atur jam operasional & hari libur (WIB)',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

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
                                              'Simpan Info Usaha',
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
            ),
    );
  }
}
