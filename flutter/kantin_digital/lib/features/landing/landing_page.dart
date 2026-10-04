import 'package:flutter/material.dart';
import '../../core/utils/image_saver.dart';
import '../../router/route_name.dart';
import '../../shared/services/demo_session_manager.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int? _expandedFaqIndex;

  // GlobalKeys for smooth scrolling
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  static const String adminWhatsAppNumber = '6287771262100';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _openWhatsApp({String? customMessage}) {
    final message = customMessage ??
        'Halo Admin eKasir, saya tertarik ingin membeli website eKasir untuk bisnis saya. Mohon info paket dan cara pemesanannya ya.';
    final url =
        'https://wa.me/$adminWhatsAppNumber?text=${Uri.encodeComponent(message)}';
    ImageSaver.openUrl(url);
  }

  void _openDemoPage() {
    DemoSessionManager.enableDemoMode();
    Navigator.of(context).pushNamed(RouteName.demoMenu);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 1200;
    final isMedium = size.width >= 960 && size.width < 1200;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    final isMobile = size.width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: isMobile ? _buildMobileDrawer(context) : null,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40.0 : (size.width > 600 ? 18.0 : 12.0),
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Logo Brand
                  InkWell(
                    onTap: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'eKasir',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(width: 5),
                                _ProBadge(),
                              ],
                            ),
                            if (size.width >= 1100)
                              Text(
                                'Platform Kasir & Self-Order Resto',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Desktop Nav Links
                  if (isWide) ...[
                    _NavTextButton(
                      label: 'Keunggulan',
                      onPressed: () => _scrollTo(_featuresKey),
                    ),
                    _NavTextButton(
                      label: 'Cara Kerja',
                      onPressed: () => _scrollTo(_howItWorksKey),
                    ),
                    _NavTextButton(
                      label: 'Toko Asli',
                      onPressed: () {
                        Navigator.of(context).pushNamed(RouteName.storeShowcase);
                      },
                    ),
                    _NavTextButton(
                      label: 'Coba Demo',
                      onPressed: _openDemoPage,
                    ),
                    _NavTextButton(
                      label: 'Paket Harga',
                      onPressed: () => _scrollTo(_pricingKey),
                    ),
                    _NavTextButton(
                      label: 'FAQ',
                      onPressed: () => _scrollTo(_faqKey),
                    ),
                    const SizedBox(width: 8),
                  ] else if (isMedium) ...[
                    _NavTextButton(
                      label: 'Toko Asli',
                      onPressed: () {
                        Navigator.of(context).pushNamed(RouteName.storeShowcase);
                      },
                    ),
                    _NavTextButton(
                      label: 'Demo',
                      onPressed: _openDemoPage,
                    ),
                    _NavTextButton(
                      label: 'Harga',
                      onPressed: () => _scrollTo(_pricingKey),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteName.buyWebsite);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: Text(size.width >= 700 ? 'Beli Website' : 'Beli'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width >= 700 ? 14 : 10,
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),

                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    TextButton.icon(
                      onPressed: () {
                        DemoSessionManager.disableDemoMode();
                        Navigator.of(context).pushNamed(RouteName.adminLogin);
                      },
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: const Text('Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 4),
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E293B), size: 24),
                        tooltip: 'Menu',
                        onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _openWhatsApp(),
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 4,
              tooltip: 'Konsultasi WhatsApp',
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
            )
          : FloatingActionButton.extended(
              onPressed: () => _openWhatsApp(),
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
              label: const Text(
                'Konsultasi WhatsApp',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════════
            // 1. HERO SECTION
            // ═══════════════════════════════════════════════════════════
            _buildHeroSection(context, isDesktop, isTablet),

            // ═══════════════════════════════════════════════════════════
            // 2. PROBLEM VS SOLUTION SECTION
            // ═══════════════════════════════════════════════════════════
            _buildProblemVsSolutionSection(context, isDesktop),

            // ═══════════════════════════════════════════════════════════
            // 4. CORE FEATURES SECTION
            // ═══════════════════════════════════════════════════════════
            _buildFeaturesSection(context, isDesktop),

            // ═══════════════════════════════════════════════════════════
            // 5. HOW IT WORKS (3 LANGKAH MUDAH)
            // ═══════════════════════════════════════════════════════════
            _buildHowItWorksSection(context, isDesktop),

            // ═══════════════════════════════════════════════════════════
            // 6. PRICING & INVESTMENT SECTION
            // ═══════════════════════════════════════════════════════════
            _buildPricingSection(context, isDesktop),

            // ═══════════════════════════════════════════════════════════
            // 7. FAQ ACCORDION SECTION
            // ═══════════════════════════════════════════════════════════
            _buildFaqSection(context, isDesktop),

            // ═══════════════════════════════════════════════════════════
            // 8. FOOTER
            // ═══════════════════════════════════════════════════════════
            _buildFooter(context, isDesktop),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MOBILE NAVIGATION DRAWER
  // ─────────────────────────────────────────────────────────────
  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'eKasir',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(width: 6),
                            _ProBadge(),
                          ],
                        ),
                        Text(
                          'Menu Navigasi Mobile',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Nav Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.storefront_rounded,
                    title: 'Toko Asli (Live Merchants)',
                    subtitle: 'Lihat resto yang sudah pakai sistem ini',
                    badge: 'POPULER',
                    badgeColor: const Color(0xFF16A34A),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(RouteName.storeShowcase);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.rocket_launch_rounded,
                    title: 'Coba Demo Website Gratis',
                    subtitle: 'Simulasi alur pembeli, kasir & admin',
                    badge: 'DEMO',
                    badgeColor: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openDemoPage();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.payments_rounded,
                    title: 'Paket & Investasi Harga',
                    subtitle: 'Mulai Rp 30.000/bln 0% komisi',
                    onTap: () {
                      Navigator.of(context).pop();
                      Future.delayed(
                          const Duration(milliseconds: 200), () => _scrollTo(_pricingKey));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.star_rounded,
                    title: 'Keunggulan Fitur',
                    subtitle: 'Self-order QR meja, POS kasir, dapur',
                    onTap: () {
                      Navigator.of(context).pop();
                      Future.delayed(
                          const Duration(milliseconds: 200), () => _scrollTo(_featuresKey));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.alt_route_rounded,
                    title: 'Cara Kerja',
                    subtitle: '3 langkah cepat mulai jualan',
                    onTap: () {
                      Navigator.of(context).pop();
                      Future.delayed(
                          const Duration(milliseconds: 200), () => _scrollTo(_howItWorksKey));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Pertanyaan Umum (FAQ)',
                    subtitle: 'Informasi printer, komisi, dan cara setup',
                    onTap: () {
                      Navigator.of(context).pop();
                      Future.delayed(
                          const Duration(milliseconds: 200), () => _scrollTo(_faqKey));
                    },
                  ),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),
                  _buildDrawerItem(
                    icon: Icons.login_rounded,
                    title: 'Login Kasir & Admin',
                    subtitle: 'Masuk ke panel manajemen toko',
                    onTap: () {
                      DemoSessionManager.disableDemoMode();
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(RouteName.adminLogin);
                    },
                  ),
                ],
              ),
            ),
            // Bottom Action in Drawer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(RouteName.buyWebsite);
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text(
                        'Beli Website Sekarang',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openWhatsApp();
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                      label: const Text(
                        'Tanya Admin WhatsApp',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF86EFAC)),
                        backgroundColor: const Color(0xFFF0FDF4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF334155)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? const Color(0xFF2563EB)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: badgeColor ?? const Color(0xFF2563EB),
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF1F5F9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : (isMobile ? 16.0 : 24.0),
        vertical: isDesktop ? 64.0 : (isMobile ? 30.0 : 40.0),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              // Tagline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Solusi Website Kasir & Self-Order QR Usaha Kuliner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'Miliki Website Kasir & Self-Order QR Meja dengan Brand Usaha Anda Sendiri',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 44 : (isTablet ? 32 : 23),
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  height: 1.25,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 14),

              // Subtitle
              Text(
                'Tingkatkan omzet dan modernisasi restoran, kafe, atau kantin Anda. Pelanggan cukup scan QR di meja untuk memesan, pesanan otomatis masuk ke kasir dan dapur, struk tercetak instan via printer thermal — 100% tanpa potongan komisi!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isDesktop ? 17 : 14,
                  color: const Color(0xFF475569),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),

              // Hero CTA Buttons
              if (isMobile) ...[
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(RouteName.buyWebsite);
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, size: 19),
                        label: const Flexible(
                          child: Text(
                            'Beli Website Sekarang',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openDemoPage,
                        icon: const Icon(Icons.rocket_launch_rounded, size: 19),
                        label: const Flexible(
                          child: Text(
                            'Coba Demo Website Gratis',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(RouteName.storeShowcase);
                        },
                        icon: const Icon(Icons.storefront_rounded, size: 19),
                        label: const Flexible(
                          child: Text(
                            'Lihat Contoh Toko Asli (Live)',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(RouteName.buyWebsite);
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                      label: const Text(
                        'Beli Website Sekarang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openDemoPage,
                      icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                      label: const Text(
                        'Coba Demo Website Gratis',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(RouteName.storeShowcase);
                      },
                      icon: const Icon(
                        Icons.storefront_rounded,
                        size: 20,
                      ),
                      label: const Text(
                        'Lihat Toko Asli Pengguna Website Ini',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),

              // Trust Highlights Strip
              Wrap(
                alignment: WrapAlignment.center,
                spacing: isDesktop ? 20 : 10,
                runSpacing: 10,
                children: [
                  _buildQuickBadge(Icons.check_circle_rounded, 'Tanpa Install Aplikasi'),
                  _buildQuickBadge(Icons.language_rounded, 'Subdomain Eksklusif'),
                  _buildQuickBadge(Icons.percent_rounded, '0% Potongan Komisi'),
                  _buildQuickBadge(Icons.print_rounded, 'Struk Thermal Bluetooth'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. PROBLEM VS SOLUTION SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildProblemVsSolutionSection(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : 20.0,
        vertical: 60.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              const Text(
                'KENAPA HARUS MILIKI WEBSITE eKasir SENDIRI?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bebaskan Usaha Anda dari Antrean & Komisi Pihak Ketiga',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return isWide
                      ? const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _OldWayCard()),
                            SizedBox(width: 24),
                            Expanded(child: _NewWayCard()),
                          ],
                        )
                      : const Column(
                          children: [
                            _OldWayCard(),
                            SizedBox(height: 20),
                            _NewWayCard(),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. CORE FEATURES SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildFeaturesSection(BuildContext context, bool isDesktop) {
    return Container(
      key: _featuresKey,
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : 20.0,
        vertical: 64.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              const Text(
                'FITUR LENGKAP & TIDAK RIBET',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Semua Fitur Esensial untuk Menjalankan Restoran & Kantin Modern',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobileList = constraints.maxWidth <= 640;
                  final featureItems = [
                    _FeatureCard(
                      icon: Icons.qr_code_scanner_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Self-Order QR Meja',
                      description:
                          'Pelanggan duduk, scan barcode di meja, pesan menu & topping favorit langsung dari HP tanpa perlu download aplikasi apapun.',
                      isGrid: !isMobileList,
                    ),
                    _FeatureCard(
                      icon: Icons.point_of_sale_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Aplikasi Kasir POS Cepat',
                      description:
                          'Kasir dapat memproses pesanan langsung (walk-in), hitung kembalian, dan terima orderan online dari meja secara terpadu.',
                      isGrid: !isMobileList,
                    ),
                    _FeatureCard(
                      icon: Icons.print_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Cetak Struk Thermal Bluetooth',
                      description:
                          'Cetak struk belanja ke printer thermal Bluetooth ukuran 58mm atau 80mm hanya dalam hitungan detik.',
                      isGrid: !isMobileList,
                    ),
                    _FeatureCard(
                      icon: Icons.soup_kitchen_rounded,
                      iconBg: const Color(0xFFFEF2F2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Kitchen Display (Layar Dapur)',
                      description:
                          'Pesanan masuk langsung tampil di layar operasional dapur atau barista secara realtime. Tanpa kertas bon tercecer atau salah masak.',
                      isGrid: !isMobileList,
                    ),
                    _FeatureCard(
                      icon: Icons.qr_code_2_rounded,
                      iconBg: const Color(0xFFFDF4FF),
                      iconColor: const Color(0xFF9333EA),
                      title: 'QRIS & Multi Pembayaran',
                      description:
                          'Mendukung pembayaran via QRIS dan Tunai. Pelanggan bisa langsung upload atau konfirmasi bukti bayar lewat WhatsApp.',
                      isGrid: !isMobileList,
                    ),
                    _FeatureCard(
                      icon: Icons.insights_rounded,
                      iconBg: const Color(0xFFF0F9FF),
                      iconColor: const Color(0xFF0284C7),
                      title: 'Laporan Omzet Realtime',
                      description:
                          'Pemilik bisa memantau total omzet harian, laba penjualan, produk terlaris, dan rekap kasir dari mana saja lewat smartphone.',
                      isGrid: !isMobileList,
                    ),
                  ];

                  if (isMobileList) {
                    return Column(
                      children: featureItems
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: item,
                              ))
                          .toList(),
                    );
                  }

                  final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: constraints.maxWidth > 900 ? 1.25 : 1.35,
                    children: featureItems,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. HOW IT WORKS (3 LANGKAH MUDAH)
  // ─────────────────────────────────────────────────────────────
  Widget _buildHowItWorksSection(BuildContext context, bool isDesktop) {
    return Container(
      key: _howItWorksKey,
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : 20.0,
        vertical: 60.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              const Text(
                'CARA MEMULAI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hanya 3 Langkah Cepat untuk Memulai',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 36),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final steps = [
                    const _StepCard(
                      stepNumber: '1',
                      title: 'Pesan & Setup Website',
                      description:
                          'Tentukan nama subdomain toko Anda (misal: kedai.ekasir.my.id). Tim kami langsung mengaktifkan sistem dan membantu input menu awal.',
                      icon: Icons.language_rounded,
                    ),
                    const _StepCard(
                      stepNumber: '2',
                      title: 'Cetak QR Code Meja',
                      description:
                          'Download dan cetak barcode QR untuk setiap nomor meja dari dashboard admin. Tempelkan stiker QR di masing-masing meja makan.',
                      icon: Icons.qr_code_2_rounded,
                    ),
                    const _StepCard(
                      stepNumber: '3',
                      title: 'Toko Siap Berjalan Otomatis',
                      description:
                          'Pelanggan mulai scan, pilih makanan, dan bayar mandiri. Pesanan langsung masuk kasir, struk tercetak, dan dapur langsung memasak!',
                      icon: Icons.store_rounded,
                    ),
                  ];

                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: steps
                              .map((step) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: step,
                                    ),
                                  ))
                              .toList(),
                        )
                      : Column(
                          children: steps
                              .map((step) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: step,
                                  ))
                              .toList(),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. PRICING & INVESTMENT SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildPricingSection(BuildContext context, bool isDesktop) {
    return Container(
      key: _pricingKey,
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : 20.0,
        vertical: 64.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const Text(
                'PAKET & INVESTASI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih Paket yang Sesuai untuk Skala Usaha Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '0% Komisi Transaksi seumur hidup. Uang penjualan 100% milik Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;

                  final pCard1 = _PricingCard(
                    title: 'Paket Hemat',
                    price: 'Rp 30.000',
                    period: '/bulan',
                    subtitle:
                        'Cocok untuk booth kecil, warung makan, atau kedai pemula.',
                    badge: 'HEMAT',
                    isPopular: false,
                    features: const [
                      'Hadir semua jenis akun (Owner, Kasir, Dapur)',
                      'Maksimal menu hanya 10 menu',
                      'Kasir POS & Struk (Tanpa sistem barcode meja)',
                      '0% Biaya admin (Tanpa potongan komisi)',
                      'Subdomain Toko [nama].ekasir.my.id',
                    ],
                    onSelect: () => Navigator.of(context).pushNamed(
                      RouteName.buyWebsite,
                      arguments: {
                        'plan': 'plan_30k',
                      },
                    ),
                  );

                  final pCard2 = _PricingCard(
                    title: 'Paket Standar',
                    price: 'Rp 70.000',
                    period: '/bulan',
                    subtitle:
                        'Ideal untuk kafe kecil atau warung makan sistem nomor meja.',
                    badge: 'POPULER',
                    isPopular: false,
                    features: const [
                      'Hadir semua jenis akun (Owner, Kasir, Dapur)',
                      'Maksimal hingga 20 menu',
                      'Sistem barcode QR meja (Maksimal 15 meja)',
                      '0% Biaya admin (Tanpa potongan komisi)',
                      'Subdomain Toko [nama].ekasir.my.id',
                    ],
                    onSelect: () => Navigator.of(context).pushNamed(
                      RouteName.buyWebsite,
                      arguments: {
                        'plan': 'plan_70k',
                      },
                    ),
                  );

                  final pCard3 = _PricingCard(
                    title: 'Paket Pro Unlimited',
                    price: 'Rp 100.000',
                    period: '/bulan',
                    subtitle:
                        'Paling favorit untuk restoran, kafe modern, atau food court.',
                    badge: '⭐ BEST SELLER',
                    isPopular: true,
                    features: const [
                      'Hadir semua jenis akun (Owner, Kasir, Dapur, Mgr)',
                      'Tanpa batas maksimal menu (Unlimited Menu)',
                      'Sistem barcode tanpa batas meja (Unlimited Meja)',
                      'Kitchen Display (Layar Dapur) & POS Kasir',
                      '0% Biaya admin (Tanpa potongan komisi)',
                      'Subdomain Toko [nama].ekasir.my.id',
                    ],
                    onSelect: () => Navigator.of(context).pushNamed(
                      RouteName.buyWebsite,
                      arguments: {
                        'plan': 'plan_100k',
                      },
                    ),
                  );

                  final pCard4 = _PricingCard(
                    title: 'Paket Custom Domain',
                    price: 'Rp 1.000.000',
                    period: '/tahun',
                    subtitle:
                        'Tampilan eksklusif & profesional dengan nama domain sendiri.',
                    badge: '👑 VIP TAHUNAN',
                    isPopular: false,
                    features: const [
                      'Domain sendiri (Contoh: namatoko.com / .id)',
                      'Semua fitur di pilihan lain (Full Unlimited)',
                      'Hadir semua jenis akun lengkap',
                      'Tanpa batas menu & barcode meja',
                      '0% Biaya admin (Tanpa potongan komisi)',
                      'Prioritas panduan, bantuan WhatsApp & SSL',
                    ],
                    onSelect: () => Navigator.of(context).pushNamed(
                      RouteName.buyWebsite,
                      arguments: {
                        'plan': 'plan_1jt',
                      },
                    ),
                  );

                  if (isWide) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: pCard1),
                            const SizedBox(width: 24),
                            Expanded(child: pCard2),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: pCard3),
                            const SizedBox(width: 24),
                            Expanded(child: pCard4),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        pCard1,
                        const SizedBox(height: 20),
                        pCard2,
                        const SizedBox(height: 20),
                        pCard3,
                        const SizedBox(height: 20),
                        pCard4,
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 8. FAQ ACCORDION SECTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildFaqSection(BuildContext context, bool isDesktop) {
    final faqs = [
      _FaqItem(
        question:
            'Apakah pelanggan harus menginstal aplikasi di Play Store atau App Store?',
        answer:
            'Tidak sama sekali! Cukup scan QR code di meja menggunakan kamera HP, website menu akan otomatis terbuka di browser browser HP pelanggan tanpa perlu instal atau login.',
      ),
      _FaqItem(
        question:
            'Printer apa saja yang didukung untuk mencetak struk kasir?',
        answer:
            'Mendukung semua printer thermal standar ukuran 58mm dan 80mm yang memiliki koneksi Bluetooth atau USB, baik untuk HP Android maupun laptop/PC kasir.',
      ),
      _FaqItem(
        question:
            'Apakah ada potongan komisi dari setiap transaksi penjualan saya?',
        answer:
            '0% komisi! Semua uang pembayaran dari pelanggan langsung masuk 100% ke rekening bank atau QRIS toko Anda sendiri tanpa ada perantara atau potongan persenan.',
      ),
      _FaqItem(
        question:
            'Bagaimana jika saya belum terbiasa atau gaptek dengan sistem ini?',
        answer:
            'Jangan khawatir! Tim kami akan memandu Anda mulai dari cara mendaftarkan menu, cetak QR meja, hingga cara mengoperasikan kasir dan mencetak struk sampai Anda benar-benar mahir.',
      ),
      _FaqItem(
        question: 'Berapa lama proses pembuatan websitenya?',
        answer:
            'Sangat cepat! Setelah Anda memilih nama subdomain dan mengirimkan data menu, website toko Anda bisa langsung aktif dan siap digunakan dalam waktu kurang dari 24 jam.',
      ),
    ];

    return Container(
      key: _faqKey,
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : 20.0,
        vertical: 60.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              const Text(
                'PERTANYAAN UMUM (FAQ)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hal yang Sering Ditanyakan Pengusaha',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 36),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: faqs.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  final isExpanded = _expandedFaqIndex == index;
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isExpanded
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedFaqIndex = expanded ? index : null;
                          });
                        },
                        title: Text(
                          faq.question,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isExpanded
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                faq.answer,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 8. FOOTER
  // ─────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: 36,
        horizontal: isDesktop ? 48 : 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const Text(
                    'eKasir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '• Platform SaaS Kasir & Self-Order QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Setiap merchant mendapatkan subdomain eksklusif [nama].ekasir.my.id • 0% Komisi Transaksi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '© 2026 eKasir Platform. Seluruh hak cipta dilindungi undang-undang.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper UI widgets
  Widget _buildQuickBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF16A34A)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COMPONENT WIDGETS
// ─────────────────────────────────────────────────────────────

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Text(
        'SaaS',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
  }
}

class _NavTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NavTextButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

class _OldWayCard extends StatelessWidget {
  const _OldWayCard();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cara Lama & Masalah',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _item('Komisi 20% - 30% memotong margin di platform ojek online.'),
          _item('Antrean kasir membludak di jam ramai membuat pelanggan pergi.'),
          _item('Pesanan salah catat dan kertas bon tercecer di meja dapur.'),
          _item('Pusing rekap nota manual di buku saat tutup toko malam hari.'),
        ],
      ),
    );
  }

  Widget _item(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('❌ ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7F1D1D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewWayCard extends StatelessWidget {
  const _NewWayCard();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Solusi Cerdas Bersama eKasir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _item('0% Komisi! 100% uang hasil jualan langsung ke rekening Anda.'),
          _item('Pelanggan pesan mandiri via scan QR meja tanpa antre di kasir.'),
          _item('Detail pesanan & topping langsung tampil di layar dapur realtime.'),
          _item('Laporan penjualan dan kas harian terekap otomatis dan instan.'),
        ],
      ),
    );
  }

  Widget _item(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅ ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF14532D),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final bool isGrid;

  const _FeatureCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    this.isGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          if (isGrid)
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            )
          else
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Icon(icon, color: const Color(0xFF94A3B8), size: 28),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String price;
  final String period;
  final bool isPopular;
  final List<String> features;
  final VoidCallback onSelect;

  const _PricingCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.price,
    this.period = '/bulan',
    required this.isPopular,
    required this.features,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isPopular ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPopular
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: isPopular
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                period,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 18),
          const Text(
            'Fasilitas yang Didapatkan:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          ...features.map(
            (feat) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feat,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: Flexible(
                child: Text(
                  isMobile ? 'Pesan Paket Sekarang' : 'Pesan $title Sekarang',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}
