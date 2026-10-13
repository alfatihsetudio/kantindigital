import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/top_notification.dart';
import '../../../../shared/models/stock_check_model.dart';
import '../stock_service.dart';

class StockHistoryView extends StatefulWidget {
  final StockService service;

  const StockHistoryView({
    super.key,
    required this.service,
  });

  @override
  State<StockHistoryView> createState() => _StockHistoryViewState();
}

class _StockHistoryViewState extends State<StockHistoryView> {
  List<StockCheckModel> _history = [];
  bool _loading = true;
  String _selectedFilter = 'all'; // all, closing, opening

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final type = _selectedFilter == 'all' ? null : _selectedFilter;
      final data = await widget.service.getStockChecks(type: type);
      if (mounted) {
        setState(() {
          _history = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        TopNotification.show(
          message: 'Gagal memuat riwayat stok: $e',
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
          initialChildSize: 0.8,
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
                            color: isClosing ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isClosing ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                            color: isClosing ? const Color(0xFF2563EB) : const Color(0xFF059669),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isClosing ? 'Rincian Stok Tutup Usaha' : 'Rincian Stok Buka Toko',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${DateFormatter.formatFriendly(check.createdAt ?? check.checkDate)} • Dicatat oleh ${check.userName ?? "Kasir"}',
                                style: TextStyle(
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
                        'Catatan: ${check.notes}',
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

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (!isClosing)
                                    Text(
                                      item.isMatched ? 'Cocok ✓' : 'Beda !',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: item.isMatched ? Colors.green : Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      'Utuh: $whole pcs',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Sisa: $rem $unit',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Keterangan: ${item.notes}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
    return Column(
      children: [
        // Filter tabs (Semua, Tutup Usaha, Buka Toko)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              _buildFilterChip('all', 'Semua Riwayat'),
              const SizedBox(width: 8),
              _buildFilterChip('closing', 'Tutup Usaha'),
              const SizedBox(width: 8),
              _buildFilterChip('opening', 'Buka Toko'),
            ],
          ),
        ),

        // History List
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada catatan riwayat stok',
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _history.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          final isClosing = item.isClosing;
                          final hasDiff = item.hasDifference;

                          return InkWell(
                            onTap: () => _showDetailModal(item),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasDiff ? const Color(0xFFFECACA) : Colors.grey.shade200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isClosing
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isClosing
                                            ? Icons.nightlight_round
                                            : Icons.wb_sunny_rounded,
                                        color: isClosing
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF059669),
                                        size: 22,
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
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
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
                                          '${DateFormatter.formatFriendly(item.createdAt ?? item.checkDate)} • ${item.items.length} item • Oleh: ${item.userName ?? "Kasir"}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.grey,
                                  ),
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
