import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../router/route_name.dart';
import '../../../shared/auth/auth_session.dart';
import '../../../shared/models/tenant_model.dart';
import '../../../shared/providers/tenant_provider.dart';
import '../../../shared/services/tenant_service.dart';
import '../../admin/widgets/admin_drawer.dart';
import '../../cashier/orders/orders_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  final ApiClient _client = ApiClient();
  final CashierOrdersService _ordersService = CashierOrdersService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Map<String, dynamic>? _salesStats;
  bool _salesLoading = true;
  List<CashierOrderModel> _orders = [];
  bool _ordersLoading = true;
  String _selectedOrderFilter = 'ALL'; // ALL, CANCELLED, UNPAID, PROCESSED

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _loadSalesStats();
    _loadOrders();
    _loadTenantInfo();
    _animationController.forward();
  }

  Future<void> _loadTenantInfo() async {
    try {
      await TenantService.fetchTenantInfo(forceRefresh: true);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _loadOrders() async {
    if (mounted) setState(() => _ordersLoading = true);
    try {
      final orders = await _ordersService.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _ordersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _ordersLoading = false);
    }
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _loadSalesStats() async {
    try {
      final response = await _client.get('/manager/stats');
      if (!mounted) return;
      setState(() {
        _salesStats = response['data'] as Map<String, dynamic>?;
        _salesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _salesLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession().user;
    final sessionTenant = AuthSession().tenant;
    final contextTenant = TenantProvider.of(context);
    final tenant = (sessionTenant != null &&
            sessionTenant.id != 0 &&
            sessionTenant.name.isNotEmpty)
        ? sessionTenant
        : contextTenant;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      body: Stack(
        children: [
          _buildBackgroundDecorations(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, tenant),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildWelcomeCard(
                            tenant.name,
                            user?.name ?? 'Owner',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildSalesReportSection(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildTransactionsSection(tenant.name),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: const Text(
                            'Menu Kelola Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                _buildQuickActionsGrid(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, TenantModel tenant) {
    final logoProvider = (tenant.logoUrl != null && tenant.logoUrl!.isNotEmpty)
        ? tenantLogoImageProvider(tenant.logoUrl!)
        : null;

    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logoProvider != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: logoProvider,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              tenant.name.isNotEmpty ? tenant.name : 'Dashboard',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Owner Mode',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(String storeName, String ownerName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '👋 Selamat Datang',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                storeName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Owner: $ownerName',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kelola usaha, pantau pemasukan, dan atur operasional dari satu tempat.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _ActionItem(
        title: 'Kelola Menu',
        subtitle: 'Tambah & Update',
        icon: Icons.restaurant_menu_rounded,
        color: const Color(0xFFFF7043), // Orange
        route: RouteName.adminMenus,
      ),
      _ActionItem(
        title: 'Kategori',
        subtitle: 'Atur Kategori',
        icon: Icons.category_rounded,
        color: const Color(0xFFBA68C8), // Purple
        route: RouteName.adminCategories,
      ),
      _ActionItem(
        title: 'Topping',
        subtitle: 'Varian Menu',
        icon: Icons.layers_rounded,
        color: const Color(0xFF4DB6AC), // Teal
        route: RouteName.adminToppings,
      ),
      _ActionItem(
        title: 'Meja & QR',
        subtitle: 'Generate Kode',
        icon: Icons.qr_code_2_rounded,
        color: const Color(0xFF5C6BC0), // Indigo
        route: RouteName.adminTables,
      ),
      _ActionItem(
        title: 'Pengguna',
        subtitle: 'Data Staff',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF42A5F5), // Blue
        route: RouteName.adminUsers,
      ),
      _ActionItem(
        title: 'Voucher Kerjasama',
        subtitle: 'Import & Laporan',
        icon: Icons.confirmation_number_rounded,
        color: const Color(0xFF10B981), // Emerald
        route: RouteName.adminVouchers,
      ),
      _ActionItem(
        title: 'Master Stok',
        subtitle: 'Bahan & Satuan',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFFD97706), // Amber
        route: RouteName.adminStockItems,
      ),
      _ActionItem(
        title: 'Laporan Stok',
        subtitle: 'Rekap & Selisih',
        icon: Icons.assessment_rounded,
        color: const Color(0xFF2563EB), // Blue Royal
        route: RouteName.adminStockReport,
      ),
      _ActionItem(
        title: 'Bonus Konsumen',
        subtitle: 'Loyalty & Klaim',
        icon: Icons.stars_rounded,
        color: const Color(0xFFF59E0B),
        route: RouteName.adminCustomerBonus,
      ),
    ];

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final action = actions[index];
          return _GlassActionCard(action: action, index: index);
        }, childCount: actions.length),
      ),
    );
  }

  Widget _buildSalesReportSection() {
    if (_salesLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.shadowSm,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _salesStats;
    if (stats == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Laporan penjualan belum bisa dimuat.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final summary = stats['summary'] as Map<String, dynamic>? ?? {};
    final dailySales =
        (stats['daily_sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final topMenus =
        (stats['top_menus'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final busiestDay = stats['busiest_day'] as Map<String, dynamic>? ?? {};

    final todayRevenue = _parseInt(summary['today_revenue']);
    final monthRevenue = _parseInt(summary['month_revenue']);
    final totalRevenue = _parseInt(summary['total_revenue']);
    final averageOrderValue = _parseInt(summary['average_order_value']);
    final topMenu = topMenus.isNotEmpty
        ? topMenus.first['menu_name']?.toString() ?? '-'
        : '-';
    final busyDay = busiestDay['day']?.toString() ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Penjualan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Pemasukan, grafik, produk, dan hari ramai',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: _loadSalesStats,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniReportCard(
                  title: 'Hari Ini',
                  value: CurrencyFormatter.rupiah(todayRevenue),
                  color: AppColors.primary,
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniReportCard(
                  title: 'Bulan Ini',
                  value: CurrencyFormatter.rupiah(monthRevenue),
                  color: const Color(0xFFFF9800),
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniReportCard(
                  title: 'Total',
                  value: CurrencyFormatter.rupiah(totalRevenue),
                  color: const Color(0xFF42A5F5),
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniReportCard(
                  title: 'Rata-rata',
                  value: CurrencyFormatter.rupiah(averageOrderValue),
                  color: const Color(0xFF26A69A),
                  icon: Icons.payments_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: 170, child: _buildSalesChart(dailySales)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InsightPill(
                  icon: Icons.emoji_events_rounded,
                  label: 'Produk terlaris',
                  value: topMenu,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightPill(
                  icon: Icons.query_stats_rounded,
                  label: 'Hari ramai',
                  value: busyDay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, RouteName.managerSales),
              icon: const Icon(Icons.bar_chart_rounded, size: 18),
              label: const Text('Lihat Laporan Lengkap'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<Map<String, dynamic>> dailySales) {
    if (dailySales.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data grafik',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final maxValue = dailySales
        .map((item) => _parseInt(item['total']).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue > 0 ? maxValue * 1.2 : 100000,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dailySales.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dailySales[index]['day']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(dailySales.length, (index) {
          final total = _parseInt(dailySales[index]['total']);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: total.toDouble(),
                width: 18,
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  List<CashierOrderModel> get _filteredOrders {
    switch (_selectedOrderFilter) {
      case 'CANCELLED':
        return _orders.where((o) => o.status == 'CANCELLED').toList();
      case 'UNPAID':
        return _orders.where((o) => o.status == 'UNPAID').toList();
      case 'PROCESSED':
        return _orders
            .where((o) => o.status == 'PROCESSED' || o.status == 'DONE')
            .toList();
      case 'ALL':
      default:
        return _orders;
    }
  }

  String _normalizeWhatsAppPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('0')) {
      return '62${digits.substring(1)}';
    }
    if (digits.startsWith('8')) {
      return '62$digits';
    }
    return digits;
  }

  Future<void> _openWhatsAppForOrder(
    CashierOrderModel order,
    String storeName,
  ) async {
    final normalizedPhone = _normalizeWhatsAppPhone(order.customerPhone ?? '');
    if (normalizedPhone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp konsumen tidak tersedia.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final customerName = (order.customerName?.trim().isNotEmpty ?? false)
        ? order.customerName!.trim()
        : 'Kak';
    final effectiveStore = storeName.trim().isNotEmpty
        ? storeName.trim()
        : 'Kantin Digital';
    final itemsText = order.items
        .map((item) => '- ${item.quantity}x ${item.menuName}')
        .join('\n');

    final message =
        'Halo $customerName,\n'
        'Kami dari *$effectiveStore* ingin mengonfirmasi pesanan Anda:\n\n'
        '*Kode Order:* #${order.code}\n'
        '*Info:* ${order.fulfillmentLabel}\n'
        '*Pesanan:*\n$itemsText\n'
        '*Total:* ${CurrencyFormatter.rupiah(order.totalAmount)}\n\n'
        'Mohon kirimkan *bukti transfer / pembayaran* pada chat ini agar pesanan Anda dapat segera kami proses. Terima kasih!';

    final uri = Uri.parse(
      'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmCancelOrder(CashierOrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Batalkan Transaksi?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Tandai pesanan #${order.code} (${order.customerName ?? 'Guest'}) sebagai Batal / Order Palsu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _ordersService.updateOrderStatus(order.id, 'CANCELLED');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi #${order.code} dibatalkan.'),
          backgroundColor: AppColors.textPrimary,
        ),
      );
      await _loadOrders();
      await _loadSalesStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _restoreOrder(CashierOrderModel order) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.replay_circle_filled_rounded, color: Color(0xFF0284C7), size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Jadi Buat Pesanan?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktifkan kembali pesanan #${order.code} (${order.customerName ?? "Guest"}) menjadi pesanan aktif hari ini?',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ${CurrencyFormatter.rupiah(order.totalAmount)} (${order.paymentMethodLabel})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Batal'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop('UNPAID'),
            child: const Text('Menunggu Bayar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('PROCESSING'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Sudah Bayar & Proses'),
          ),
        ],
      ),
    );

    if (action == null) return;

    try {
      await _ordersService.updateOrderStatus(order.id, action);
      await _loadOrders();
      await _loadSalesStats();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan #${order.code} berhasil diaktifkan kembali (Jadi Pesan)!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengaktifkan: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _confirmDeleteOrder(CashierOrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hapus Permanen Transaksi?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus permanen transaksi #${order.code} (${order.customerName ?? 'Guest'} - ${CurrencyFormatter.rupiah(order.totalAmount)}) dari sistem?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _ordersService.deleteOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi #${order.code} berhasil dihapus.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadOrders();
      await _loadSalesStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus transaksi: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _confirmBulkDeleteCancelled() async {
    final cancelledCount = _orders
        .where((o) => o.status == 'CANCELLED')
        .length;
    if (cancelledCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bersihkan Semua Order Batal?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Hapus permanen semua $cancelledCount transaksi yang berstatus Batal / Order Palsu sekaligus?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_sweep_rounded, size: 18),
            label: Text('Hapus $cancelledCount Transaksi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      final deleted = await _ordersService.bulkDeleteOrders(
        status: 'CANCELLED',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deleted transaksi batal berhasil dihapus.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadOrders();
      await _loadSalesStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus transaksi: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildTransactionsSection(String storeName) {
    final cancelledCount = _orders
        .where((o) => o.status == 'CANCELLED')
        .length;
    final unpaidCount = _orders.where((o) => o.status == 'UNPAID').length;
    final processedCount = _orders
        .where((o) => o.status == 'PROCESSED' || o.status == 'DONE')
        .length;
    final filtered = _filteredOrders;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Transaksi & Order Palsu',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Pantau pesanan masuk & hapus transaksi palsu/batal',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang transaksi',
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildOrderFilterChip(
                  value: 'ALL',
                  label: 'Semua (${_orders.length})',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildOrderFilterChip(
                  value: 'CANCELLED',
                  label: 'Batal / Palsu ($cancelledCount)',
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                _buildOrderFilterChip(
                  value: 'UNPAID',
                  label: 'Belum Bayar ($unpaidCount)',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                _buildOrderFilterChip(
                  value: 'PROCESSED',
                  label: 'Proses / Selesai ($processedCount)',
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          if (cancelledCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cleaning_services_rounded,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ada $cancelledCount transaksi berstatus Batal / Palsu.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _confirmBulkDeleteCancelled,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: const Text(
                      'Hapus Semua Batal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (_ordersLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tidak ada transaksi pada kategori ini',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length > 15 ? 15 : filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildAdminOrderTile(filtered[index], storeName);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOrderFilterChip({
    required String value,
    required String label,
    required Color color,
  }) {
    final selected = _selectedOrderFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedOrderFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminOrderTile(CashierOrderModel order, String storeName) {
    final isCancelled = order.status == 'CANCELLED';
    final isUnpaid = order.status == 'UNPAID';
    final hasPhone = (order.customerPhone?.trim().isNotEmpty ?? false);

    Color statusColor;
    String statusLabel;
    switch (order.status) {
      case 'CANCELLED':
        statusColor = AppColors.danger;
        statusLabel = 'BATAL / PALSU';
        break;
      case 'UNPAID':
        statusColor = AppColors.warning;
        statusLabel = 'BELUM BAYAR';
        break;
      case 'PROCESSED':
        statusColor = AppColors.info;
        statusLabel = 'DIPROSES';
        break;
      case 'DONE':
        statusColor = AppColors.success;
        statusLabel = 'SELESAI';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusLabel = order.status;
    }

    final itemsSummary = order.items
        .map((i) => '${i.quantity}x ${i.menuName}')
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCancelled
            ? AppColors.danger.withValues(alpha: 0.04)
            : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCancelled
              ? AppColors.danger.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${order.code}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.paymentMethodLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.rupiah(order.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  DateFormatter.formatFriendly(order.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: order.isUnsettled
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: order.isUnsettled
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  order.isUnsettled ? 'Belum Setor' : 'Sudah Setor',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: order.isUnsettled
                        ? const Color(0xFFB45309)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${order.customerName?.isNotEmpty == true ? order.customerName : 'Guest'} • ${order.fulfillmentLabel}${hasPhone ? ' • ${order.customerPhone}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (itemsSummary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              itemsSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasPhone)
                OutlinedButton.icon(
                  onPressed: () => _openWhatsAppForOrder(order, storeName),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1EBE57),
                    side: const BorderSide(color: Color(0xFF25D366)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 15),
                  label: const Text(
                    'Hubungi WA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              if (isCancelled)
                ElevatedButton.icon(
                  onPressed: () => _restoreOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 15),
                  label: const Text(
                    'Jadi Pesan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              if (isUnpaid)
                OutlinedButton.icon(
                  onPressed: () => _confirmCancelOrder(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 15),
                  label: const Text(
                    'Tandai Batal/Palsu',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              // Tombol Hapus HANYA untuk pesanan yang Batal / Palsu dan belum disetor
              if (isCancelled && order.isUnsettled)
                ElevatedButton.icon(
                  onPressed: () => _confirmDeleteOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 15),
                  label: const Text(
                    'Hapus Transaksi',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniReportCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniReportCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InsightPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _GlassActionCard extends StatelessWidget {
  final _ActionItem action;
  final int index;

  const _GlassActionCard({required this.action, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, action.route),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative gradient blob
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -10,
                  bottom: -10,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: action.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(action.icon, color: action.color, size: 26),
                      ),
                      const Spacer(),
                      Text(
                        action.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
