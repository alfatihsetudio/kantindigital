import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/auth/auth_session.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/tenant_model.dart';
import '../../../shared/services/tenant_service.dart';
import '../../customer/menu/menu_service.dart';
import '../widgets/admin_drawer.dart';

class PromoSettingsPage extends StatefulWidget {
  const PromoSettingsPage({super.key});

  @override
  State<PromoSettingsPage> createState() => _PromoSettingsPageState();
}

class _PromoSettingsPageState extends State<PromoSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final _promoBadgeCtrl = TextEditingController();
  final _promoMessageCtrl = TextEditingController();
  final _promoDiscountCtrl = TextEditingController();
  final Set<int> _promoMenuIds = {};
  final Set<String> _promoPaymentMethods = {'qris'};
  List<MenuModel> _promoMenus = [];
  bool _promoAppliesToAll = true;
  bool _promoMenusLoading = true;
  String? _promoMenusError;
  String _voucherPromoMode = 'both';
  List<DeliveryDiscountTier> _deliveryDiscountTiers = [];

  String _tenantName = '';
  String _primaryColorHex = '#00AA13';

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  @override
  void dispose() {
    _promoBadgeCtrl.dispose();
    _promoMessageCtrl.dispose();
    _promoDiscountCtrl.dispose();
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

  Future<void> _loadTenantData() async {
    setState(() => _isLoading = true);
    try {
      final tenant = await TenantService.fetchTenantInfo(forceRefresh: true);
      _tenantName = tenant.name;
      _primaryColorHex = tenant.primaryColor;
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
      _voucherPromoMode = tenant.voucherPromoMode;
      _deliveryDiscountTiers =
          List<DeliveryDiscountTier>.from(tenant.deliveryDiscountTiers);

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
      debugPrint('Error loading promo settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePromo() async {
    if (!_formKey.currentState!.validate()) {
      TopNotification.show(
        message: 'Mohon periksa kolom yang bertanda merah.',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final client = ApiClient();
      final fields = <String, String>{
        'name': _tenantName.isNotEmpty ? _tenantName : 'Kantin',
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
        'voucher_promo_mode': _voucherPromoMode,
        'delivery_discount_tiers': jsonEncode(
          _deliveryDiscountTiers.map((t) => t.toJson()).toList(),
        ),
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
        message: 'Pengaturan promo dan diskon berhasil disimpan!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal menyimpan promo: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddDeliveryTierDialog() {
    final qtyCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Tambah Diskon Pengiriman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tentukan batas minimal pesanan (cup/item) dan potongan diskonnya:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimal Jumlah Cup / Item',
                hintText: 'Contoh: 3',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal Potongan Diskon (Rp)',
                hintText: 'Contoh: 5000',
                prefixIcon: Icon(Icons.money_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final minQty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;

              if (minQty <= 0) {
                TopNotification.show(
                  message: 'Minimal jumlah item harus lebih dari 0',
                  backgroundColor: AppColors.warning,
                  icon: Icons.warning_amber_rounded,
                );
                return;
              }
              if (amount <= 0) {
                TopNotification.show(
                  message: 'Nominal diskon harus lebih dari 0',
                  backgroundColor: AppColors.warning,
                  icon: Icons.warning_amber_rounded,
                );
                return;
              }

              setState(() {
                _deliveryDiscountTiers.removeWhere((t) => t.minQty == minQty);
                _deliveryDiscountTiers.add(
                  DeliveryDiscountTier(minQty: minQty, discountAmount: amount),
                );
                _deliveryDiscountTiers.sort(
                  (a, b) => a.minQty.compareTo(b.minQty),
                );
              });

              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDiscountTiersSettings() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diskon Pengiriman / Ongkir (Bertingkat)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF166534),
                      ),
                    ),
                    Text(
                      'Potongan otomatis berdasarkan total item di keranjang.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_deliveryDiscountTiers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Belum ada aturan diskon pengiriman. Tekan "+ Tambah Tingkat Diskon" di bawah.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...List.generate(_deliveryDiscountTiers.length, (index) {
              final tier = _deliveryDiscountTiers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Min. ${tier.minQty} Cup / Item',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Diskon ${CurrencyFormatter.rupiah(tier.discountAmount)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      tooltip: 'Hapus Tingkat Diskon',
                      onPressed: () {
                        setState(() {
                          _deliveryDiscountTiers.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showAddDeliveryTierDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Tingkat Diskon'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _parseColor(_primaryColorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Promo'),
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
                    child: Form(
                      key: _formKey,
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
                                  Icons.local_fire_department_rounded,
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
                                      'Promo di Halaman Menu Pelanggan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Banner dan aturan diskon yang tampil di halaman pemesanan pembeli.',
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

                          TextFormField(
                            controller: _promoBadgeCtrl,
                            maxLength: 60,
                            decoration: const InputDecoration(
                              labelText: 'Label Promo',
                              hintText: 'Contoh: Promo Hari Ini',
                              prefixIcon: Icon(
                                Icons.local_fire_department_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _promoMessageCtrl,
                            maxLength: 180,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Pesan Promo',
                              hintText:
                                  'Contoh: Diskon 10% Semua Varian Kopi Hari Ini!',
                              prefixIcon: Icon(Icons.campaign_rounded),
                              helperText:
                                  'Teks ini ditampilkan pada banner promo di halaman menu pelanggan.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _promoDiscountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Diskon Promo (%)',
                              hintText: 'Contoh: 10',
                              prefixIcon: Icon(Icons.percent_rounded),
                              helperText:
                                  'Isi 0 jika tidak ada diskon. Diskon berlaku otomatis saat pembayaran.',
                            ),
                            validator: (value) {
                              final percent =
                                  int.tryParse(value?.trim() ?? '');
                              if (percent == null ||
                                  percent < 0 ||
                                  percent > 100) {
                                return 'Masukkan persentase diskon antara 0 sampai 100.';
                              }
                              if (percent > 0 &&
                                  !_promoAppliesToAll &&
                                  _promoMenuIds.isEmpty) {
                                return 'Pilih minimal satu menu untuk promo varian tertentu.';
                              }
                              if (percent > 0 && _promoPaymentMethods.isEmpty) {
                                return 'Pilih minimal satu metode pembayaran untuk diskon.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Metode Pembayaran yang Mendapat Diskon:',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('QRIS'),
                            subtitle: const Text(
                              'Diskon muncul saat pelanggan memilih pembayaran QRIS.',
                            ),
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
                              'Centang jika pembayaran tunai juga mendapat diskon promo.',
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
                          const SizedBox(height: 8),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Berlaku untuk semua menu'),
                            subtitle: const Text(
                              'Matikan untuk memilih menu / varian tertentu saja.',
                            ),
                            value: _promoAppliesToAll,
                            onChanged: (value) =>
                                setState(() => _promoAppliesToAll = value),
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
                                constraints:
                                    const BoxConstraints(maxHeight: 240),
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
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          const Text(
                            'Kombinasi Potongan Voucher & Diskon Umum',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Atur apakah pelanggan yang memakai voucher kerjasama juga tetap mendapat diskon promo umum atau salah satunya.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...[
                            (
                              'both',
                              'Bisa Keduanya (Voucher + Diskon Umum)',
                              'Pelanggan mendapat diskon promo umum sekaligus potongan voucher.',
                            ),
                            (
                              'single',
                              'Salah Satu Saja (Voucher Menggantikan Diskon Umum)',
                              'Jika memakai voucher, diskon umum otomatis tidak berlaku pada pesanan tersebut.',
                            ),
                            (
                              'voucher_only',
                              'Hanya Voucher Saja',
                              'Hanya potongan kode voucher yang aktif (diskon promo dinonaktifkan).',
                            ),
                            (
                              'promo_only',
                              'Hanya Diskon Umum Saja',
                              'Hanya diskon promo umum yang aktif (input kode voucher disembunyikan).',
                            ),
                          ].map((opt) {
                            final isSelected = _voucherPromoMode == opt.$1;
                            return RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: opt.$1,
                              groupValue: _voucherPromoMode,
                              activeColor: AppColors.primary,
                              title: Text(
                                opt.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                opt.$3,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _voucherPromoMode = val);
                                }
                              },
                            );
                          }),
                          const SizedBox(height: 16),
                          _buildDeliveryDiscountTiersSettings(),
                          const SizedBox(height: 28),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isSaving ? null : _savePromo,
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
                                          'Simpan Pengaturan Promo',
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
            ),
    );
  }
}
