import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/top_notification.dart';
import '../../../../shared/models/stock_check_model.dart';
import '../stock_service.dart';

class OpeningStockView extends StatefulWidget {
  final StockService service;
  final VoidCallback onSaved;

  const OpeningStockView({
    super.key,
    required this.service,
    required this.onSaved,
  });

  @override
  State<OpeningStockView> createState() => _OpeningStockViewState();
}

class _OpeningItemHolder {
  final int? stockItemId;
  final String itemName;
  final String unit;
  final double prevWhole;
  final double prevRemainder;
  final TextEditingController wholeController;
  final TextEditingController remainderController;
  final TextEditingController notesController;

  _OpeningItemHolder({
    this.stockItemId,
    required this.itemName,
    required this.unit,
    required this.prevWhole,
    required this.prevRemainder,
    required this.wholeController,
    required this.remainderController,
    required this.notesController,
  });

  double get currentWhole => double.tryParse(wholeController.text.trim()) ?? 0.0;
  double get currentRemainder => double.tryParse(remainderController.text.trim()) ?? 0.0;

  double get diffWhole => currentWhole - prevWhole;
  double get diffRemainder => currentRemainder - prevRemainder;

  bool get isMatched => (diffWhole.abs() < 0.001) && (diffRemainder.abs() < 0.001);

  void dispose() {
    wholeController.dispose();
    remainderController.dispose();
    notesController.dispose();
  }
}

class _OpeningStockViewState extends State<OpeningStockView> {
  StockCheckModel? _latestClosing;
  List<_OpeningItemHolder> _holders = [];
  final _overallNotesController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadLatestClosing();
  }

  @override
  void dispose() {
    for (final holder in _holders) {
      holder.dispose();
    }
    _overallNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestClosing() async {
    setState(() => _loading = true);
    try {
      final closing = await widget.service.getLatestClosing();
      for (final h in _holders) {
        h.dispose();
      }

      if (closing != null) {
        _latestClosing = closing;
        _holders = closing.items.map((item) {
          final wholeStr = item.wholeQuantity.truncateToDouble() == item.wholeQuantity
              ? item.wholeQuantity.toStringAsFixed(0)
              : item.wholeQuantity.toStringAsFixed(2);
          final remStr = item.remainderQuantity.truncateToDouble() == item.remainderQuantity
              ? item.remainderQuantity.toStringAsFixed(0)
              : item.remainderQuantity.toStringAsFixed(2);

          // Default kasir terisi sama dengan kemarin (tinggal verifikasi atau ubah jika beda)
          final wholeCtrl = TextEditingController(text: wholeStr);
          final remCtrl = TextEditingController(text: remStr);
          final notesCtrl = TextEditingController();

          wholeCtrl.addListener(() {
            if (mounted) setState(() {});
          });
          remCtrl.addListener(() {
            if (mounted) setState(() {});
          });

          return _OpeningItemHolder(
            stockItemId: item.stockItemId,
            itemName: item.itemName,
            unit: item.unit,
            prevWhole: item.wholeQuantity,
            prevRemainder: item.remainderQuantity,
            wholeController: wholeCtrl,
            remainderController: remCtrl,
            notesController: notesCtrl,
          );
        }).toList();
      } else {
        // Belum ada closing, ambil dari stock items master
        final items = await widget.service.getStockItems(activeOnly: true);
        _holders = items.map((item) {
          final wholeCtrl = TextEditingController(text: '0');
          final remCtrl = TextEditingController(text: '0');
          final notesCtrl = TextEditingController();

          wholeCtrl.addListener(() {
            if (mounted) setState(() {});
          });
          remCtrl.addListener(() {
            if (mounted) setState(() {});
          });

          return _OpeningItemHolder(
            stockItemId: item.id,
            itemName: item.name,
            unit: item.unit,
            prevWhole: 0,
            prevRemainder: 0,
            wholeController: wholeCtrl,
            remainderController: remCtrl,
            notesController: notesCtrl,
          );
        }).toList();
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        TopNotification.show(
          message: 'Gagal memuat catatan closing kemarin: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  void _matchAllWithYesterday() {
    for (final holder in _holders) {
      final wholeStr = holder.prevWhole.truncateToDouble() == holder.prevWhole
          ? holder.prevWhole.toStringAsFixed(0)
          : holder.prevWhole.toStringAsFixed(2);
      final remStr = holder.prevRemainder.truncateToDouble() == holder.prevRemainder
          ? holder.prevRemainder.toStringAsFixed(0)
          : holder.prevRemainder.toStringAsFixed(2);

      holder.wholeController.text = wholeStr;
      holder.remainderController.text = remStr;
    }
    setState(() {});
    TopNotification.show(
      message: 'Semua stok fisik disesuaikan sama dengan catatan kemarin',
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  Future<void> _submitOpening() async {
    if (_holders.isEmpty) {
      TopNotification.show(
        message: 'Tidak ada item yang dapat diperiksa.',
        backgroundColor: AppColors.warning,
        icon: Icons.warning_rounded,
      );
      return;
    }

    final hasDiscrepancy = _holders.any((h) => !h.isMatched);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              hasDiscrepancy ? Icons.warning_amber_rounded : Icons.verified_rounded,
              color: hasDiscrepancy ? Colors.orange : AppColors.primary,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(hasDiscrepancy ? 'Ada Selisih Stok' : 'Simpan Buka Toko?'),
          ],
        ),
        content: Text(
          hasDiscrepancy
              ? 'Terdapat perbedaan antara stok fisik saat ini dengan catatan kemarin. Apakah Anda yakin ingin menyimpan hasil pemeriksaan ini?'
              : 'Semua stok fisik terverifikasi sesuai dengan catatan tutup toko kemarin. Simpan hasil pemeriksaan buka toko?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasDiscrepancy ? Colors.orange : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      final itemsPayload = _holders.map((holder) {
        return {
          if (holder.stockItemId != null) 'stock_item_id': holder.stockItemId,
          'item_name': holder.itemName,
          'unit': holder.unit,
          'whole_quantity': holder.currentWhole,
          'remainder_quantity': holder.currentRemainder,
          'previous_whole_quantity': holder.prevWhole,
          'previous_remainder_quantity': holder.prevRemainder,
          'is_matched': holder.isMatched,
          'difference_whole': holder.diffWhole,
          'difference_remainder': holder.diffRemainder,
          'notes': holder.notesController.text.trim().isNotEmpty
              ? holder.notesController.text.trim()
              : null,
        };
      }).toList();

      await widget.service.saveStockCheck(
        checkType: 'opening',
        notes: _overallNotesController.text.trim().isNotEmpty
            ? _overallNotesController.text.trim()
            : null,
        items: itemsPayload,
      );

      if (!mounted) return;
      setState(() => _saving = false);

      TopNotification.show(
        message: hasDiscrepancy
            ? 'Pemeriksaan buka toko disimpan dengan catatan selisih'
            : 'Pemeriksaan buka toko berhasil! Semua stok sesuai.',
        backgroundColor: hasDiscrepancy ? AppColors.warning : AppColors.success,
        icon: hasDiscrepancy ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
      );

      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      TopNotification.show(
        message: 'Gagal menyimpan pemeriksaan: $e',
        backgroundColor: AppColors.danger,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final matchedCount = _holders.where((h) => h.isMatched).length;
    final totalCount = _holders.length;
    final allMatched = totalCount > 0 && matchedCount == totalCount;

    return RefreshIndicator(
      onRefresh: _loadLatestClosing,
      color: AppColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Buka Toko
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF047857),
                    Color(0xFF10B981),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pemeriksaan Stok Buka Toko (Opening)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _latestClosing != null
                              ? 'Bandingkan stok fisik saat buka dengan catatan closing kemarin (${_latestClosing!.checkDate} oleh ${_latestClosing!.userName ?? "Kasir"}).'
                              : 'Periksa dan pastikan stok fisik sebelum toko mulai menerima pesanan hari ini.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: allMatched
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: allMatched
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    allMatched
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: allMatched ? const Color(0xFF059669) : const Color(0xFFD97706),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allMatched
                              ? 'Semua Stok Sesuai ($matchedCount/$totalCount Item Cocok)'
                              : '$matchedCount dari $totalCount Item Sesuai (Ada Perbedaan)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: allMatched
                                ? const Color(0xFF065F46)
                                : const Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          allMatched
                              ? 'Tidak ada selisih antara stok buka & catatan kemarin.'
                              : 'Periksa fisik barang atau cantumkan keterangan pada item yang berselisih.',
                          style: TextStyle(
                            fontSize: 11,
                            color: allMatched
                                ? const Color(0xFF047857)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_latestClosing != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                      ),
                      onPressed: _matchAllWithYesterday,
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: const Text('Semua Sesuai', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Item Comparison List
            Text(
              'Perbandingan Stok Fisik Pagi Ini vs Catatan Kemarin',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (_holders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text('Tidak ada item yang dapat diperiksa'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _holders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final holder = _holders[index];
                  final unit = holder.unit;
                  final isMatched = holder.isMatched;

                  final prevWholeText = holder.prevWhole.truncateToDouble() == holder.prevWhole
                      ? holder.prevWhole.toStringAsFixed(0)
                      : holder.prevWhole.toStringAsFixed(2);
                  final prevRemText = holder.prevRemainder.truncateToDouble() == holder.prevRemainder
                      ? holder.prevRemainder.toStringAsFixed(0)
                      : holder.prevRemainder.toStringAsFixed(2);

                  final diffW = holder.diffWhole;
                  final diffR = holder.diffRemainder;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMatched
                            ? Colors.grey.shade200
                            : const Color(0xFFFCA5A5),
                        width: isMatched ? 1 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isMatched
                              ? Colors.black.withValues(alpha: 0.02)
                              : Colors.red.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row Nama & Status Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isMatched
                                    ? AppColors.primaryLight
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isMatched
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                                color: isMatched
                                    ? AppColors.primary
                                    : AppColors.danger,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    holder.itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Satuan: $unit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Badge Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isMatched
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isMatched
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFFECACA),
                                ),
                              ),
                              child: Text(
                                isMatched ? 'Sesuai ✓' : 'Selisih !',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isMatched
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Info Stok Kemarin vs Input Stok Fisik Sekarang
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.history_rounded, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Catatan Kemarin: Utuh: $prevWholeText | Sisa: $prevRemText $unit',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              // Tombol quick copy kemarin
                              InkWell(
                                onTap: () {
                                  holder.wholeController.text = prevWholeText;
                                  holder.remainderController.text = prevRemText;
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    'Cocokkan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Input Stok Fisik Sekarang
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fisik Utuh
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fisik Utuh Sekarang',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: holder.wholeController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      suffixText: 'pcs',
                                      suffixStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                  if (diffW.abs() > 0.001)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Selisih: ${diffW > 0 ? "+$diffW" : "$diffW"}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: diffW < 0 ? AppColors.danger : Colors.green,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Fisik Sisa / Gram
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fisik Sisa ($unit)',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: holder.remainderController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      suffixText: unit,
                                      suffixStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                  if (diffR.abs() > 0.001)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Selisih: ${diffR > 0 ? "+$diffR" : "$diffR"} $unit',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: diffR < 0 ? AppColors.danger : Colors.green,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Jika ada selisih, munculkan kolom keterangan selisih
                        if (!isMatched) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: holder.notesController,
                            decoration: InputDecoration(
                              hintText: 'Keterangan selisih (misal: gula tumpah / dipakai tester)',
                              hintStyle: TextStyle(fontSize: 11, color: Colors.red.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFFECACA)),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFEF2F2),
                              isDense: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            // Catatan Pemeriksaan Buka Toko
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan Pemeriksaan Buka Toko (Opsional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _overallNotesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Misal: Kondisi toko aman dan bersih, semua bahan siap dipakai',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Simpan Opening
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: allMatched ? const Color(0xFF059669) : Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: _saving ? null : _submitOpening,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_rounded),
                label: Text(
                  _saving ? 'Menyimpan Pemeriksaan...' : (allMatched ? 'Simpan Pemeriksaan (Semua Sesuai)' : 'Simpan Pemeriksaan (Ada Selisih)'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
