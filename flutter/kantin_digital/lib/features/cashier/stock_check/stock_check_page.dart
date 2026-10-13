import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'stock_service.dart';
import 'widgets/closing_stock_view.dart';
import 'widgets/opening_stock_view.dart';
import 'widgets/stock_history_view.dart';
import 'widgets/stock_items_management_sheet.dart';

class CashierStockCheckPage extends StatefulWidget {
  final int initialTabIndex;

  const CashierStockCheckPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<CashierStockCheckPage> createState() => _CashierStockCheckPageState();
}

class _CashierStockCheckPageState extends State<CashierStockCheckPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StockService _service = StockService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSavedSuccess() {
    // Arahkan ke tab riwayat agar kasir langsung melihat catatan yang tersimpan
    setState(() {
      _tabController.animateTo(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Catatan Stok Kasir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Kontrol stok fisik saat buka & tutup usaha',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            tooltip: 'Kelola Master Bahan',
            onPressed: () => StockItemsManagementSheet.show(
              context,
              service: _service,
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.wb_sunny_rounded, size: 20),
              text: 'Buka Toko',
            ),
            Tab(
              icon: Icon(Icons.nightlight_round, size: 20),
              text: 'Tutup Usaha',
            ),
            Tab(
              icon: Icon(Icons.history_rounded, size: 20),
              text: 'Riwayat Log',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OpeningStockView(
            service: _service,
            onSaved: _onSavedSuccess,
          ),
          ClosingStockView(
            service: _service,
            onSaved: _onSavedSuccess,
          ),
          StockHistoryView(
            service: _service,
          ),
        ],
      ),
    );
  }
}
