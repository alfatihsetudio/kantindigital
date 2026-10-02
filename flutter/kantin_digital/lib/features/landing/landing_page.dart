import 'package:flutter/material.dart';
import '../../router/route_name.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void _openDemoTenant(BuildContext context) {
    Navigator.of(context).pushNamed(RouteName.customerMenu);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // Logo & Brand
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'eKasir',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Kantin & Resto Digital',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Action buttons
                  OutlinedButton.icon(
                    onPressed: () => _openDemoTenant(context),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                    label: Text(isDesktop ? 'Lihat Demo Kantin' : 'Demo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 20 : 12,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteName.adminLogin);
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(isDesktop ? 'Login Akun' : 'Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 22 : 14,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO SECTION
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 20.0,
                vertical: isDesktop ? 64.0 : 36.0,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFF1F5F9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Platform POS Kasir & Self-Order QR Multi-Tenant',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Big Title
                      Text(
                        'Kelola Kantin & Restoran Lebih Cepat, Rapi, dan Modern',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 42 : 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          height: 1.2,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Subtitle
                      Text(
                        'Pelanggan pesan mandiri lewat QR Code di meja, pesanan otomatis masuk ke layar dapur, kasir mencetak struk thermal, dan pemilik memantau omzet secara realtime.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 15,
                          color: const Color(0xFF64748B),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Buttons
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed(RouteName.adminLogin);
                            },
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text(
                              'Masuk ke Akun / Kasir',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openDemoTenant(context),
                            icon: const Icon(Icons.store_rounded),
                            label: const Text(
                              'Buka Demo Kantin (Say Coffee)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E293B),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // Features Badge Row
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: isDesktop ? 32 : 16,
                        runSpacing: 12,
                        children: [
                          _buildQuickBadge(Icons.check_circle_rounded, 'Tanpa Install Aplikasi'),
                          _buildQuickBadge(Icons.qr_code_2_rounded, 'Self-Order QR Meja'),
                          _buildQuickBadge(Icons.receipt_long_rounded, 'Struk Thermal & Bluetooth'),
                          _buildQuickBadge(Icons.domain_rounded, 'Subdomain Eksklusif'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FITUR UNGGULAN SECTION
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 20.0,
                vertical: 60.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    Text(
                      'FITUR UNGGULAN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Semua yang Dibutuhkan untuk Usaha Kuliner',
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
                        final crossAxisCount = constraints.maxWidth > 900
                            ? 3
                            : (constraints.maxWidth > 600 ? 2 : 1);
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: constraints.maxWidth > 900 ? 1.25 : 1.35,
                          children: const [
                            _FeatureCard(
                              icon: Icons.qr_code_scanner_rounded,
                              iconBg: Color(0xFFEFF6FF),
                              iconColor: Color(0xFF2563EB),
                              title: 'Self-Order QR Meja',
                              description:
                                  'Pelanggan duduk, scan barcode QR di meja, pesan menu dan topping favorit tanpa harus antre berdesakan.',
                            ),
                            _FeatureCard(
                              icon: Icons.point_of_sale_rounded,
                              iconBg: Color(0xFFF0FDF4),
                              iconColor: Color(0xFF16A34A),
                              title: 'POS Kasir Cepat',
                              description:
                                  'Proses pesanan walk-in, hitung total & kembalian otomatis, serta cetak struk via printer thermal Bluetooth 58/80mm.',
                            ),
                            _FeatureCard(
                              icon: Icons.soup_kitchen_rounded,
                              iconBg: Color(0xFFFFF7ED),
                              iconColor: Color(0xFFEA580C),
                              title: 'Kitchen Display (KDS)',
                              description:
                                  'Pesanan masuk langsung tampil di layar operasional dapur secara realtime. Tanpa kertas bon hilang atau salah masak.',
                            ),
                            _FeatureCard(
                              icon: Icons.analytics_outlined,
                              iconBg: Color(0xFFFDF4FF),
                              iconColor: Color(0xFF9333EA),
                              title: 'Laporan Penjualan',
                              description:
                                  'Pantau omzet harian, mingguan, metode pembayaran QRIS/Tunai, dan produk paling laris dalam sekejap.',
                            ),
                            _FeatureCard(
                              icon: Icons.tune_rounded,
                              iconBg: Color(0xFFFEF2F2),
                              iconColor: Color(0xFFDC2626),
                              title: 'Menu & Topping Fleksibel',
                              description:
                                  'Atur variasi menu, level kepedasan, pilihan topping, kategori, foto produk, dan status stok dengan mudah.',
                            ),
                            _FeatureCard(
                              icon: Icons.hub_rounded,
                              iconBg: Color(0xFFF0F9FF),
                              iconColor: Color(0xFF0284C7),
                              title: 'Sistem Multi-Tenant',
                              description:
                                  'Setiap kantin memiliki subdomain khusus (misal: saycoffee.ekasir.my.id) dan database profil kantin tersendiri.',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // DEMO SHOWCASE CARD
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 20.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 40 : 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF334155),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DEMO KANTIN AKTIF',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Coba Demo Pemesanan "Say Coffee"',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Lihat bagaimana alur pemesanan makanan & minuman pelanggan, pemilihan topping, keranjang belanja, hingga status pembayaran.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _openDemoTenant(context),
                                  icon: const Icon(Icons.coffee_rounded, size: 18),
                                  label: const Text('Buka Menu Pemesanan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(RouteName.adminLogin);
                                  },
                                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                                  label: const Text('Login Pengelola / Kasir'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xFF475569)),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 32),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 64,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // FOOTER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      'eKasir • Platform Kasir Digital & Self-Order QR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Multi-Tenant Cloud POS System • https://ekasir.my.id',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF16A34A)),
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
