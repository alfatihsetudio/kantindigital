import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/network/api_client.dart';
import 'widgets/manager_drawer.dart';

/// Manager Sales Page with Liquid Glass Design
/// Gojek-inspired green theme with charts and statistics
class ManagerSalesPage extends StatefulWidget {
  const ManagerSalesPage({super.key});

  @override
  State<ManagerSalesPage> createState() => _ManagerSalesPageState();
}

class _ManagerSalesPageState extends State<ManagerSalesPage>
    with SingleTickerProviderStateMixin {
  final ApiClient _client = ApiClient();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;
  String _selectedPeriod = '7days';
  DateTimeRange? _customDateRange;
  String _chartMetric = 'revenue'; // 'revenue' or 'cups'
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadStats();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper to safely parse int from dynamic
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Hari Ini';
      case 'yesterday':
        return 'Kemarin';
      case '7days':
        return '7 Hari Terakhir';
      case '30days':
        return '30 Hari Terakhir';
      case 'this_month':
        return 'Bulan Ini';
      case 'custom':
        if (_customDateRange != null) {
          final s = _customDateRange!.start;
          final e = _customDateRange!.end;
          return '${s.day}/${s.month} - ${e.day}/${e.month}/${e.year}';
        }
        return 'Kustom';
      default:
        return '7 Hari Terakhir';
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          ),
      firstDate: DateTime(2023),
      lastDate: now,
      helpText: 'PILIH RENTANG TANGGAL',
      cancelText: 'BATAL',
      confirmText: 'TERAPKAN',
      saveText: 'PILIH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customDateRange = picked;
      });
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final queryParams = <String, String>{
        'period': _selectedPeriod,
      };
      if (_selectedPeriod == 'custom' && _customDateRange != null) {
        final start = _customDateRange!.start;
        final end = _customDateRange!.end;
        queryParams['start_date'] =
            '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
        queryParams['end_date'] =
            '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      }

      final response = await _client.get(
        '/manager/stats',
        queryParameters: queryParams,
      );
      if (mounted) {
        setState(() {
          _stats = response['data'];
          _loading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ManagerDrawer(),
      body: Stack(
        children: [
          // Background decorations
          _buildBackgroundDecorations(),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(context),

                // Content
                Expanded(
                  child: _loading
                      ? _buildLoadingState()
                      : _error != null
                      ? _buildErrorState(_error!)
                      : _buildContent(),
                ),
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
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.5),
                  AppColors.primaryLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          Builder(
            builder: (scaffoldContext) => IconButton(
              onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan Penjualan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Pemasukan, grafik, dan analisa',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadStats,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Memuat statistik...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_stats == null) {
      return const Center(child: Text('Data tidak tersedia'));
    }

    final summary = _stats!['summary'] as Map<String, dynamic>? ?? {};
    final dailySales =
        (_stats!['daily_sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final topMenus =
        (_stats!['top_menus'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final busyDays =
        (_stats!['busy_days'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final busiestDay = _stats!['busiest_day'] as Map<String, dynamic>? ?? {};

    final periodRevenue = _parseInt(summary['period_revenue'] ?? summary['total_revenue']);
    final periodOrders = _parseInt(summary['period_orders'] ?? summary['total_orders']);
    final periodCups = _parseInt(summary['period_cups'] ?? summary['total_cups']);

    final todayRevenue = _parseInt(summary['today_revenue']);
    final todayOrders = _parseInt(summary['today_orders']);
    final todayCups = _parseInt(summary['today_cups']);

    final totalRevenue = _parseInt(summary['total_revenue']);
    final totalOrders = _parseInt(summary['total_orders']);
    final totalCups = _parseInt(summary['total_cups']);

    final monthRevenue = _parseInt(summary['month_revenue']);
    final monthOrders = _parseInt(summary['month_orders']);
    final monthCups = _parseInt(summary['month_cups']);

    final averageOrderValue = _parseInt(summary['average_order_value']);
    final averageCupsPerOrder = _parseDouble(summary['average_cups_per_order']);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Hari / Periode
            _buildPeriodFilterSection(),

            const SizedBox(height: 14),

            // Summary Cards
            _buildSummarySection(
              periodRevenue: periodRevenue,
              periodOrders: periodOrders,
              periodCups: periodCups,
              todayRevenue: todayRevenue,
              todayOrders: todayOrders,
              todayCups: todayCups,
              monthRevenue: monthRevenue,
              monthOrders: monthOrders,
              monthCups: monthCups,
              totalRevenue: totalRevenue,
              totalOrders: totalOrders,
              totalCups: totalCups,
              averageOrderValue: averageOrderValue,
              averageCupsPerOrder: averageCupsPerOrder,
            ),

            const SizedBox(height: 24),

            // Sales & Cup Chart
            _buildChartSection(dailySales, periodRevenue, periodOrders, periodCups),

            const SizedBox(height: 24),

            // Busy Days
            _buildBusyDaysSection(busyDays, busiestDay),

            const SizedBox(height: 24),

            // Top Menus
            _buildTopMenusSection(topMenus),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilterSection() {
    final filters = [
      {'key': 'today', 'label': 'Hari Ini', 'icon': Icons.today_rounded},
      {'key': 'yesterday', 'label': 'Kemarin', 'icon': Icons.history_rounded},
      {'key': '7days', 'label': '7 Hari', 'icon': Icons.date_range_rounded},
      {'key': '30days', 'label': '30 Hari', 'icon': Icons.calendar_month_rounded},
      {'key': 'this_month', 'label': 'Bulan Ini', 'icon': Icons.calendar_today_rounded},
      {'key': 'custom', 'label': 'Pilih Tanggal', 'icon': Icons.edit_calendar_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Filter Periode Penjualan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPeriodLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: filters.map((f) {
                final key = f['key'] as String;
                final label = f['label'] as String;
                final icon = f['icon'] as IconData;
                final isSelected = _selectedPeriod == key;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (key == 'custom') {
                        _pickCustomDateRange();
                      } else {
                        if (_selectedPeriod != key) {
                          setState(() => _selectedPeriod = key);
                          _loadStats();
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            key == 'custom' && _customDateRange != null && isSelected
                                ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
                                : label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection({
    required int periodRevenue,
    required int periodOrders,
    required int periodCups,
    required int todayRevenue,
    required int todayOrders,
    required int todayCups,
    required int monthRevenue,
    required int monthOrders,
    required int monthCups,
    required int totalRevenue,
    required int totalOrders,
    required int totalCups,
    required int averageOrderValue,
    required double averageCupsPerOrder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Card - Period Revenue
        _GlassSummaryHero(
          title: 'Pendapatan ${_getPeriodLabel()}',
          value: CurrencyFormatter.rupiah(periodRevenue),
          subtitle: '$periodOrders pesanan • ☕ $periodCups cup terjual',
          icon: Icons.account_balance_wallet_rounded,
          gradient: AppColors.primaryGradient,
        ),

        const SizedBox(height: 16),

        // Metrik Utama: Cup Terjual & Total Pesanan
        Row(
          children: [
            Expanded(
              child: _GlassSummaryCard(
                title: 'Cup Terjual (${_getPeriodLabel()})',
                value: '$periodCups Cup',
                subtitle: '$averageCupsPerOrder cup/order',
                icon: Icons.local_cafe_rounded,
                color: const Color(0xFFD97706), // Warm coffee amber
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassSummaryCard(
                title: 'Total Pesanan (${_getPeriodLabel()})',
                value: '$periodOrders Order',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF8E24AA), // Purple
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Rata-rata per order & Realtime Hari Ini
        Row(
          children: [
            Expanded(
              child: _GlassSummaryCard(
                title: 'Rata-rata per Transaksi',
                value: CurrencyFormatter.rupiah(averageOrderValue),
                icon: Icons.payments_rounded,
                color: const Color(0xFF00897B), // Teal
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassSummaryCard(
                title: 'Hari Ini ($todayOrders order)',
                value: CurrencyFormatter.rupiah(todayRevenue),
                subtitle: '$todayCups cup',
                icon: Icons.today_rounded,
                color: const Color(0xFF1E88E5), // Blue
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Bulan Ini & All-Time Total
        Row(
          children: [
            Expanded(
              child: _GlassSummaryCard(
                title: 'Pemasukan Bulan Ini',
                value: CurrencyFormatter.rupiah(monthRevenue),
                subtitle: '$monthOrders order • $monthCups cup',
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFFFF9800), // Orange
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassSummaryCard(
                title: 'Total Toko (All Time)',
                value: CurrencyFormatter.rupiah(totalRevenue),
                subtitle: '$totalOrders order • $totalCups cup',
                icon: Icons.storefront_rounded,
                color: const Color(0xFF5E35B1), // Deep purple
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(
    List<Map<String, dynamic>> dailySales,
    int periodRevenue,
    int periodOrders,
    int periodCups,
  ) {
    final isCups = _chartMetric == 'cups';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
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
                  color: isCups ? const Color(0xFFFEF3C7) : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCups ? Icons.local_cafe_rounded : Icons.show_chart_rounded,
                  color: isCups ? const Color(0xFFD97706) : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCups ? 'Grafik Jumlah Cup Terjual' : 'Grafik Pendapatan Penjualan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_getPeriodLabel()} (${dailySales.length} hari riwayat)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Toggle Tab: Omset (Rp) vs Cup Terjual (☕)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _chartMetric = 'revenue'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !isCups ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !isCups ? AppTheme.shadowSm : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on_outlined,
                            size: 15,
                            color: !isCups ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Omset (Rp)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: !isCups ? FontWeight.w700 : FontWeight.w500,
                              color: !isCups ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _chartMetric = 'cups'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isCups ? const Color(0xFFD97706) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isCups ? AppTheme.shadowSm : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_cafe_rounded,
                            size: 15,
                            color: isCups ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cup Terjual (☕)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCups ? FontWeight.w700 : FontWeight.w500,
                              color: isCups ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chart Canvas
          SizedBox(
            height: 210,
            child: dailySales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada data penjualan pada periode ini',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxValue(dailySales) * 1.25,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = dailySales[group.x.toInt()];
                            final day = item['day']?.toString() ?? '';
                            final date = item['date']?.toString() ?? '';
                            final total = _parseInt(item['total']);
                            final cups = _parseInt(item['cups']);
                            final orders = _parseInt(item['orders']);

                            return BarTooltipItem(
                              '$day ($date)\n',
                              const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                              ),
                              children: [
                                TextSpan(
                                  text: isCups
                                      ? '☕ $cups cup terjual\n'
                                      : '${CurrencyFormatter.rupiah(total)}\n',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: isCups
                                      ? 'Omset: ${CurrencyFormatter.rupiah(total)} ($orders order)'
                                      : '☕ $cups cup terjual ($orders order)',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < dailySales.length) {
                                // If many days, skip some labels to avoid clutter
                                if (dailySales.length > 14 && index % 3 != 0) {
                                  return const Text('');
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dailySales[index]['day']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: isCups ? 36 : 52,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const Text('');
                              if (isCups) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              }
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}k',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getMaxValue(dailySales) > 0
                            ? (_getMaxValue(dailySales) / 4)
                            : 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(dailySales.length, (index) {
                        final val = isCups
                            ? _parseInt(dailySales[index]['cups']).toDouble()
                            : _parseInt(dailySales[index]['total']).toDouble();

                        // Adjust bar width dynamically based on data length
                        double barWidth = 22;
                        if (dailySales.length > 20) {
                          barWidth = 8;
                        } else if (dailySales.length > 10) {
                          barWidth = 14;
                        }

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: val,
                              gradient: isCups
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                  : AppColors.primaryGradient,
                              width: barWidth,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Mini summary bar under chart
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniSummaryItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Total Omset',
                  value: CurrencyFormatter.rupiah(periodRevenue),
                  color: AppColors.primary,
                ),
                Container(width: 1, height: 24, color: AppColors.border),
                _buildMiniSummaryItem(
                  icon: Icons.local_cafe_rounded,
                  label: 'Total Cup',
                  value: '$periodCups Cup',
                  color: const Color(0xFFD97706),
                ),
                Container(width: 1, height: 24, color: AppColors.border),
                _buildMiniSummaryItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total Order',
                  value: '$periodOrders Transaksi',
                  color: const Color(0xFF8E24AA),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTopMenusSection(List<Map<String, dynamic>> topMenus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Terlaris',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '30 hari terakhir',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (topMenus.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu_rounded,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada data',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ...topMenus.asMap().entries.map((entry) {
            final index = entry.key;
            final menu = entry.value;
            return _TopMenuCard(
              rank: index + 1,
              name: menu['menu_name']?.toString() ?? 'Menu',
              quantity: menu['total_qty']?.toString() ?? '0',
              total: _parseInt(menu['total_sales']),
              salesShare: _parseDouble(menu['sales_share']),
              index: index,
            );
          }),
      ],
    );
  }

  Widget _buildBusyDaysSection(
    List<Map<String, dynamic>> busyDays,
    Map<String, dynamic> busiestDay,
  ) {
    final topDay = busiestDay['day']?.toString() ?? '-';
    final topOrders = _parseInt(busiestDay['orders']);
    final topRevenue = _parseInt(busiestDay['revenue']);
    final maxOrders = busyDays.isEmpty
        ? 0
        : busyDays
              .map((day) => _parseInt(day['orders']))
              .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
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
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analisa Hari Ramai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      topOrders > 0
                          ? '$topDay paling ramai, $topOrders pesanan'
                          : 'Belum ada pola hari ramai',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    topOrders > 0
                        ? '$topDay menghasilkan ${CurrencyFormatter.rupiah(topRevenue)} dari $topOrders pesanan.'
                        : 'Data akan terisi setelah ada pesanan yang dibayar atau diproses.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (busyDays.isEmpty)
            Center(
              child: Text(
                'Belum ada data hari',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...busyDays.map((day) {
              final orders = _parseInt(day['orders']);
              final revenue = _parseInt(day['revenue']);
              final ratio = maxOrders > 0 ? orders / maxOrders : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            day['day']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: ratio.clamp(0.0, 1.0),
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                orders == maxOrders && orders > 0
                                    ? AppColors.primary
                                    : const Color(0xFF90CAF9),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 72,
                          child: Text(
                            '$orders order',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (revenue > 0) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Text(
                          CurrencyFormatter.rupiah(revenue),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  double _getMaxValue(List<Map<String, dynamic>> dailySales) {
    if (dailySales.isEmpty) return _chartMetric == 'cups' ? 20 : 100000;
    final key = _chartMetric == 'cups' ? 'cups' : 'total';
    final max = dailySales
        .map((e) => _parseInt(e[key]).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);
    if (_chartMetric == 'cups') {
      return max > 0 ? max : 10;
    }
    return max > 0 ? max : 100000;
  }
}

// ═══════════════════════════════════════════════════════════
// GLASS SUMMARY HERO - Large summary card with gradient
// ═══════════════════════════════════════════════════════════

class _GlassSummaryHero extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;

  const _GlassSummaryHero({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '📦 $subtitle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GLASS SUMMARY CARD - Small summary card
// ═══════════════════════════════════════════════════════════

class _GlassSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _GlassSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (subtitle != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TOP MENU CARD - Ranking card with animation
// ═══════════════════════════════════════════════════════════

class _TopMenuCard extends StatelessWidget {
  final int rank;
  final String name;
  final String quantity;
  final int total;
  final double salesShare;
  final int index;

  const _TopMenuCard({
    required this.rank,
    required this.name,
    required this.quantity,
    required this.total,
    required this.salesShare,
    required this.index,
  });

  Color _getMedalColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.primary;
    }
  }

  IconData _getMedalIcon() {
    switch (rank) {
      case 1:
        return Icons.emoji_events_rounded;
      case 2:
        return Icons.military_tech_rounded;
      case 3:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: _getMedalColor().withValues(
                alpha: rank <= 3 ? 0.15 : 0.05,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getMedalColor(),
                    _getMedalColor().withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getMedalColor().withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: rank <= 3
                    ? Icon(_getMedalIcon(), color: Colors.white, size: 22)
                    : Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Menu info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_cafe_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$quantity cup terjual',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (salesShare > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${salesShare.toStringAsFixed(salesShare % 1 == 0 ? 0 : 1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Total sales
            Text(
              CurrencyFormatter.rupiah(total),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
