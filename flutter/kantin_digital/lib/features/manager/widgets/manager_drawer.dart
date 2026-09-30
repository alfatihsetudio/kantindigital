import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../router/route_name.dart';
import '../../../shared/auth/auth_session.dart';
import '../../admin/auth/login_service.dart';

/// Modern Liquid Glass Drawer for Manager Role
/// Green Gojek theme with glassmorphism effects
class ManagerDrawer extends StatelessWidget {
  const ManagerDrawer({super.key});

  void _showChangePasswordDialog(BuildContext context) {
    final currentPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPwdCtrl,
              decoration: InputDecoration(
                labelText: 'Password Lama',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPwdCtrl,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPwdCtrl,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (currentPwdCtrl.text.isEmpty) {
                TopNotification.show(
                  message: 'Masukkan password lama',
                  backgroundColor: AppColors.warning,
                  icon: Icons.warning_rounded,
                );
                return;
              }
              if (newPwdCtrl.text != confirmPwdCtrl.text) {
                TopNotification.show(
                  message: 'Password baru tidak cocok',
                  backgroundColor: AppColors.warning,
                  icon: Icons.warning_rounded,
                );
                return;
              }
              if (newPwdCtrl.text.length < 6) {
                TopNotification.show(
                  message: 'Password minimal 6 karakter',
                  backgroundColor: AppColors.warning,
                  icon: Icons.warning_rounded,
                );
                return;
              }

              showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final auth = AdminAuthService();
                final user = AuthSession().user;
                
                // Verify
                await auth.login(email: user?.email ?? '', password: currentPwdCtrl.text);

                // Change
                final client = ApiClient();
                await client.post('/change-password', body: {
                  'user_id': user?.id,
                  'current_password': currentPwdCtrl.text,
                  'new_password': newPwdCtrl.text,
                });
                
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext); // Close loading
                Navigator.pop(dialogContext); // Close form
                
                if (!context.mounted) return;
                TopNotification.show(
                  message: 'Password berhasil diubah',
                  backgroundColor: AppColors.success,
                  icon: Icons.check_circle_rounded,
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                
                String msg = e.toString();
                if (msg.toLowerCase().contains('gagal') || msg.toLowerCase().contains('salah') || msg.contains('401')) {
                   msg = 'Password lama salah!';
                }
                
                TopNotification.show(
                  message: msg,
                  backgroundColor: AppColors.danger,
                  icon: Icons.error_rounded,
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final currentEmailCtrl = TextEditingController(text: AuthSession().user?.email ?? '');
    final newEmailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ganti Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan email baru dan password saat ini untuk konfirmasi.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: currentEmailCtrl,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email Saat Ini',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newEmailCtrl,
              decoration: InputDecoration(
                labelText: 'Email Baru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              decoration: InputDecoration(
                labelText: 'Password Saat Ini',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'Diperlukan untuk keamanan',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (newEmailCtrl.text.isEmpty || !newEmailCtrl.text.contains('@')) {
                TopNotification.show(
                  message: 'Email baru tidak valid',
                  backgroundColor: AppColors.warning,
                  icon: Icons.warning_rounded,
                );
                return;
              }
              if (passwordCtrl.text.isEmpty) {
                TopNotification.show(
                  message: 'Masukkan password untuk konfirmasi',
                  backgroundColor: AppColors.warning,
                  icon: Icons.warning_rounded,
                );
                return;
              }

              showDialog(
                context: dialogContext,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final auth = AdminAuthService();
                final user = AuthSession().user;
                await auth.login(email: user?.email ?? '', password: passwordCtrl.text);

                final client = ApiClient();
                await client.post('/update-profile', body: {
                  'user_id': user?.id,
                  'email': newEmailCtrl.text,
                });
                
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext); // Close loading
                Navigator.pop(dialogContext); // Close form

                if (!context.mounted) return;
                TopNotification.show(
                  message: 'Email berhasil diubah. Login ulang diperlukan.',
                  backgroundColor: AppColors.success,
                  icon: Icons.check_circle_rounded,
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                
                String msg = e.toString();
                if (msg.toLowerCase().contains('gagal') || msg.toLowerCase().contains('salah')) {
                   msg = 'Password salah!';
                }

                TopNotification.show(
                  message: msg,
                  backgroundColor: AppColors.danger,
                  icon: Icons.error_rounded,
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95), // Liquid effect
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(4, 0),
            )
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    route: RouteName.managerDashboard,
                    isActive: currentRoute == RouteName.managerDashboard,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  _DrawerItem(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Laporan Menu',
                    route: RouteName.managerMenus,
                    isActive: currentRoute == RouteName.managerMenus,
                  ),
                   _DrawerItem(
                    icon: Icons.category_rounded,
                    label: 'Laporan Kategori',
                    route: RouteName.managerCategories,
                    isActive: currentRoute == RouteName.managerCategories,
                  ),
                   _DrawerItem(
                    icon: Icons.people_rounded,
                    label: 'Laporan Karyawan',
                    route: RouteName.managerUsers,
                    isActive: currentRoute == RouteName.managerUsers,
                  ),
                   _DrawerItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Grafik Penjualan',
                    route: RouteName.managerSales,
                    isActive: currentRoute == RouteName.managerSales,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  _DrawerItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Ganti Password',
                    route: '',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showChangePasswordDialog(context);
                    },
                  ),
                   _DrawerItem(
                    icon: Icons.email_outlined,
                    label: 'Ganti Email',
                    route: '',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeEmailDialog(context);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.dangerLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: const Text(
                    'Keluar', 
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    AuthSession().clear();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      RouteName.adminLogin,
                      (route) => false,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = AuthSession().user;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.background,
              child: const Icon(Icons.business_center_rounded, color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? 'Manager',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user?.email ?? 'manager@kantin.com',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Pimpinan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = isActive;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {
            Navigator.pop(context); // Close drawer first
            if (!isActive) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.2)) 
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
