import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/cashier_shift_report_model.dart';
import '../../cashier/shift/cashier_shift_service.dart';
import '../widgets/admin_drawer.dart';

class AdminCashierReportsPage extends StatefulWidget {
  const AdminCashierReportsPage({super.key});

  @override
  State<AdminCashierReportsPage> createState() => _AdminCashierReportsPageState();
}

class _AdminCashierReportsPageState extends State<AdminCashierReportsPage>
    with SingleTickerProviderStateMixin {
  final CashierShiftService _service = CashierShiftService();
  late TabController _tabController;

  bool _loading = true;
  List<CashierShiftReportModel> _allReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final reports = await _service.fetchReports(limit: 50);
      if (!mounted) return;
      setState(() {
        _allReports = reports;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      TopNotification.show(
        message: 'Gagal memuat laporan kasir: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  List<CashierShiftReportModel> get _pendingReports =>
      _allReports.where((r) => r.isPending).toList();

  List<CashierShiftReportModel> get _completedReports =>
      _allReports.where((r) => !r.isPending).toList();

  Future<void> _handleApprove(CashierShiftReportModel report) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 26),
            SizedBox(width: 10),
            Text('ACC Setoran Kasir?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setujui penerimaan uang setoran sebesar ${CurrencyFormatter.rupiah(report.cashReceived)} dari ${report.cashierName ?? "Kasir"}?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan Persetujuan (Opsional)',
                hintText: 'Misal: Uang fisik sudah diterima di brankas',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui (ACC)'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.approveReport(report.id, notes: noteCtrl.text.trim());
      await _loadReports();
      if (!mounted) return;
      TopNotification.show(
        message: 'Laporan setoran kasir berhasil di-ACC!',
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal menyetujui laporan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  Future<void> _handleReject(CashierShiftReportModel report) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 26),
            SizedBox(width: 10),
            Text('Tolak Setoran Kasir?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pesanan akan dikembalikan ke status belum dilaporkan agar kasir dapat menghitung dan melapor ulang.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan *',
                hintText: 'Misal: Jumlah uang fisik kurang Rp 20.000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak Setoran'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.rejectReport(report.id, notes: noteCtrl.text.trim());
      await _loadReports();
      if (!mounted) return;
      TopNotification.show(
        message: 'Laporan kasir ditolak & transaksi dikembalikan untuk dilaporkan ulang.',
        backgroundColor: AppColors.warning,
        icon: Icons.info_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      TopNotification.show(
        message: 'Gagal menolak laporan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingReports.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ACC Laporan Uang Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Menunggu ACC'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Riwayat Setoran'),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportList(_pendingReports, isPendingTab: true),
                _buildReportList(_completedReports, isPendingTab: false),
              ],
            ),
    );
  }

  Widget _buildReportList(List<CashierShiftReportModel> reports, {required bool isPendingTab}) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPendingTab ? Icons.check_circle_outline_rounded : Icons.history_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isPendingTab
                  ? 'Tidak ada setoran kasir yang menunggu ACC'
                  : 'Belum ada riwayat setoran kasir',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(report, isPendingTab: isPendingTab);
      },
    );
  }

  Widget _buildReportCard(CashierShiftReportModel report, {required bool isPendingTab}) {
    Color statusColor;
    String statusText;
    if (report.isApproved) {
      statusColor = const Color(0xFF16A34A);
      statusText = 'DI-ACC';
    } else if (report.isRejected) {
      statusColor = const Color(0xFFDC2626);
      statusText = 'DITOLAK';
    } else {
      statusColor = const Color(0xFFD97706);
      statusText = 'MENUNGGU ACC';
    }

    final diff = report.cashDifference;
    Color diffColor = const Color(0xFF16A34A);
    String diffText = 'Pas (Sesuai)';
    if (diff > 0) {
      diffColor = const Color(0xFF0284C7);
      diffText = 'Lebih ${CurrencyFormatter.rupiah(diff)}';
    } else if (diff < 0) {
      diffColor = const Color(0xFFDC2626);
      diffText = 'Kurang ${CurrencyFormatter.rupiah(diff.abs())}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: report.isPending ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
          width: report.isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Kasir & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      report.cashierName ?? 'Kasir',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Shift: ${report.shiftOpenedAt != null ? _formatDateTime(report.shiftOpenedAt!) : "-"} s/d ${report.shiftClosedAt != null ? _formatDateTime(report.shiftClosedAt!) : "-"}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Divider(height: 20),

            // Financial details grid
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Uang Kasir Disetor',
                    CurrencyFormatter.rupiah(report.cashReceived),
                    isBold: true,
                    valColor: const Color(0xFF0F172A),
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Tunai Sistem',
                    CurrencyFormatter.rupiah(report.totalCashExpected),
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Selisih Kas',
                    diffText,
                    valColor: diffColor,
                    isBold: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QRIS: ${CurrencyFormatter.rupiah(report.totalQrisExpected)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B21A8), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Total Omzet: ${CurrencyFormatter.rupiah(report.totalSalesExpected)} (${report.totalOrders} order)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            if (report.cashierNotes != null && report.cashierNotes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '📝 Catatan Kasir: "${report.cashierNotes}"',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
              ),
            ],

            if (report.approverName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Diperiksa oleh: ${report.approverName} ${report.approvedAt != null ? "pada ${_formatDateTime(report.approvedAt!)}" : ""}${report.approvalNotes != null ? " (${report.approvalNotes})" : ""}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],

            // Action Buttons for Pending
            if (isPendingTab) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleReject(report),
                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                      label: const Text('Tolak Setoran', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleApprove(report),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('ACC Setoran', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isBold = false, Color? valColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }
}
