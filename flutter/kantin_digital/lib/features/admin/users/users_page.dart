import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/constants/user_role.dart';
import '../../admin/widgets/admin_drawer.dart';
import 'users_controller.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminUsersController _controller = AdminUsersController();
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _controller.fetchUsers();
    });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pengguna?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        await _controller.deleteUser(id);
        _reload();
        if (!mounted) return;
        TopNotification.show(
          message: 'Pengguna berhasil dihapus',
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      } catch (e) {
        if (!mounted) return;
        TopNotification.show(
          message: 'Gagal menghapus: $e',
          backgroundColor: AppColors.danger,
          icon: Icons.error_rounded,
        );
      }
    }
  }

  Future<void> _showForm({UserModel? user}) async {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passwordCtrl = TextEditingController();
    String selectedRole = user?.role?.name ?? 'cashier';
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental close
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(user == null ? 'Tambah Pengguna' : 'Edit Pengguna'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    enabled: !isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    decoration: InputDecoration(
                      labelText: user == null ? 'Password' : 'Password Baru (opsional)',
                      helperText: user == null ? 'Wajib diisi (min. 6 karakter)' : 'Kosongkan jika tidak ingin mengubah',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                    enabled: !isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin/Operator')),
                      DropdownMenuItem(value: 'cashier', child: Text('Kasir/Pelayan')),
                      DropdownMenuItem(value: 'manager', child: Text('Pimpinan')),
                    ],
                    onChanged: isSubmitting ? null : (val) => setState(() => selectedRole = val ?? 'cashier'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  // 1. Local Validation
                  if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                    TopNotification.show(
                      message: 'Nama dan Email wajib diisi',
                      backgroundColor: AppColors.danger,
                      icon: Icons.error_rounded,
                    );
                    return;
                  }
                  
                  if (user == null && (passwordCtrl.text.isEmpty || passwordCtrl.text.length < 6)) {
                    TopNotification.show(
                      message: 'Password wajib diisi minimal 6 karakter',
                      backgroundColor: AppColors.danger,
                      icon: Icons.error_rounded,
                    );
                    return;
                  }

                  if (user != null && passwordCtrl.text.isNotEmpty && passwordCtrl.text.length < 6) {
                    TopNotification.show(
                      message: 'Password baru minimal 6 karakter',
                      backgroundColor: AppColors.danger,
                      icon: Icons.error_rounded,
                    );
                    return;
                  }

                  // 2. Prepare Data
                  final data = {
                    'name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'role': selectedRole,
                  };

                  if (passwordCtrl.text.isNotEmpty) {
                    data['password'] = passwordCtrl.text;
                  }

                  // 3. Submit
                  setState(() => isSubmitting = true);

                  try {
                    if (user == null) {
                      await _controller.addUser(data);
                    } else {
                      await _controller.editUser(user.id, data);
                    }
                    
                    // Success!
                    if (mounted) {
                       _reload();
                       TopNotification.show(
                        message: user == null ? 'Pengguna berhasil ditambah' : 'Pengguna berhasil diperbarui',
                        backgroundColor: AppColors.success,
                        icon: Icons.check_circle_rounded,
                      );
                      Navigator.pop(dialogContext); // Close ONLY on success
                    }
                  } catch (e) {
                    // Error!
                    if (context.mounted) {
                      setState(() => isSubmitting = false); // Stop loading
                      // Clean error message
                      String msg = e.toString();
                      if (msg.contains('ApiException')) {
                        msg = msg.replaceAll('ApiException:', '').trim();
                        // Try to parse message if json
                        // But for now raw message is better than nothing
                      }
                      
                      TopNotification.show(
                        message: 'Gagal: $msg',
                        backgroundColor: AppColors.danger,
                        icon: Icons.error_rounded,
                        duration: const Duration(seconds: 4),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.blue;
      case 'cashier':
        return Colors.orange;
      case 'manager':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin/Operator';
      case UserRole.cashier:
        return 'Kasir/Pelayan';
      case UserRole.manager:
        return 'Pimpinan';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      drawer: const AdminDrawer(),
      body: FutureBuilder<List<UserModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('Belum ada pengguna'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getRoleColor(user.role?.name).withValues(alpha: 0.1),
                    child: Icon(Icons.person, color: _getRoleColor(user.role?.name)),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role?.name).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRoleLabel(user.role),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(user.role?.name),
                          ),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showForm(user: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(user.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
