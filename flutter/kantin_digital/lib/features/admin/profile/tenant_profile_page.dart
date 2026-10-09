import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/auth/auth_session.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/tenant_model.dart';
import '../../../shared/services/tenant_service.dart';
import '../../../shared/utils/store_opening_hours.dart';
import '../../customer/menu/menu_service.dart';
import '../widgets/admin_drawer.dart';

class AdminTenantProfilePage extends StatefulWidget {
  const AdminTenantProfilePage({super.key});

  @override
  State<AdminTenantProfilePage> createState() => _AdminTenantProfilePageState();
}

class _AdminTenantProfilePageState extends State<AdminTenantProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _infoSectionKey = GlobalKey();
  final _promoSectionKey = GlobalKey();
  final _logoSectionKey = GlobalKey();
  final _appearanceSectionKey = GlobalKey();
  final _socialPreviewSectionKey = GlobalKey();
  final _nameCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _openingHoursCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _metaTitleCtrl = TextEditingController();
  final _metaDescCtrl = TextEditingController();
  final _metaImageCtrl = TextEditingController();
  final _menuCodePrefixCtrl = TextEditingController();
  final _promoBadgeCtrl = TextEditingController();
  final _promoMessageCtrl = TextEditingController();
  final _promoDiscountCtrl = TextEditingController();
  final Set<int> _promoMenuIds = {};
  final Set<String> _promoPaymentMethods = {'qris'};
  List<MenuModel> _promoMenus = [];
  bool _promoAppliesToAll = true;
  bool _promoMenusLoading = true;
  String? _promoMenusError;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCompressing = false;
  bool _isCompressingMeta = false;
  bool _clearMetaImage = false;
  CompressedImageFile? _newLogo;
  CompressedImageFile? _newMetaImage;
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
    _scrollController.dispose();
    _nameCtrl.dispose();
    _logoCtrl.dispose();
    _colorCtrl.dispose();
    _addressCtrl.dispose();
    _openingHoursCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose();
    _metaImageCtrl.dispose();
    _menuCodePrefixCtrl.dispose();
    _promoBadgeCtrl.dispose();
    _promoMessageCtrl.dispose();
    _promoDiscountCtrl.dispose();
    super.dispose();
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _loadTenantData() async {
    setState(() => _isLoading = true);
    try {
      final tenant = await TenantService.fetchTenantInfo(forceRefresh: true);
      _nameCtrl.text = tenant.name;
      _menuCodePrefixCtrl.text = tenant.menuCodePrefix ?? 'SAY';
      _logoCtrl.text = tenant.logoUrl ?? '';
      _selectedColor = tenant.primaryColor;
      _colorCtrl.text = tenant.primaryColor;
      _addressCtrl.text = tenant.address ?? '';
      _openingHoursCtrl.text = tenant.openingHours.trim().isNotEmpty
          ? tenant.openingHours
          : 'Setiap hari, 08:00 - 22:00';
      _phoneCtrl.text = tenant.phone ?? '';
      _whatsappCtrl.text = tenant.whatsapp ?? '';
      _metaTitleCtrl.text = tenant.metaTitle ?? '';
      _metaDescCtrl.text = tenant.metaDescription ?? '';
      _metaImageCtrl.text = tenant.metaImageUrl ?? '';
      _clearMetaImage = false;
      _promoBadgeCtrl.text = tenant.promoBadgeText;
      _promoMessageCtrl.text = tenant.promoMessage;
      _promoDiscountCtrl.text = tenant.promoDiscountPercent.toString();
      _promoAppliesToAll = tenant.promoScope != 'selected';
      _promoMenuIds
        ..clear()
        ..addAll(tenant.promoMenuIds);
      _promoPaymentMethods
        ..clear()
        ..addAll(
          tenant.promoPaymentMethods.isEmpty
              ? const ['qris']
              : tenant.promoPaymentMethods,
        );
      try {
        _promoMenus = await MenuService(
          ApiClient(),
        ).fetchMenus(includeUnavailable: true);
        _promoMenusError = null;
      } catch (e) {
        _promoMenusError = e.toString();
      }
      _promoMenusLoading = false;
    } catch (e) {
      debugPrint('Error loading tenant: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Grid 7 Hari
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dayList.map((entry) {
                          final dayNum = entry.$1;
                          final dayName = entry.$2;
                          final isOpen = dialogOpenDays.contains(dayNum);
                          final isToday = dayNum == todayWeekday;

                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                if (isOpen) {
                                  dialogOpenDays.remove(dayNum);
                                } else {
                                  dialogOpenDays.add(dayNum);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 96,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOpen
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  width: isToday ? 2.0 : 1.2,
                                ),
                                boxShadow: [
                                  if (isToday)
                                    BoxShadow(
                                      color: (isOpen
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444))
                                          .withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isToday) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'HARI INI',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Text(
                                    dayName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isOpen
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF991B1B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isOpen
                                            ? Icons.check_circle_rounded
                                            : Icons.do_not_disturb_on_rounded,
                                        size: 14,
                                        color: isOpen
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOpen ? 'BUKA' : 'LIBUR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isOpen
                                              ? const Color(0xFF047857)
                                              : const Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // Shortcut buttons
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            avatar: Icon(
                              isTodayOpen
                                  ? Icons.event_busy_rounded
                                  : Icons.event_available_rounded,
                              size: 15,
                              color: isTodayOpen
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                            ),
                            label: Text(
                              isTodayOpen
                                  ? 'Libur Hari Ini (Dadakan)'
                                  : 'Buka Kembali Hari Ini',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isTodayOpen
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                            onPressed: () {
                              setModalState(() {
                                if (isTodayOpen) {
                                  dialogOpenDays.remove(todayWeekday);
                                } else {
                                  dialogOpenDays.add(todayWeekday);
                                }
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text(
                              'Buka Semua Hari',
                              style: TextStyle(fontSize: 11.5),
                            ),
                            onPressed: () {
                              setModalState(() {
                                dialogOpenDays.addAll([1, 2, 3, 4, 5, 6, 7]);
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text(
                              'Libur Minggu',
                              style: TextStyle(fontSize: 11.5),
                            ),
                            onPressed: () {
                              setModalState(() {
                                dialogOpenDays
                                  ..clear()
                                  ..addAll([1, 2, 3, 4, 5, 6]);
                              });
                            },
                          ),
                          ActionChip(
                            label: const Text(
                              'Libur Sabtu & Minggu',
                              style: TextStyle(fontSize: 11.5),
                            ),
                            onPressed: () {
                              setModalState(() {
                                dialogOpenDays
                                  ..clear()
                                  ..addAll([1, 2, 3, 4, 5]);
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      const Text(
                        'Jam Operasional (WIB):',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await _showWibTimePicker(
                                  title: 'Pilih jam buka (WIB)',
                                  initialTime: dialogOpen,
                                );
                                if (picked != null) {
                                  setModalState(() => dialogOpen = picked);
                                }
                              },
                              icon: const Icon(Icons.wb_sunny_outlined, size: 16),
                              label: Text(
                                'Buka: ${_formatTimeOfDay(dialogOpen)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await _showWibTimePicker(
                                  title: 'Pilih jam tutup (WIB)',
                                  initialTime: dialogClose,
                                );
                                if (picked != null) {
                                  setModalState(() => dialogClose = picked);
                                }
                              },
                              icon: const Icon(
                                Icons.nightlight_outlined,
                                size: 16,
                              ),
                              label: Text(
                                'Tutup: ${_formatTimeOfDay(dialogClose)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Hasil Jadwal:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${dialogOpenDays.length} Hari Buka • ${7 - dialogOpenDays.length} Libur',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              previewStr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
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
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, {
                    'schedule': previewStr,
                    'saveNow': false,
                  }),
                  child: const Text('Terapkan ke Form'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, {
                    'schedule': previewStr,
                    'saveNow': true,
                  }),
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Terapkan & Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      String schedule = '';
      bool saveNow = false;
      if (result is Map) {
        schedule = (result['schedule'] ?? '').toString().trim();
        saveNow = result['saveNow'] == true;
      } else {
        schedule = result.toString().trim();
      }

      if (schedule.isNotEmpty) {
        setState(() {
          _openingHoursCtrl.text = schedule;
        });

        if (saveNow) {
          await _saveOpeningHoursDirectly(schedule);
        } else {
          TopNotification.show(
            message:
                'Jadwal berhasil diterapkan di form: "$schedule". Klik "Simpan Profil Kantin" di bawah untuk menyimpan perubahan.',
            backgroundColor: AppColors.primary,
            icon: Icons.check_circle_rounded,
          );
        }
      }
    }
  }

  Future<void> _saveOpeningHoursDirectly(String schedule) async {
    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      final response = await client.post(
        '/tenant/opening-hours',
        body: {'opening_hours': schedule},
      );

      final savedOpeningHours =
          response?['data']?['opening_hours']?.toString() ?? schedule;
      if (savedOpeningHours.trim().isNotEmpty) {
        _openingHoursCtrl.text = savedOpeningHours.trim();
      } else {
        _openingHoursCtrl.text = schedule;
      }

      TenantService.clearCache();
      final savedTenant = await TenantService.fetchTenantInfo(
        forceRefresh: true,
      );
      AuthSession().updateTenant(savedTenant);
      if (savedTenant.openingHours.trim().isNotEmpty) {
        _openingHoursCtrl.text = savedTenant.openingHours.trim();
      }

      if (!mounted) return;
      TopNotification.show(
        message: 'Jadwal operasional & hari libur berhasil disimpan!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      final err = e.toString();
      if (err.contains('404')) {
        await _saveTenant();
        return;
      }
      TopNotification.show(
        message: 'Gagal menyimpan hari libur: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<TimeOfDay?> _showWibTimePicker({
    required String title,
    required TimeOfDay initialTime,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: title,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll('.', ':').trim();
    final parts = normalized.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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
      if (mounted) {
        try {
          TopNotification.show(
            message: 'Gagal memilih gambar: $e',
            backgroundColor: AppColors.danger,
            icon: Icons.error_rounded,
          );
        } catch (_) {}
      }
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
        'promo_badge_text': _promoBadgeCtrl.text.trim(),
        'promo_message': _promoMessageCtrl.text.trim(),
        'promo_discount_percent': _promoDiscountCtrl.text.trim().isEmpty
            ? '0'
            : _promoDiscountCtrl.text.trim(),
        'promo_scope': _promoAppliesToAll ? 'all' : 'selected',
        'promo_menu_ids': jsonEncode(
          _promoAppliesToAll ? <int>[] : _promoMenuIds.toList(),
        ),
        'promo_payment_methods': jsonEncode(_promoPaymentMethods.toList()),
        'primary_color': _selectedColor,
        'address': _addressCtrl.text.trim(),
        'opening_hours': _openingHoursCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'meta_title': _metaTitleCtrl.text.trim(),
        'meta_description': _metaDescCtrl.text.trim(),
      };

      if (_newLogo == null) {
        fields['logo_url'] = _logoCtrl.text.trim();
      }

      if (_clearMetaImage) {
        fields['meta_image_url'] = '';
      } else if (_newMetaImage == null) {
        fields['meta_image_url'] = _metaImageCtrl.text.trim();
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

      if (response?['data']?['promo_discount_percent'] != null) {
        _promoDiscountCtrl.text = response!['data']['promo_discount_percent']
            .toString();
      }

      final savedOpeningHours = response?['data']?['opening_hours']?.toString();
      if (savedOpeningHours != null) {
        _openingHoursCtrl.text = savedOpeningHours;
      }

      // Update URL dari server jika baru diupload
      if (response != null && response['data'] != null) {
        if (response['data']['logo_url'] != null) {
          _logoCtrl.text = response['data']['logo_url'].toString();
          _newLogo = null;
        }
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

      // Clear cache agar data baru diambil kembali
      TenantService.clearCache();
      final savedTenant = await TenantService.fetchTenantInfo(
        forceRefresh: true,
      );
      AuthSession().updateTenant(savedTenant);
      _openingHoursCtrl.text =
          (savedOpeningHours != null && savedOpeningHours.isNotEmpty)
              ? savedOpeningHours
              : savedTenant.openingHours;

      if (!mounted) return;
      try {
        TopNotification.show(
          message: 'Profil kantin, logo, promo, & meta data berhasil disimpan!',
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profil kantin, logo, promo, & meta data berhasil disimpan!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString();
      final isAuthError =
          errorStr.contains('401') ||
          errorStr.toLowerCase().contains('unauthenticated') ||
          errorStr.toLowerCase().contains('unauthorized');

      TopNotification.show(
        message: isAuthError
            ? 'Anda belum login atau sesi telah berakhir. Silakan login terlebih dahulu sebagai Admin.'
            : 'Gagal menyimpan: $e',
        backgroundColor: AppColors.danger,
        icon: isAuthError ? Icons.lock_outline_rounded : Icons.error_rounded,
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

  Widget _buildPromoDiscountSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextFormField(
          controller: _promoDiscountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Diskon promo (%)',
            hintText: 'Contoh: 10',
            prefixIcon: Icon(Icons.percent_rounded),
            helperText:
                'Isi 0 jika tidak ada diskon. Diskon berlaku otomatis saat pembayaran.',
          ),
          validator: (value) {
            final percent = int.tryParse(value?.trim() ?? '');
            if (percent == null || percent < 0 || percent > 100) {
              return 'Masukkan persentase diskon antara 0 sampai 100.';
            }
            if (percent > 0 && !_promoAppliesToAll && _promoMenuIds.isEmpty) {
              return 'Pilih minimal satu menu untuk promo varian tertentu.';
            }
            if (percent > 0 && _promoPaymentMethods.isEmpty) {
              return 'Pilih minimal satu metode pembayaran untuk mendapat diskon.';
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        const Text(
          'Metode pembayaran yang mendapat diskon',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('QRIS'),
          subtitle: const Text('Diskon muncul saat pelanggan memilih QRIS.'),
          value: _promoPaymentMethods.contains('qris'),
          onChanged: (selected) => setState(() {
            if (selected == true) {
              _promoPaymentMethods.add('qris');
            } else {
              _promoPaymentMethods.remove('qris');
            }
          }),
        ),
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Tunai'),
          subtitle: const Text(
            'Centang jika pembayaran tunai juga mendapat diskon.',
          ),
          value: _promoPaymentMethods.contains('cash'),
          onChanged: (selected) => setState(() {
            if (selected == true) {
              _promoPaymentMethods.add('cash');
            } else {
              _promoPaymentMethods.remove('cash');
            }
          }),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Berlaku untuk semua menu'),
          subtitle: const Text('Matikan untuk memilih menu/varian tertentu.'),
          value: _promoAppliesToAll,
          onChanged: (value) => setState(() => _promoAppliesToAll = value),
        ),
        if (!_promoAppliesToAll) ...[
          const SizedBox(height: 4),
          if (_promoMenusLoading)
            const Center(child: CircularProgressIndicator())
          else if (_promoMenusError != null)
            Text(
              'Daftar menu gagal dimuat: $_promoMenusError',
              style: const TextStyle(color: AppColors.danger),
            )
          else if (_promoMenus.isEmpty)
            const Text('Belum ada menu yang bisa dipilih.')
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView(
                shrinkWrap: true,
                children: _promoMenus.map((menu) {
                  return CheckboxListTile(
                    dense: true,
                    title: Text(menu.name),
                    subtitle: Text(menu.categoryName),
                    value: _promoMenuIds.contains(menu.id),
                    onChanged: (selected) => setState(() {
                      if (selected == true) {
                        _promoMenuIds.add(menu.id);
                      } else {
                        _promoMenuIds.remove(menu.id);
                      }
                    }),
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
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
      final imageProvider = tenantLogoImageProvider(_logoCtrl.text);
      if (imageProvider == null) {
        return Icon(
          Icons.storefront_rounded,
          color: activeThemeColor,
          size: 26,
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.storefront_rounded, color: activeThemeColor, size: 26),
        ),
      );
    }

    return Icon(Icons.storefront_rounded, color: activeThemeColor, size: 26);
  }

  Widget _buildMetaImagePreview(Color activeThemeColor) {
    if (_newMetaImage != null) {
      try {
        return Image.memory(
          _newMetaImage!.bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildLogoPreview(activeThemeColor),
        );
      } catch (_) {}
    }

    if (!_clearMetaImage && _metaImageCtrl.text.isNotEmpty) {
      final imageProvider = tenantLogoImageProvider(_metaImageCtrl.text);
      if (imageProvider != null) {
        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildLogoPreview(activeThemeColor),
        );
      }
    }

    return _buildLogoPreview(activeThemeColor);
  }

  Widget _buildProfileSubMenu(Color activeThemeColor) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SubMenuButton(
              icon: Icons.storefront_rounded,
              label: 'Info Usaha',
              color: activeThemeColor,
              onTap: () => _scrollToSection(_infoSectionKey),
            ),
            _SubMenuButton(
              icon: Icons.local_fire_department_rounded,
              label: 'Promo',
              color: activeThemeColor,
              onTap: () => _scrollToSection(_promoSectionKey),
            ),
            _SubMenuButton(
              icon: Icons.image_rounded,
              label: 'Logo',
              color: activeThemeColor,
              onTap: () => _scrollToSection(_logoSectionKey),
            ),
            _SubMenuButton(
              icon: Icons.palette_rounded,
              label: 'Tampilan',
              color: activeThemeColor,
              onTap: () => _scrollToSection(_appearanceSectionKey),
            ),
            _SubMenuButton(
              icon: Icons.share_rounded,
              label: 'Preview Link',
              color: activeThemeColor,
              onTap: () => _scrollToSection(_socialPreviewSectionKey),
            ),
          ],
        ),
      ),
    );
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
              controller: _scrollController,
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

                    const SizedBox(height: 24),
                    _buildProfileSubMenu(activeThemeColor),
                    const SizedBox(height: 16),

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
                          KeyedSubtree(
                            key: _infoSectionKey,
                            child: const Text(
                              'Informasi Usaha & Tampilan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
                          const SizedBox(height: 16),

                          // 1.1 KODE PREFIX MENU
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
                          const SizedBox(height: 20),

                          KeyedSubtree(
                            key: _promoSectionKey,
                            child: const Text(
                              'Promo di Halaman Menu Pelanggan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _promoBadgeCtrl,
                            maxLength: 60,
                            decoration: const InputDecoration(
                              labelText: 'Label promo',
                              hintText: 'Contoh: Promo Hari Ini',
                              prefixIcon: Icon(
                                Icons.local_fire_department_rounded,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _promoMessageCtrl,
                            maxLength: 180,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Pesan promo',
                              hintText:
                                  'Contoh: Pesan Sekarang, Nikmati Kemudahannya!',
                              prefixIcon: Icon(Icons.campaign_rounded),
                              helperText:
                                  'Teks ini ditampilkan pada banner promo di halaman pelanggan.',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          _buildPromoDiscountSettings(),
                          const SizedBox(height: 20),

                          // 2. UPLOAD LOGO KANTIN
                          KeyedSubtree(
                            key: _logoSectionKey,
                            child: const Text(
                              'Logo Kantin (Upload & Kompres Otomatis)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
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
                          KeyedSubtree(
                            key: _appearanceSectionKey,
                            child: const Text(
                              'Warna Identitas Brand',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _openingHoursCtrl,
                            maxLength: 255,
                            decoration: const InputDecoration(
                              labelText: 'Jam buka toko (WIB)',
                              hintText: 'Contoh: Setiap hari, 08:00 - 22:00',
                              prefixIcon: Icon(Icons.access_time_rounded),
                              helperText:
                                  'Gunakan WIB (Asia/Jakarta). Klik tombol di bawah untuk mengatur jam buka & hari libur toko.',
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
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          // 6. PREVIEW LINK SOSIAL MEDIA (META TAGS)
                          KeyedSubtree(
                            key: _socialPreviewSectionKey,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: activeThemeColor.withValues(
                                      alpha: 0.12,
                                    ),
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
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: activeThemeColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                left: Radius.circular(10),
                                              ),
                                        ),
                                        child: _buildMetaImagePreview(
                                          activeThemeColor,
                                        ),
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
                                                    : (_addressCtrl
                                                              .text
                                                              .isNotEmpty
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

                          // 6a. Upload Gambar Preview Link (Meta Image / OG Image)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 18,
                                      color: activeThemeColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Gambar Preview Link (Meta Image)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
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
                                              color: activeThemeColor,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Mengompres...',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: activeThemeColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Gambar thumbnail yang tampil saat link website dibagikan ke WhatsApp, Facebook, dsb. Gambar akan otomatis dikompres ke resolusi optimal (~1200px) agar sangat ringan dan cepat dibuka.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Thumbnail preview
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: activeThemeColor.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: _buildMetaImagePreview(
                                          activeThemeColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      activeThemeColor,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
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
                                                      : 'Upload & Kompres Gambar',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (_newMetaImage != null ||
                                                  (!_clearMetaImage &&
                                                      _metaImageCtrl
                                                          .text
                                                          .isNotEmpty))
                                                OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.red.shade700,
                                                    side: BorderSide(
                                                      color:
                                                          Colors.red.shade200,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 10,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed:
                                                      _resetMetaImageToDefault,
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Gunakan Logo Saja',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _newMetaImage != null
                                                ? '✨ Gambar baru siap disimpan (terkompresi optimal).'
                                                : ((!_clearMetaImage &&
                                                          _metaImageCtrl
                                                              .text
                                                              .isNotEmpty)
                                                      ? '✅ Menggunakan gambar preview khusus.'
                                                      : 'ℹ️ Belum ada gambar khusus (otomatis memakai logo kantin).'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: _newMetaImage != null
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade600,
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
                          const SizedBox(height: 16),

                          // 6b. Judul Preview Link (Meta Title)
                          TextFormField(
                            controller: _metaTitleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Judul Preview Link (Meta Title)',
                              hintText:
                                  'Contoh: SAY COFFEE - Ngopi Santai & Nikmat',
                              prefixIcon: Icon(Icons.title_rounded),
                              helperText:
                                  'Judul link saat dibagikan. Kosongkan jika ingin sama dengan Nama Kantin.',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),

                          // 6c. Deskripsi Preview Link (Meta Description)
                          TextFormField(
                            controller: _metaDescCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText:
                                  'Deskripsi Preview Link (Meta Description)',
                              hintText:
                                  'Contoh: Pesan berbagai macam varian kopi susu aren, teh segar, dan camilan nikmat langsung dari smartphone Anda.',
                              prefixIcon: Icon(Icons.description_outlined),
                              helperText:
                                  'Teks deskripsi ringkasan yang muncul di bawah judul saat link dibagikan.',
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

class _SubMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SubMenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.28)),
          backgroundColor: color.withValues(alpha: 0.06),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
