import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/cashier_shift_report_model.dart';
import 'cashier_shift_service.dart';

class CashierShiftDialog extends StatefulWidget {
  const CashierShiftDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const CashierShiftDialog(),
    );
  }

  @override
  State<CashierShiftDialog> createState() => _CashierShiftDialogState();
}

class _CashierShiftDialogState extends State<CashierShiftDialog> {
  final CashierShiftService _service = CashierShiftService();
  final TextEditingController _cashCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  CurrentShiftData? _data;
  double _enteredCash = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _cashCtrl.addListener(_onCashChanged);
  }

  @override
  void dispose() {
    _cashCtrl.removeListener(_onCashChanged);
    _cashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onCashChanged() {
    final text = _cashCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      _enteredCash = double.tryParse(text) ?? 0.0;
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await _service.fetchCurrentShift();
      if (!mounted) return;
      setState(() {
        _data = res;
        _loading = false;
        // Default autofill with expected cash for convenience
        if (_cashCtrl.text.isEmpty && res.totalCashExpected > 0) {
          _cashCtrl.text = res.totalCashExpected.toInt().toString();
          _enteredCash = res.totalCashExpected;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      TopNotification.show(
        message: 'Gagal memuat data penjualan berjalan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  Future<void> _submitReport() async {
    if (_enteredCash < 0) {
      TopNotification.show(
        message: 'Masukkan jumlah uang kasir yang valid',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('Konfirmasi Laporan Uang', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Kirimkan laporan uang masuk sebesar ${CurrencyFormatter.rupiah(_enteredCash)} kepada Admin / Manajer untuk diverifikasi (ACC)?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Ya, Kirim Laporan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await _service.submitShiftReport(
        cashReceived: _enteredCash,
        notes: _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      TopNotification.show(
        message: 'Laporan uang shift berhasil dikirim! Menunggu ACC Admin/Manajer.',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
      _cashCtrl.clear();
      _notesCtrl.clear();
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal mengirim laporan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24, vertical: 24),
      child: Container(
        width: isCompact ? double.infinity : 540,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Laporan Penjualan Shift',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'Akumulasi penjualan waktu buka berjalan',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scrollable Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_data?.pendingReport != null)
                            _buildPendingBanner(_data!.pendingReport!),

                          _buildAccumulationCard(_data!),
                          const SizedBox(height: 16),

                          _buildHandoverForm(),
                          const SizedBox(height: 16),

                          if (_data != null && _data!.recentReports.isNotEmpty)
                            _buildRecentReportsList(_data!.recentReports),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Kembali'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(_submitting ? 'Mengirim...' : 'Kirim Laporan Kas'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPendingBanner(CashierShiftReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laporan Terakhir Menunggu ACC',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                ),
                Text(
                  'Setoran Rp ${CurrencyFormatter.rupiah(report.cashReceived)} sedang menunggu persetujuan Admin/Manajer.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccumulationCard(CurrentShiftData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: data.isStoreOpen ? const Color(0xFF16A34A) : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    data.isStoreOpen ? 'Toko Buka (Shift Berjalan)' : 'Toko Tutup',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: data.isStoreOpen ? const Color(0xFF16A34A) : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Text(
                '${data.totalOrders} Pesanan Masuk',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Uang Tunai (Cash)',
                  CurrencyFormatter.rupiah(data.totalCashExpected),
                  '${data.cashOrdersCount} order',
                  const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricItem(
                  'Uang QRIS / Digital',
                  CurrencyFormatter.rupiah(data.totalQrisExpected),
                  '${data.qrisOrdersCount} order',
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Akumulasi Uang Masuk:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                ),
                Text(
                  CurrencyFormatter.rupiah(data.totalSalesExpected),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                ),
              ],
            ),
          ),
          if (data.unpaidOrdersCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'ℹ️ Ada ${data.unpaidOrdersCount} pesanan belum bayar (${CurrencyFormatter.rupiah(data.unpaidAmount)}) yang belum terhitung ke uang masuk.',
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          Text(sub, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildHandoverForm() {
    final expectedCash = _data?.totalCashExpected ?? 0.0;
    final difference = _enteredCash - expectedCash;

    Color diffColor;
    String diffLabel;
    IconData diffIcon;

    if (difference.abs() < 1) {
      diffColor = const Color(0xFF16A34A);
      diffLabel = 'Pas (Sesuai uang tunai sistem)';
      diffIcon = Icons.check_circle_rounded;
    } else if (difference > 0) {
      diffColor = const Color(0xFF0284C7);
      diffLabel = 'Kelebihan ${CurrencyFormatter.rupiah(difference)}';
      diffIcon = Icons.arrow_upward_rounded;
    } else {
      diffColor = const Color(0xFFDC2626);
      diffLabel = 'Selisih Kurang ${CurrencyFormatter.rupiah(difference.abs())}';
      diffIcon = Icons.warning_amber_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Uang Fisik Kasir',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _cashCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Uang Fisik Diterima Kasir (Tunai) *',
            hintText: 'Contoh: 150000',
            prefixText: 'Rp ',
            prefixIcon: const Icon(Icons.money_rounded, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),

        // Live Difference Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: diffColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: diffColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(diffIcon, size: 16, color: diffColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selisih: $diffLabel',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: diffColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        TextFormField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Catatan Kasir (Opsional)',
            hintText: 'Misal: Modal awal kasir Rp 50.000 sudah dipisahkan',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReportsList(List<CashierShiftReportModel> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Laporan Kasir Terakhir',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        ...reports.take(3).map((r) {
          Color badgeColor;
          String badgeText;
          if (r.isApproved) {
            badgeColor = const Color(0xFF16A34A);
            badgeText = 'DI-ACC';
          } else if (r.isRejected) {
            badgeColor = const Color(0xFFDC2626);
            badgeText = 'DITOLAK';
          } else {
            badgeColor = const Color(0xFFD97706);
            badgeText = 'PENDING ACC';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setoran: ${CurrencyFormatter.rupiah(r.cashReceived)} (${r.totalOrders} order)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Kasir: ${r.cashierName ?? "Kasir"} • ${r.createdAt != null ? "${r.createdAt!.hour.toString().padLeft(2, '0')}:${r.createdAt!.minute.toString().padLeft(2, '0')}" : ""}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
