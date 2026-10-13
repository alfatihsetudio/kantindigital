import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/stock_check_model.dart';
import '../../../shared/models/stock_item_model.dart';
import '../../admin/widgets/admin_drawer.dart';
import '../../cashier/stock_check/stock_service.dart';

class AdminStockReportPage extends StatefulWidget {
  const AdminStockReportPage({super.key});

  @override
  State<AdminStockReportPage> createState() => _AdminStockReportPageState();
}

class _AdminStockReportPageState extends State<AdminStockReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StockService _service = StockService();

  // Snapshot stok terkini
  StockCheckModel? _latestClosing;
  List<StockItemModel> _masterItems = [];
  bool _snapshotLoading = true;
  final TextEditingController _snapshotSearchCtrl = TextEditingController();

  // Riwayat opname
  List<StockCheckModel> _history = [];
  bool _historyLoading = true;
  String _selectedFilter = 'all'; // all, closing, opening, diff

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSnapshot();
    _loadHistory();
    _snapshotSearchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _snapshotSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSnapshot() async {
    setState(() => _snapshotLoading = true);
    try {
      final closing = await _service.getLatestClosing();
      final items = await _service.getStockItems(activeOnly: false);
      if (mounted) {
        setState(() {
          _latestClosing = closing;
          _masterItems = items;
          _snapshotLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _snapshotLoading = false);
        TopNotification.show(
          message: 'Gagal memuat posisi stok terkini: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final type = (_selectedFilter == 'closing' || _selectedFilter == 'opening')
          ? _selectedFilter
          : null;
      final data = await _service.getStockChecks(type: type);
      if (mounted) {
        setState(() {
          if (_selectedFilter == 'diff') {
            _history = data.where((c) => c.hasDifference).toList();
          } else {
            _history = data;
          }
          _historyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _historyLoading = false);
        TopNotification.show(
          message: 'Gagal memuat riwayat opname: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _showDetailModal(StockCheckModel check) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            final isClosing = check.isClosing;
            final hasDiff = check.hasDifference;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isClosing
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isClosing ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                            color: isClosing ? const Color(0xFF2563EB) : const Color(0xFF059669),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isClosing ? 'Laporan Tutup Usaha (Closing)' : 'Laporan Buka Toko (Opening)',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Tanggal: ${check.checkDate} • Petugas: ${check.userName ?? "Kasir"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasDiff ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasDiff ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Text(
                            hasDiff ? 'Ada Selisih' : 'Semua Sesuai',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: hasDiff ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (check.notes != null && check.notes!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        'Catatan Petugas: ${check.notes}',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: check.items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final item = check.items[idx];
                        final unit = item.unit;
                        final whole = item.wholeQuantity.truncateToDouble() == item.wholeQuantity
                            ? item.wholeQuantity.toStringAsFixed(0)
                            : item.wholeQuantity.toStringAsFixed(2);
                        final rem = item.remainderQuantity.truncateToDouble() == item.remainderQuantity
                            ? item.remainderQuantity.toStringAsFixed(0)
                            : item.remainderQuantity.toStringAsFixed(2);

                        final prevWhole = item.previousWholeQuantity != null
                            ? (item.previousWholeQuantity!.truncateToDouble() == item.previousWholeQuantity
                                ? item.previousWholeQuantity!.toStringAsFixed(0)
                                : item.previousWholeQuantity!.toStringAsFixed(2))
                            : null;
                        final prevRem = item.previousRemainderQuantity != null
                            ? (item.previousRemainderQuantity!.truncateToDouble() == item.previousRemainderQuantity
                                ? item.previousRemainderQuantity!.toStringAsFixed(0)
                                : item.previousRemainderQuantity!.toStringAsFixed(2))
                            : null;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: item.isMatched ? Colors.grey.shade50 : const Color(0xFFFEF2F2).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.isMatched ? Colors.grey.shade200 : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (!isClosing)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.isMatched ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.isMatched ? 'Sesuai ✓' : 'Selisih !',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: item.isMatched ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Info stok pembanding
                              if (!isClosing && (prevWhole != null || prevRem != null))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'Catatan Kemarin: Utuh $prevWhole pcs | Sisa $prevRem $unit',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      'Fisik Utuh: $whole pcs',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Fisik Sisa: $rem $unit',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  if (!isClosing && item.differenceRemainder.abs() > 0.001) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Selisih: ${item.differenceRemainder > 0 ? "+" : ""}${item.differenceRemainder} $unit',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Keterangan: ${item.notes}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Laporan Stok & Opname',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Pantau sisa bahan toko dan rekap selisih fisik harian',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory_2_rounded, size: 20),
              text: 'Posisi Stok Terkini',
            ),
            Tab(
              icon: Icon(Icons.history_rounded, size: 20),
              text: 'Riwayat Opname Harian',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSnapshotView(),
          _buildHistoryView(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: POSISI STOK TERKINI
  // ==========================================
  Widget _buildSnapshotView() {
    if (_snapshotLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final query = _snapshotSearchCtrl.text.trim().toLowerCase();

    // Map item yang ada di closing terakhir
    final latestItemsMap = <String, StockCheckItemModel>{};
    if (_latestClosing != null) {
      for (final ci in _latestClosing!.items) {
        latestItemsMap[ci.itemName.toLowerCase().trim()] = ci;
      }
    }

    final filteredMaster = _masterItems.where((i) {
      return i.name.toLowerCase().contains(query) ||
          i.unit.toLowerCase().contains(query) ||
          (i.category?.toLowerCase().contains(query) ?? false);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadSnapshot,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Ringkasan Penutupan Terakhir
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kondisi Stok Fisik Terakhir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _latestClosing != null
                              ? 'Berdasarkan catatan tutup toko tanggal ${_latestClosing!.checkDate} oleh ${_latestClosing!.userName ?? "Kasir"}'
                              : 'Belum ada catatan tutup toko dari kasir.',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Filter
            TextField(
              controller: _snapshotSearchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari bahan baku atau satuan...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _snapshotSearchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _snapshotSearchCtrl.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Daftar Bahan & Sisa Timbangan
            Text(
              'Rincian Stok Bahan (${filteredMaster.length} Bahan)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (filteredMaster.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text('Tidak ada bahan yang sesuai'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredMaster.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final mItem = filteredMaster[index];
                  final recorded = latestItemsMap[mItem.name.toLowerCase().trim()];

                  final whole = recorded != null
                      ? (recorded.wholeQuantity.truncateToDouble() == recorded.wholeQuantity
                          ? recorded.wholeQuantity.toStringAsFixed(0)
                          : recorded.wholeQuantity.toStringAsFixed(2))
                      : '-';

                  final rem = recorded != null
                      ? (recorded.remainderQuantity.truncateToDouble() == recorded.remainderQuantity
                          ? recorded.remainderQuantity.toStringAsFixed(0)
                          : recorded.remainderQuantity.toStringAsFixed(2))
                      : '-';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.scale_rounded, color: AppColors.primary, size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mItem.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kategori: ${mItem.category ?? "Bahan Baku"}',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Utuh: $whole pcs',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Sisa: $rem ${mItem.unit}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (recorded?.notes != null && recorded!.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Ket: ${recorded.notes}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: RIWAYAT OPNAME HARIAN
  // ==========================================
  Widget _buildHistoryView() {
    return Column(
      children: [
        // Filter row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua Laporan'),
                const SizedBox(width: 8),
                _buildFilterChip('closing', 'Tutup Usaha (Closing)'),
                const SizedBox(width: 8),
                _buildFilterChip('opening', 'Buka Toko (Opening)'),
                const SizedBox(width: 8),
                _buildFilterChip('diff', 'Hanya yang Ada Selisih ⚠️'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _historyLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada riwayat catatan stok pada filter ini',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _history.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          final isClosing = item.isClosing;
                          final hasDiff = item.hasDifference;

                          return InkWell(
                            onTap: () => _showDetailModal(item),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasDiff ? const Color(0xFFFECACA) : Colors.grey.shade200,
                                ),
                                boxShadow: AppTheme.shadowSm,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: isClosing
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isClosing ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                        color: isClosing ? const Color(0xFF2563EB) : const Color(0xFF059669),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              isClosing
                                                  ? 'Tutup Usaha (Closing)'
                                                  : 'Buka Toko (Opening)',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: hasDiff
                                                    ? const Color(0xFFFEF2F2)
                                                    : const Color(0xFFECFDF5),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                hasDiff ? 'Ada Selisih' : 'Sesuai',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: hasDiff
                                                      ? const Color(0xFFDC2626)
                                                      : const Color(0xFF059669),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.checkDate} • Dicatat oleh: ${item.userName ?? "Kasir"} • ${item.items.length} Bahan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = value);
        _loadHistory();
      },
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }
}
