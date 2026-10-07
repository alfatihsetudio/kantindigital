import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/auth/auth_session.dart';
import '../../shared/models/tenant_model.dart';
import '../../shared/providers/tenant_provider.dart';
import '../../router/route_name.dart';
import 'widgets/manager_drawer.dart';

/// Manager Dashboard with Liquid Glass Design
/// Simple, Gojek-inspired, with soft rounded corners
class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
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
      drawer: const ManagerDrawer(),
      body: Stack(
        children: [
          // Background gradient circles
          _buildBackgroundDecorations(),

          // Main content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(child: _buildCustomAppBar(context, tenant)),

                // Welcome Card
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildWelcomeCard(
                        tenant.name.isNotEmpty ? tenant.name : (user?.name ?? 'Pimpinan'),
                        user?.name ?? 'Pimpinan',
                      ),
                    ),
                  ),
                ),

                // Quick Stats
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildQuickStats(),
                  ),
                ),

                // Menu Section Title
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu Laporan',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Semua data bersifat Read Only',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Quick Actions Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                        ),
                    delegate: SliverChildListDelegate([
                      _GlassActionCard(
                        icon: Icons.bar_chart_rounded,
                        title: 'Laporan Penjualan',
                        subtitle: 'Pemasukan dan analisa',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00C853), Color(0xFF00AA13)],
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteName.managerSales,
                        ),
                        index: 0,
                      ),
                      _GlassActionCard(
                        icon: Icons.restaurant_menu_rounded,
                        title: 'Daftar Menu',
                        subtitle: 'Lihat semua menu',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF26A69A), Color(0xFF00897B)],
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteName.managerMenus,
                        ),
                        index: 1,
                      ),
                      _GlassActionCard(
                        icon: Icons.category_rounded,
                        title: 'Kategori',
                        subtitle: 'Lihat kategori menu',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteName.managerCategories,
                        ),
                        index: 2,
                      ),
                      _GlassActionCard(
                        icon: Icons.people_rounded,
                        title: 'Data Karyawan',
                        subtitle: 'Lihat staff kantin',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFAB47BC), Color(0xFF8E24AA)],
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteName.managerUsers,
                        ),
                        index: 3,
                      ),
                    ]),
                  ),
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
        // Top gradient circle
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
        // Bottom left gradient
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
                  AppColors.primaryLight.withValues(alpha: 0.4),
                  AppColors.primaryLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAppBar(BuildContext context, TenantModel tenant) {
    final logoProvider = (tenant.logoUrl != null && tenant.logoUrl!.isNotEmpty)
        ? tenantLogoImageProvider(tenant.logoUrl!)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          // Menu Button
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
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
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              tenant.name.isNotEmpty ? tenant.name : 'Dashboard Pimpinan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          // Quick Action Menu
          Theme(
            data: Theme.of(context).copyWith(cardColor: Colors.white),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              offset: const Offset(0, 48),
              onSelected: (value) {
                if (value == 'stats') {
                  Navigator.pushNamed(context, RouteName.managerSales);
                } else if (value == 'drawer') {
                  Scaffold.of(context).openDrawer();
                } else if (value == 'logout') {
                  AuthSession().clear();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    RouteName.adminLogin,
                    (route) => false,
                  );
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Laporan Penjualan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'drawer',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Menu & Akun',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Keluar',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(String storeName, String name) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
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
          // Decorative pattern
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.business_center_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.waving_hand_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Halo, $name',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Pantau laporan dan statistik bisnis kantin Anda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.receipt_long_rounded,
              label: 'Pesanan',
              value: 'Hari Ini',
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.trending_up_rounded,
              label: 'Penjualan',
              value: 'Minggu Ini',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.star_rounded,
              label: 'Menu Favorit',
              value: 'Top 5',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GLASS ACTION CARD - Modern card with glass effect
// ═══════════════════════════════════════════════════════════

class _GlassActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  final int index;

  const _GlassActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    required this.index,
  });

  @override
  State<_GlassActionCard> createState() => _GlassActionCardState();
}

class _GlassActionCardState extends State<_GlassActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          _controller.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gradient accent
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon with gradient background
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: widget.gradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (widget.gradient as LinearGradient)
                                  .colors
                                  .first
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 24),
                      ),
                      const Spacer(),
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Subtitle
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow indicator
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
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

// ═══════════════════════════════════════════════════════════
// STAT CARD - Small stat indicator
// ═══════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
