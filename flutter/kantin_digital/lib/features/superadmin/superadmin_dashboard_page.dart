import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/top_notification.dart';
import '../../router/route_name.dart';
import '../../shared/auth/auth_session.dart';
import '../../shared/models/managed_tenant_model.dart';
import 'superadmin_service.dart';

class SuperAdminDashboardPage extends StatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  State<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends State<SuperAdminDashboardPage> {
  final _service = SuperAdminService();
  late Future<List<ManagedTenantModel>> _tenants;

  @override
  void initState() {
    super.initState();
    _tenants = _service.fetchTenants();
  }

  void _reload() {
    setState(() => _tenants = _service.fetchTenants());
  }

  Future<void> _showTenantForm({ManagedTenantModel? tenant}) async {
    final name = TextEditingController(text: tenant?.name ?? '');
    final subdomain = TextEditingController(text: tenant?.subdomain ?? '');
    final emailDomain = _tenantWebDomain();
    final expiresAt = TextEditingController(
      text: tenant?.expiresAt?.split('T').first ?? '',
    );
    final address = TextEditingController(text: tenant?.address ?? '');
    final phone = TextEditingController(text: tenant?.phone ?? '');
    final whatsapp = TextEditingController(text: tenant?.whatsapp ?? '');
    final ownerName = TextEditingController();
    final ownerEmail = TextEditingController();
    final managerName = TextEditingController(text: 'Manager');
    final managerEmail = TextEditingController();
    final cashierName = TextEditingController(text: 'Kasir');
    final cashierEmail = TextEditingController();
    final operationsName = TextEditingController(text: 'Operasional');
    final operationsEmail = TextEditingController();
    bool subdomainManuallyEdited = tenant != null;
    bool managerEmailManuallyEdited = false;
    bool cashierEmailManuallyEdited = false;
    bool operationsEmailManuallyEdited = false;
    String plan = tenant?.plan ?? 'free';
    bool isActive = tenant?.isActive ?? true;
    bool submitting = false;

    void updateDefaultEmails(String value) {
      final slug = _slugify(value);
      if (slug.isEmpty) return;
      if (!managerEmailManuallyEdited) {
        managerEmail.text = 'manager@$slug.$emailDomain';
      }
      if (!cashierEmailManuallyEdited) {
        cashierEmail.text = 'kasir@$slug.$emailDomain';
      }
      if (!operationsEmailManuallyEdited) {
        operationsEmail.text = 'operasional@$slug.$emailDomain';
      }
    }

    if (tenant != null) updateDefaultEmails(tenant.subdomain);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tenant == null ? 'Tambah Tenant' : 'Pengaturan Tenant'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(
                    name,
                    'Nama usaha',
                    onChanged: (value) {
                      if (tenant == null && !subdomainManuallyEdited) {
                        final slug = _slugify(value);
                        subdomain.text = slug;
                        updateDefaultEmails(slug);
                        setDialogState(() {});
                      }
                    },
                  ),
                  _field(
                    subdomain,
                    'Subdomain',
                    hint: 'contoh: kantin-sri',
                    enabled: tenant == null,
                    suffixText: '.${_tenantWebDomain()}',
                    onChanged: (value) {
                      subdomainManuallyEdited = true;
                      updateDefaultEmails(value);
                      setDialogState(() {});
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: plan,
                    decoration: const InputDecoration(labelText: 'Paket'),
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Free')),
                      DropdownMenuItem(value: 'basic', child: Text('Basic')),
                      DropdownMenuItem(value: 'pro', child: Text('Pro')),
                    ],
                    onChanged: submitting
                        ? null
                        : (value) => setDialogState(() => plan = value ?? plan),
                  ),
                  _field(
                    expiresAt,
                    'Tanggal kedaluwarsa (opsional)',
                    hint: 'YYYY-MM-DD',
                  ),
                  _field(address, 'Alamat', maxLines: 2),
                  _field(phone, 'Telepon'),
                  _field(whatsapp, 'WhatsApp'),
                  if (tenant == null) ...[
                    const Divider(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Akun pemilik kantin',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    _field(ownerName, 'Nama pemilik'),
                    _field(ownerEmail, 'Email pemilik'),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Akun manager, kasir, dan operasional',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    _field(managerName, 'Nama manager'),
                    _field(
                      managerEmail,
                      'Email manager',
                      onChanged: (_) => managerEmailManuallyEdited = true,
                    ),
                    _field(cashierName, 'Nama kasir'),
                    _field(
                      cashierEmail,
                      'Email kasir',
                      onChanged: (_) => cashierEmailManuallyEdited = true,
                    ),
                    _field(operationsName, 'Nama operasional'),
                    _field(
                      operationsEmail,
                      'Email operasional',
                      onChanged: (_) => operationsEmailManuallyEdited = true,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Password sementara dibuat otomatis dan hanya ditampilkan satu kali setelah tenant dibuat. Setiap pengguna wajib menggantinya saat login pertama.',
                      ),
                    ),
                  ] else ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isActive ? 'Tenant aktif' : 'Tenant nonaktif',
                      ),
                      subtitle: Text(
                        isActive
                            ? 'Tenant dapat mengakses aplikasinya'
                            : 'Akses tenant dihentikan',
                      ),
                      value: isActive,
                      onChanged: submitting
                          ? null
                          : (value) => setDialogState(() => isActive = value),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.manage_accounts_rounded),
                      label: const Text('Kelola Pengguna & Reset Password'),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _showManageUsersDialog(tenant);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (name.text.trim().isEmpty ||
                          subdomain.text.trim().isEmpty) {
                        _notify(
                          'Nama dan subdomain wajib diisi',
                          isError: true,
                        );
                        return;
                      }
                      if (tenant == null &&
                          (ownerName.text.trim().isEmpty ||
                              ownerEmail.text.trim().isEmpty ||
                              managerName.text.trim().isEmpty ||
                              managerEmail.text.trim().isEmpty ||
                              cashierName.text.trim().isEmpty ||
                              cashierEmail.text.trim().isEmpty ||
                              operationsName.text.trim().isEmpty ||
                              operationsEmail.text.trim().isEmpty)) {
                        _notify(
                          'Lengkapi nama dan email untuk keempat akun.',
                          isError: true,
                        );
                        return;
                      }

                      setDialogState(() => submitting = true);
                      final data = <String, dynamic>{
                        'name': name.text.trim(),
                        'subdomain': subdomain.text.trim().toLowerCase(),
                        'plan': plan,
                        'expires_at': expiresAt.text.trim().isEmpty
                            ? null
                            : expiresAt.text.trim(),
                        'address': address.text.trim(),
                        'phone': phone.text.trim(),
                        'whatsapp': whatsapp.text.trim(),
                      };
                      List<Map<String, dynamic>> initialAccounts = [];
                      try {
                        if (tenant == null) {
                          data.addAll({
                            'owner_name': ownerName.text.trim(),
                            'owner_email': ownerEmail.text.trim(),
                            'manager_name': managerName.text.trim(),
                            'manager_email': managerEmail.text.trim(),
                            'cashier_name': cashierName.text.trim(),
                            'cashier_email': cashierEmail.text.trim(),
                            'operations_name': operationsName.text.trim(),
                            'operations_email': operationsEmail.text.trim(),
                          });
                          initialAccounts = await _service.createTenant(data);
                        } else {
                          data['is_active'] = isActive;
                          await _service.updateTenant(tenant.id, data);
                        }
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        _reload();
                        if (tenant == null) {
                          await _showInitialAccounts(initialAccounts);
                        } else {
                          _notify('Pengaturan tenant berhasil disimpan');
                        }
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => submitting = false);
                        _notify('Gagal menyimpan: $error', isError: true);
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    subdomain.dispose();
    expiresAt.dispose();
    address.dispose();
    phone.dispose();
    whatsapp.dispose();
    ownerName.dispose();
    ownerEmail.dispose();
    managerName.dispose();
    managerEmail.dispose();
    cashierName.dispose();
    cashierEmail.dispose();
    operationsName.dispose();
    operationsEmail.dispose();
  }

  Future<void> _showInitialAccounts(List<Map<String, dynamic>> accounts) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Akun awal berhasil dibuat'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simpan dan kirim setiap kredensial kepada penggunanya sekarang. Password sementara hanya ditampilkan kali ini.',
                ),
                const SizedBox(height: 16),
                ...accounts.map((account) {
                  final role = account['role'] == 'admin'
                      ? 'Owner'
                      : account['role'] == 'operations'
                      ? 'Operasional'
                      : account['role'].toString().toUpperCase();
                  final credentials =
                      '$role - ${account['name']}\n'
                      'Email: ${account['email']}\n'
                      'Password sementara: ${account['temporary_password']}';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: SelectableText(credentials)),
                          IconButton(
                            tooltip: 'Salin kredensial',
                            icon: const Icon(Icons.copy_rounded),
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: credentials),
                              );
                              if (dialogContext.mounted) {
                                _notify('Kredensial $role disalin');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Future<void> _showManageUsersDialog(ManagedTenantModel tenant) async {
    late Future<List<Map<String, dynamic>>> usersFuture;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          usersFuture = _service.fetchTenantUsers(tenant.id);
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Akun Pengguna: ${tenant.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Gagal memuat pengguna: ${snapshot.error}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => setDialogState(() {}),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Belum ada akun terdaftar.')),
                    );
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: users.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final role = user['role']?.toString() ?? 'user';
                        final roleName = _roleLabel(role);
                        final roleColor = _roleColor(role);
                        final mustChange = user['must_change_password'] == true ||
                            user['must_change_password'] == 1;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withValues(alpha: 0.15),
                            child: Icon(
                              role == 'admin'
                                  ? Icons.admin_panel_settings_rounded
                                  : (role == 'cashier'
                                      ? Icons.point_of_sale_rounded
                                      : (role == 'manager'
                                          ? Icons.badge_rounded
                                          : Icons.person_rounded)),
                              color: roleColor,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user['name']?.toString() ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  roleName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: roleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['email']?.toString() ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (mustChange)
                                const Text(
                                  '• Wajib ganti password',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          trailing: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                            icon: const Icon(Icons.lock_reset_rounded, size: 16),
                            label: const Text('Reset', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              _showResetPasswordDialog(
                                tenant,
                                user,
                                onUserUpdated: () => setDialogState(() {}),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showResetPasswordDialog(
    ManagedTenantModel tenant,
    Map<String, dynamic> user, {
    required VoidCallback onUserUpdated,
  }) async {
    final passwordController = TextEditingController();
    bool mustChangePassword = true;
    bool isSubmitting = false;

    void generateRandom() {
      passwordController.text = _generateRandomPassword();
    }

    generateRandom();

    await showDialog<void>(
      context: context,
      builder: (resetDialogContext) => StatefulBuilder(
        builder: (context, setResetState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reset Password: ${user['name']}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email: ${user['email']} (${_roleLabel(user['role']?.toString() ?? '')})',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password Baru',
                          hintText: 'Minimal 6 karakter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Acak password baru',
                      icon: const Icon(Icons.shuffle_rounded),
                      onPressed: () {
                        setResetState(() {
                          generateRandom();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Wajib ganti password saat login', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Pengguna diminta membuat password baru saat login', style: TextStyle(fontSize: 11)),
                  value: mustChangePassword,
                  onChanged: isSubmitting
                      ? null
                      : (val) => setResetState(() => mustChangePassword = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(resetDialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final newPwd = passwordController.text.trim();
                      if (newPwd.length < 6) {
                        _notify('Password minimal 6 karakter', isError: true);
                        return;
                      }

                      setResetState(() => isSubmitting = true);
                      try {
                        await _service.resetUserPassword(
                          user['id'],
                          newPassword: newPwd,
                          mustChangePassword: mustChangePassword,
                        );

                        if (!resetDialogContext.mounted) return;
                        Navigator.pop(resetDialogContext);
                        onUserUpdated();
                        _notify('Password ${user['name']} berhasil direset!');
                        _showResetSuccessDialog(tenant, user, newPwd);
                      } catch (e) {
                        if (!resetDialogContext.mounted) return;
                        setResetState(() => isSubmitting = false);
                        _notify('Gagal mereset password: $e', isError: true);
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
    passwordController.dispose();
  }

  Future<void> _showResetSuccessDialog(
    ManagedTenantModel tenant,
    Map<String, dynamic> user,
    String newPassword,
  ) async {
    final domain = _tenantWebDomain();
    final loginUrl = 'https://${tenant.subdomain}.$domain';
    final credentialsText =
        'Kredensial Akun Baru\n'
        'Toko: ${tenant.name}\n'
        'Nama: ${user['name']}\n'
        'Role: ${_roleLabel(user['role']?.toString() ?? '')}\n'
        'Email: ${user['email']}\n'
        'Password Baru: $newPassword\n'
        'Login di: $loginUrl';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Password Berhasil Direset'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Silakan salin kredensial berikut dan kirimkan ke pengguna yang bersangkutan:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                credentialsText,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Salin Kredensial'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: credentialsText));
              if (dialogContext.mounted) {
                _notify('Kredensial berhasil disalin ke clipboard');
              }
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Owner';
      case 'manager':
        return 'Manager';
      case 'cashier':
        return 'Kasir';
      case 'operations':
        return 'Operasional';
      case 'superadmin':
        return 'Superadmin';
      default:
        return role.toUpperCase();
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'manager':
        return Colors.indigo;
      case 'cashier':
        return Colors.teal;
      case 'operations':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  String _generateRandomPassword([int length = 10]) {
    const chars = '23456789abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ';
    final rand = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    int seed = rand;
    for (int i = 0; i < length; i++) {
      seed = (seed * 9301 + 49297) % 233280;
      buffer.write(chars[seed.abs() % chars.length]);
    }
    return buffer.toString();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool enabled = true,
    bool obscureText = false,
    int maxLines = 1,
    String? suffixText,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffixText,
        ),
      ),
    );
  }

  String _slugify(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  String _tenantWebDomain() {
    final host = Uri.base.host.toLowerCase();
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.test') ||
        host == 'kantindigital.test' ||
        host == '127.0.0.1' ||
        host == '192.168.0.8') {
      return 'kantindigital.test';
    }
    return 'ekasir.my.id';
  }

  void _notify(String message, {bool isError = false}) {
    if (!mounted) return;
    TopNotification.show(
      message: message,
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      icon: isError ? Icons.error_rounded : Icons.check_circle_rounded,
    );
  }

  Future<void> _logout() async {
    AuthSession().clear();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteName.adminLogin, (route) => false);
  }

  Future<void> _showPasswordDialog() async {
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmation = TextEditingController();
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ganti Password Superadmin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passwordField(currentPassword, 'Password saat ini'),
              _passwordField(newPassword, 'Password baru (min. 12 karakter)'),
              _passwordField(confirmation, 'Konfirmasi password baru'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (currentPassword.text.isEmpty ||
                          newPassword.text.length < 12 ||
                          newPassword.text != confirmation.text) {
                        _notify(
                          'Periksa password. Password baru minimal 12 karakter dan konfirmasi harus sama.',
                          isError: true,
                        );
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        await ApiClient().post(
                          '/change-password',
                          body: {
                            'current_password': currentPassword.text,
                            'new_password': newPassword.text,
                          },
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        _notify('Password superadmin berhasil diubah');
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => submitting = false);
                        _notify(
                          'Gagal mengganti password: $error',
                          isError: true,
                        );
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    currentPassword.dispose();
    newPassword.dispose();
    confirmation.dispose();
  }

  Widget _passwordField(TextEditingController controller, String label) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Superadmin Platform'),
        actions: [
          IconButton(
            tooltip: 'Ganti password',
            onPressed: _showPasswordDialog,
            icon: const Icon(Icons.key_rounded),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTenantForm(),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Tambah Tenant'),
      ),
      body: FutureBuilder<List<ManagedTenantModel>>(
        future: _tenants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final tenants = snapshot.data ?? const [];
          final activeCount = tenants
              .where((tenant) => tenant.isActive && !tenant.isExpired)
              .length;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Text(
                  'Pengaturan tenant dan akses platform',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total tenant',
                        value: '${tenants.length}',
                        icon: Icons.storefront_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Tenant aktif',
                        value: '$activeCount',
                        icon: Icons.verified_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Daftar Tenant',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (tenants.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada tenant. Tambahkan tenant pertama.',
                      ),
                    ),
                  )
                else
                  ...tenants.map(
                    (tenant) => _TenantCard(
                      tenant: tenant,
                      onEdit: () => _showTenantForm(tenant: tenant),
                      onManageUsers: () => _showManageUsersDialog(tenant),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.tenant,
    required this.onEdit,
    required this.onManageUsers,
  });

  final ManagedTenantModel tenant;
  final VoidCallback onEdit;
  final VoidCallback onManageUsers;

  @override
  Widget build(BuildContext context) {
    final statusColor = tenant.isActive && !tenant.isExpired
        ? AppColors.success
        : AppColors.danger;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        tenant.subdomain,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Kelola akun & reset password',
                  onPressed: onManageUsers,
                  icon: const Icon(Icons.manage_accounts_rounded),
                ),
                IconButton(
                  tooltip: 'Pengaturan tenant',
                  onPressed: onEdit,
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Tag(label: tenant.plan.toUpperCase()),
                _Tag(
                  label: tenant.isExpired
                      ? 'KEDALUWARSA'
                      : tenant.isActive
                      ? 'AKTIF'
                      : 'NONAKTIF',
                  color: statusColor,
                ),
                _Tag(label: '${tenant.usersCount} pengguna'),
                _Tag(label: '${tenant.menusCount} menu'),
                _Tag(label: '${tenant.ordersCount} pesanan'),
              ],
            ),
            if (tenant.expiresAt != null && tenant.expiresAt!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Berlaku sampai ${tenant.expiresAt!.split('T').first}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: activeColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    ),
  );
}
