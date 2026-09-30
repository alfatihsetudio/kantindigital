import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/loading_view.dart';
import '../widgets/admin_drawer.dart';
import 'qris_setting_controller.dart';

class QrisSettingPage extends StatefulWidget {
  const QrisSettingPage({super.key});

  @override
  State<QrisSettingPage> createState() => _QrisSettingPageState();
}

class _QrisSettingPageState extends State<QrisSettingPage> {
  final _controller = QrisSettingController();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _waCtrl;
  late TextEditingController _payloadCtrl;

  bool _isActive = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _waCtrl = TextEditingController();
    _payloadCtrl = TextEditingController();

    _payloadCtrl.addListener(() {
      setState(() {});
    });

    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _waCtrl.dispose();
    _payloadCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final setting = await _controller.fetchSetting();
      if (mounted) {
        _nameCtrl.text = setting.merchantName;
        _cityCtrl.text = setting.merchantCity;
        _waCtrl.text = setting.whatsappNumber;
        _payloadCtrl.text = setting.basePayload;
        _isActive = setting.isActive;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(
          context,
          message: 'Gagal memuat pengaturan QRIS: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_rounded,
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _controller.saveSetting(
        merchantName: _nameCtrl.text.trim(),
        merchantCity: _cityCtrl.text.trim(),
        whatsappNumber: _waCtrl.text.trim(),
        basePayload: _payloadCtrl.text.trim(),
        isActive: _isActive,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.show(
          context,
          message: 'Pengaturan QRIS berhasil disimpan ke database!',
          backgroundColor: const Color(0xFF059669),
          icon: Icons.check_circle_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.show(
          context,
          message: 'Gagal menyimpan: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan QRIS Merchant', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const LoadingView(message: 'Memuat data QRIS...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Form
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.shadowSm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFFDC2626), size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Konfigurasi QRIS Toko',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Data ini tersimpan di database MySQL dan digunakan untuk transaksi pelanggan.',
                                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 32),

                              // Merchant Name
                              const Text('Nama Merchant / Toko *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Contoh: KANTIN DIGITAL',
                                  prefixIcon: const Icon(Icons.storefront_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Nama merchant wajib diisi' : null,
                              ),
                              const SizedBox(height: 16),

                              // Merchant City
                              const Text('Kota Merchant *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _cityCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Contoh: SERANG / JAKARTA',
                                  prefixIcon: const Icon(Icons.location_city_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Kota merchant wajib diisi' : null,
                              ),
                              const SizedBox(height: 16),

                              // WhatsApp Admin Number
                              const Text('Nomor WhatsApp Admin (Konfirmasi Pelanggan) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _waCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Contoh: 087771262100',
                                  prefixIcon: const Icon(Icons.phone_android_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Nomor WhatsApp wajib diisi' : null,
                              ),
                              const SizedBox(height: 16),

                              // Base Payload
                              const Text('Base Payload QRIS (String Statis) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              const Text(
                                'Dapatkan string ini dengan melakukan scan pada gambar QRIS statis toko Anda (diawali 00020101...).',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _payloadCtrl,
                                maxLines: 4,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: '00020101021126610014COM.GO-JEK.WWW01189360091439141276340210G9141276340303UMI...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Base payload QRIS wajib diisi' : null,
                              ),
                              const SizedBox(height: 16),

                              // Switch Active
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Status Pembayaran QRIS Aktif', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: const Text('Aktifkan agar metode pembayaran QRIS muncul di menu checkout pelanggan', style: TextStyle(fontSize: 12)),
                                value: _isActive,
                                activeColor: AppColors.primary,
                                onChanged: (val) => setState(() => _isActive = val),
                              ),
                              const SizedBox(height: 24),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _save,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.save_rounded),
                                  label: Text(
                                    _isSaving ? 'Menyimpan ke Database...' : 'Simpan Pengaturan QRIS',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Live Preview Card
                        if (_payloadCtrl.text.trim().isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.shadowSm,
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Pratinjau QR Code QRIS Statis',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Merchant: ${_nameCtrl.text.trim().isEmpty ? 'KANTIN DIGITAL' : _nameCtrl.text.trim()} • ${_cityCtrl.text.trim().isEmpty ? 'SERANG' : _cityCtrl.text.trim()}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: QrImageView(
                                    data: _payloadCtrl.text.trim(),
                                    version: QrVersions.auto,
                                    size: 180,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  '✓ Kode QR ini valid dan siap dinamisasi otomatis saat checkout pelanggan.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
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
