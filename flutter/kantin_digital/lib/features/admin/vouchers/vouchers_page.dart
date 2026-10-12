import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../shared/auth/auth_session.dart';
import '../../../shared/constants/user_role.dart';
import '../../../shared/services/voucher_service.dart';
import '../../manager/widgets/manager_drawer.dart';
import '../widgets/admin_drawer.dart';

class AdminVouchersPage extends StatefulWidget {
  const AdminVouchersPage({super.key});

  @override
  State<AdminVouchersPage> createState() => _AdminVouchersPageState();
}

class _AdminVouchersPageState extends State<AdminVouchersPage> {
  final VoucherService _service = VoucherService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String _statusFilter = 'ALL'; // ALL, UNUSED, USED, UNREPORTED, REPORTED
  String _partnerFilter = 'ALL';

  VoucherListResponse _data = VoucherListResponse.empty();
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    setState(() => _loading = true);
    String? apiStatus;
    String? apiReported;
    if (_statusFilter == 'UNUSED') apiStatus = 'unused';
    if (_statusFilter == 'USED') apiStatus = 'used';
    if (_statusFilter == 'UNREPORTED') {
      apiStatus = 'used';
      apiReported = 'unreported';
    }
    if (_statusFilter == 'REPORTED') {
      apiStatus = 'used';
      apiReported = 'reported';
    }

    final res = await _service.getVouchers(
      status: apiStatus,
      reported: apiReported,
      partner: _partnerFilter == 'ALL' ? null : _partnerFilter,
      search: _searchController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _data = res;
      _selectedIds.removeWhere((id) => !res.items.any((e) => e.id == id));
      _loading = false;
    });
  }

  Future<void> _showImportDialog() async {
    final partnerCtrl = TextEditingController(
      text: _partnerFilter != 'ALL' ? _partnerFilter : '',
    );
    final amountCtrl = TextEditingController(text: '15000');
    final codesCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool submitting = false;

    final imported = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final rawLines = codesCtrl.text
              .split(RegExp(r'[\r\n,;]+'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Data Kode Voucher',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Masukkan nomor voucher dari mitra kerjasama',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: partnerCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Mitra / Instansi Kerjasama *',
                        hintText: 'Contoh: PT Maju Bersama / Kampus ABC',
                        prefixIcon: const Icon(Icons.handshake_outlined, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Nominal Potongan per Voucher (Rp) *',
                        hintText: '15000',
                        prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [10000, 15000, 20000, 25000, 50000].map((val) {
                        return ActionChip(
                          label: Text(
                            CurrencyFormatter.rupiah(val),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setDialogState(() {
                              amountCtrl.text = val.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Nomor / Kode Voucher *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${rawLines.length} kode terdeteksi',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: codesCtrl,
                      minLines: 5,
                      maxLines: 10,
                      onChanged: (_) => setDialogState(() {}),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText:
                            'Tempel daftar nomor voucher di sini (pisahkan dengan baris baru atau koma).\nContoh:\nVCH-001\nVCH-002\nVCH-003',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tips: Anda bisa langsung copy-paste kolom nomor voucher dari Excel / WhatsApp. Bisa juga format KODE,NOMINAL per baris jika nominal berbeda.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        hintText: 'Contoh: Batch Oktober 2026',
                        prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton.icon(
                onPressed: submitting
                    ? null
                    : () async {
                        final partner = partnerCtrl.text.trim();
                        final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
                        final rawCodes = codesCtrl.text.trim();
                        if (partner.isEmpty) {
                          AppSnackBar.show(
                            context,
                            message: 'Nama mitra kerjasama wajib diisi',
                          );
                          return;
                        }
                        if (amount <= 0) {
                          AppSnackBar.show(
                            context,
                            message: 'Nominal voucher harus lebih dari 0',
                          );
                          return;
                        }
                        if (rawCodes.isEmpty) {
                          AppSnackBar.show(
                            context,
                            message: 'Masukkan minimal 1 kode voucher',
                          );
                          return;
                        }
                        setDialogState(() => submitting = true);
                        try {
                          final res = await _service.importVouchers(
                            partnerName: partner,
                            amount: amount,
                            codesRaw: rawCodes,
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx, true);
                          if (mounted) {
                            AppSnackBar.show(
                              context,
                              message:
                                  res['message']?.toString() ??
                                  'Voucher berhasil diimport',
                            );
                          }
                        } catch (e) {
                          setDialogState(() => submitting = false);
                          if (mounted) {
                            AppSnackBar.show(
                              context,
                              message: 'Gagal import: $e',
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: submitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_done_rounded, size: 18),
                label: Text(submitting ? 'Mengimport...' : 'Import Sekarang'),
              ),
            ],
          );
        },
      ),
    );

    if (imported == true) {
      _loadVouchers();
    }
  }

  Future<void> _markPartnerReported(String partnerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Tandai Sudah Dilaporkan?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Semua voucher terpakai milik mitra "$partnerName" yang belum dilaporkan akan ditandai sebagai SUDAH DILAPORKAN.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Tandai Dilaporkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final count = await _service.markReported(
        partnerName: partnerName,
        isReported: true,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: '$count voucher mitra $partnerName ditandai sudah dilaporkan.',
      );
      _loadVouchers();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Gagal memperbarui status laporan: $e');
    }
  }

  Future<void> _copyPartnerReport(VoucherPartnerSummary summary) async {
    final usedItems = _data.items
        .where(
          (v) =>
              v.isUsed &&
              (v.partnerName.isEmpty ? 'Tanpa Mitra' : v.partnerName) ==
                  summary.partnerName,
        )
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('LAPORAN PENGGUNAAN VOUCHER');
    buffer.writeln('Mitra: ${summary.partnerName}');
    buffer.writeln('Total Voucher Terpakai: ${summary.usedCount} lembar');
    buffer.writeln(
      'Total Nominal Terpakai: ${CurrencyFormatter.rupiah(summary.usedAmount)}',
    );
    buffer.writeln(
      'Belum Dilaporkan Sebelumnya: ${summary.unreportedCount} lembar (${CurrencyFormatter.rupiah(summary.unreportedAmount)})',
    );
    buffer.writeln('----------------------------------------');
    if (usedItems.isEmpty) {
      buffer.writeln('(Filter daftar di bawah untuk memuat detail rincian kode)');
    } else {
      for (var i = 0; i < usedItems.length; i++) {
        final v = usedItems[i];
        final statusLapor = v.isReported ? 'Sudah Lapor' : 'Belum Lapor';
        buffer.writeln(
          '${i + 1}. ${v.code} - ${CurrencyFormatter.rupiah(v.amount)} | Order: ${v.orderCode ?? '-'} | Pelanggan: ${v.usedByName ?? '-'} | Waktu: ${v.usedAt ?? '-'} [$statusLapor]',
        );
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    AppSnackBar.show(
      context,
      message:
          'Laporan voucher "${summary.partnerName}" berhasil disalin! Siap ditempel ke WhatsApp.',
    );
  }

  Future<void> _toggleItemReported(VoucherItemModel item) async {
    try {
      await _service.markReported(
        voucherIds: [item.id],
        isReported: !item.isReported,
      );
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: !item.isReported
            ? 'Voucher ${item.code} ditandai sudah dilaporkan.'
            : 'Status laporan voucher ${item.code} dibatalkan.',
      );
      _loadVouchers();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Gagal mengubah status laporan: $e');
    }
  }

  Future<void> _deleteSingleVoucher(VoucherItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Kode Voucher?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Hapus voucher "${item.code}" (${CurrencyFormatter.rupiah(item.amount)})?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteVoucher(item.id);
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Voucher ${item.code} dihapus.');
      _loadVouchers();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Gagal menghapus voucher: $e');
    }
  }

  Future<void> _bulkDeleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Voucher Terpilih?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Hapus ${_selectedIds.length} kode voucher yang dipilih secara permanen?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final deleted = await _service.bulkDeleteVouchers(
        voucherIds: _selectedIds.toList(),
      );
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      AppSnackBar.show(context, message: '$deleted voucher berhasil dihapus.');
      _loadVouchers();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Gagal menghapus voucher: $e');
    }
  }

  Future<void> _bulkMarkSelectedReported() async {
    if (_selectedIds.isEmpty) return;
    try {
      final count = await _service.markReported(
        voucherIds: _selectedIds.toList(),
        isReported: true,
      );
      if (!mounted) return;
      setState(() => _selectedIds.clear());
      AppSnackBar.show(
        context,
        message: '$count voucher ditandai sudah dilaporkan.',
      );
      _loadVouchers();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: 'Gagal menandai laporan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = AuthSession().role == UserRole.manager;
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isManager ? const ManagerDrawer() : const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voucher Kerjasama & Laporan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Import nomor voucher mitra & kelola laporan pemakaian',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadVouchers,
            tooltip: 'Muat Ulang',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _showImportDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 17),
              label: const Text(
                'Import Voucher',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVouchers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryGrid(),
              const SizedBox(height: 18),
              if (_data.partnerSummaries.isNotEmpty) ...[
                _buildPartnerSummariesSection(),
                const SizedBox(height: 18),
              ],
              _buildVoucherListSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final cards = [
          _buildStatCard(
            title: 'Total Kode Voucher',
            value: '${_data.totalVouchers}',
            subtitle: '${_data.unusedCount} belum dipakai',
            icon: Icons.confirmation_number_rounded,
            color: AppColors.primary,
          ),
          _buildStatCard(
            title: 'Sudah Dipakai',
            value: '${_data.usedCount} Voucher',
            subtitle: CurrencyFormatter.rupiah(_data.usedAmount),
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
          _buildStatCard(
            title: ' Perlu Dilaporkan ke Mitra',
            value: '${_data.unreportedUsedCount} Voucher',
            subtitle:
                'Tagihan: ${CurrencyFormatter.rupiah(_data.unreportedUsedAmount)}',
            icon: Icons.assignment_late_rounded,
            color: const Color(0xFFD97706),
          ),
        ];

        if (isWide) {
          return Row(
            children: cards
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: c,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Column(
          children: cards
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerSummariesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handshake_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rekap Laporan per Mitra Kerjasama',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Salin laporan pemakaian untuk dikirim ke pihak mitra kerjasama, lalu tandai sudah dilaporkan.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ..._data.partnerSummaries.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.partnerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: p.unreportedCount > 0
                              ? const Color(0xFFFEF3C7)
                              : AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.unreportedCount > 0
                              ? '${p.unreportedCount} Belum Lapor (${CurrencyFormatter.rupiah(p.unreportedAmount)})'
                              : 'Semua Sudah Dilaporkan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.unreportedCount > 0
                                ? const Color(0xFFB45309)
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      Text(
                        'Total Kuota: ${p.total}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Sisa: ${p.unusedCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Terpakai: ${p.usedCount} (${CurrencyFormatter.rupiah(p.usedAmount)})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _copyPartnerReport(p),
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text(
                          'Salin Laporan WA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      if (p.unreportedCount > 0)
                        ElevatedButton.icon(
                          onPressed: () => _markPartnerReported(p.partnerName),
                          icon: const Icon(
                            Icons.done_all_rounded,
                            size: 15,
                          ),
                          label: const Text(
                            'Tandai Sudah Dilaporkan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVoucherListSection() {
    final partners = ['ALL', ..._data.partners];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daftar Kode Voucher',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_selectedIds.isNotEmpty) ...[
                TextButton.icon(
                  onPressed: _bulkMarkSelectedReported,
                  icon: const Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  label: Text(
                    'Lapor (${_selectedIds.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _bulkDeleteSelected,
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  label: Text(
                    'Hapus (${_selectedIds.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Search + Partner Dropdown
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadVouchers(),
                  decoration: InputDecoration(
                    hintText: 'Cari kode voucher, nama pelanggan, order...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _loadVouchers();
                            },
                            icon: const Icon(Icons.clear_rounded, size: 16),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: partners.contains(_partnerFilter)
                      ? _partnerFilter
                      : 'ALL',
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  items: partners
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p == 'ALL' ? 'Semua Mitra' : p,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _partnerFilter = val ?? 'ALL');
                    _loadVouchers();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'Semua'),
                const SizedBox(width: 6),
                _buildFilterChip('UNUSED', 'Belum Dipakai'),
                const SizedBox(width: 6),
                _buildFilterChip('USED', 'Terpakai'),
                const SizedBox(width: 6),
                _buildFilterChip('UNREPORTED', 'Belum Dilaporkan'),
                const SizedBox(width: 6),
                _buildFilterChip('REPORTED', 'Sudah Dilaporkan'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_data.items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 42,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Belum ada data voucher untuk filter ini',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _showImportDialog,
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text('Import Kode Voucher Sekarang'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _data.items.map(_buildVoucherRow).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _statusFilter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      onSelected: (_) {
        setState(() => _statusFilter = key);
        _loadVouchers();
      },
    );
  }

  Widget _buildVoucherRow(VoucherItemModel item) {
    final isSelected = _selectedIds.contains(item.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryLight.withValues(alpha: 0.25)
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedIds.add(item.id);
                } else {
                  _selectedIds.remove(item.id);
                }
              });
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        item.code,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.rupiah(item.amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.isUsed
                            ? AppColors.successLight
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isUsed ? 'TERPAKAI' : 'BELUM DIPAKAI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: item.isUsed
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (item.isUsed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.isReported
                              ? AppColors.infoLight
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isReported
                              ? 'SUDAH DILAPORKAN'
                              : 'BELUM DILAPORKAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: item.isReported
                                ? AppColors.info
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Mitra: ${item.partnerName.isEmpty ? '-' : item.partnerName}${item.notes != null && item.notes!.isNotEmpty ? ' • ${item.notes}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.isUsed) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dipakai pada Order #${item.orderCode ?? '-'} oleh ${item.usedByName ?? '-'} (${item.usedByPhone ?? '-'}) • ${item.usedAt ?? ''}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isUsed)
                IconButton(
                  tooltip: item.isReported
                      ? 'Batalkan Status Dilaporkan'
                      : 'Tandai Sudah Dilaporkan',
                  onPressed: () => _toggleItemReported(item),
                  icon: Icon(
                    item.isReported
                        ? Icons.verified_rounded
                        : Icons.fact_check_outlined,
                    color: item.isReported
                        ? AppColors.info
                        : const Color(0xFFD97706),
                    size: 20,
                  ),
                ),
              IconButton(
                tooltip: 'Hapus Voucher',
                onPressed: () => _deleteSingleVoucher(item),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
