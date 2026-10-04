import 'package:flutter/material.dart';
import '../../router/route_name.dart';
import '../../shared/auth/auth_session.dart';
import '../../shared/constants/user_role.dart';
import '../../shared/services/demo_session_manager.dart';

/// Halaman Portal Demo Interaktif untuk Calon Pembeli Website
/// Menampilkan panduan alur 3 halaman:
/// 1. Halaman Pelanggan (Self-Order Meja)
/// 2. Halaman Kasir POS
/// 3. Halaman Manager & Admin
/// Dilengkapi kredensial demo dan jaminan isolasi browser lokal.
class DemoHubPage extends StatelessWidget {
  const DemoHubPage({super.key});

  void _loginAndNavigate(BuildContext context, DemoCredential cred) {
    DemoSessionManager.enableDemoMode();
    final result = DemoSessionManager.tryDemoLogin(cred.email, cred.password);
    if (result != null) {
      AuthSession().setSession(
        token: result.token,
        user: result.user,
        tenant: result.tenant,
      );

      switch (cred.role) {
        case UserRole.cashier:
        case UserRole.operations:
          Navigator.of(context).pushNamed(RouteName.cashierOrders);
          break;
        case UserRole.manager:
          Navigator.of(context).pushNamed(RouteName.managerDashboard);
          break;
        case UserRole.admin:
        case UserRole.superadmin:
          Navigator.of(context).pushNamed(RouteName.adminDashboard);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    final isMobile = size.width <= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
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
                horizontal: isDesktop ? 48 : 14,
                vertical: 8,
              ),
              child: Row(
                children: [
                  if (isMobile) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
                      tooltip: 'Kembali ke Beranda',
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacementNamed(RouteName.landingPage);
                        }
                      },
                    ),
                    const SizedBox(width: 2),
                  ],
                  InkWell(
                    onTap: () {
                      Navigator.of(context)
                          .pushReplacementNamed(RouteName.landingPage);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isMobile ? 'Demo Hub' : 'eKasir Demo Hub',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (!isMobile)
                              const Text(
                                'Simulasi Interaktif Calon Pembeli',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!isMobile) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(RouteName.landingPage);
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Beranda'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(RouteName.buyWebsite);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 15),
                    label: Text(isMobile ? 'Beli' : 'Beli Website'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16, vertical: 8),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge Portal
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded,
                            size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isMobile
                                ? 'PORTAL UJI COBA CALON PEMBELI'
                                : 'PANDUAN & PORTAL UJI COBA CALON PEMBELI',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Color(0xFF1D4ED8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    'Eksplorasi Lengkap Sistem eKasir dari 3 Sudut Pandang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isDesktop ? 32 : (isTablet ? 26 : 22),
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: const Text(
                      'Rasakan bagaimana alur pemesanan mandiri oleh pembeli langsung terhubung secara instan ke layar kasir dan laporan omzet manager. Semua data demo tersimpan secara terisolasi di browser Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Privacy / Sandbox Guarantee Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            color: Color(0xFF16A34A), size: 22),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Uji Coba Anda Aman & Terisolasi (Local Browser Sandbox)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pesanan atau perubahan menu yang Anda lakukan di mode demo hanya muncul di browser perangkat ini dan TIDAK akan tampil di layar orang lain.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Kartu Pengalaman Pelanggan
                  _buildCustomerCard(context),
                  const SizedBox(height: 36),

                  // Tabel Kredensial Demo Terbuka
                  _buildCredentialsTable(context),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Kartu Pelanggan
  Widget _buildCustomerCard(BuildContext context) {
    return _WalkthroughCard(
      stepNumber: '1',
      badge: 'UNTUK PEMBELI RESTO',
      badgeColor: const Color(0xFF2563EB),
      badgeBg: const Color(0xFFEFF6FF),
      title: 'Halaman Pelanggan (Self-Order Meja)',
      description:
          'Simulasi pembeli duduk di meja kafe/resto. Scan QR meja, pilih aneka makanan & minuman favorit (17 menu foto lezat), pilih topping, dan checkout mandiri.',
      features: const [
        'Katalog 17 menu makanan & minuman',
        'Pilih topping & catatan pesanan',
        'Pilih nomor meja (Meja 01 - 10)',
        'Status pesanan realtime & QRIS',
      ],
      buttonLabel: 'Coba Pesan Sebagai Pembeli ➜',
      buttonColor: const Color(0xFF2563EB),
      onTap: () {
        DemoSessionManager.enableDemoMode();
        Navigator.of(context).pushNamed(RouteName.customerMenu);
      },
    );
  }

  // Tabel Kredensial Demo
  Widget _buildCredentialsTable(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.key_rounded,
                    color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar Akun & Password Uji Coba',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Klik tombol "Masuk" untuk simulasi login otomatis tanpa ketik manual',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...DemoSessionManager.demoCredentials.map((cred) {
            if (isMobile) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Color(cred.badgeColor).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              cred.role == UserRole.cashier
                                  ? Icons.point_of_sale_rounded
                                  : (cred.role == UserRole.manager
                                      ? Icons.insights_rounded
                                      : Icons.admin_panel_settings_rounded),
                              color: Color(cred.badgeColor),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cred.roleName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                cred.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Email: ',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                              Expanded(
                                child: Text(
                                  cred.email,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'Password: ',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                              Text(
                                cred.password,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () => _loginAndNavigate(context, cred),
                        icon: const Icon(Icons.login_rounded, size: 15),
                        label: Flexible(
                          child: Text(
                            'Masuk Simulasi ${cred.roleName}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(cred.badgeColor),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(cred.badgeColor).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        cred.role == UserRole.cashier
                            ? Icons.point_of_sale_rounded
                            : (cred.role == UserRole.manager
                                ? Icons.insights_rounded
                                : Icons.admin_panel_settings_rounded),
                        color: Color(cred.badgeColor),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cred.roleName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text(
                              'Email: ',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            Text(
                              cred.email,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Password: ',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            Text(
                              cred.password,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cred.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _loginAndNavigate(context, cred),
                    icon: const Icon(Icons.login_rounded, size: 14),
                    label: const Text(
                      'Masuk',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(cred.badgeColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WalkthroughCard extends StatelessWidget {
  final String stepNumber;
  final String badge;
  final Color badgeColor;
  final Color badgeBg;
  final String title;
  final String description;
  final List<String> features;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onTap;

  const _WalkthroughCard({
    required this.stepNumber,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.title,
    required this.description,
    required this.features,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 15, color: buttonColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
