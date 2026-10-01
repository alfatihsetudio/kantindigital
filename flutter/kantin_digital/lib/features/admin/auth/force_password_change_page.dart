import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../router/route_name.dart';
import '../../../shared/auth/auth_session.dart';

class ForcePasswordChangePage extends StatefulWidget {
  const ForcePasswordChangePage({super.key});

  @override
  State<ForcePasswordChangePage> createState() =>
      _ForcePasswordChangePageState();
}

class _ForcePasswordChangePageState extends State<ForcePasswordChangePage> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassword.text.length < 8 ||
        _newPassword.text != _confirmation.text) {
      _notify(
        'Password baru minimal 8 karakter dan konfirmasi harus sama.',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiClient().post(
        '/change-password',
        body: {
          'current_password': _currentPassword.text,
          'new_password': _newPassword.text,
        },
      );
      final user = AuthSession().user;
      if (user == null || !mounted) return;
      AuthSession().updateUser(user.copyWith(mustChangePassword: false));
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RouteName.adminLogin, (route) => false);
    } catch (error) {
      if (mounted) {
        _notify('Gagal mengganti password: $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _logout() async {
    try {
      await ApiClient().post('/logout');
    } catch (error) {
      if (mounted) {
        _notify('Sesi keluar dari server gagal: $error', isError: true);
      }
    } finally {
      AuthSession().clear();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RouteName.adminLogin, (route) => false);
      }
    }
  }

  void _notify(String message, {bool isError = false}) {
    TopNotification.show(
      message: message,
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      icon: isError ? Icons.error_rounded : Icons.check_circle_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Amankan akun'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: _submitting ? null : _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ganti password sementara',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Untuk keamanan, buat password baru sebelum menggunakan aplikasi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _passwordField(_currentPassword, 'Password sementara'),
                    _passwordField(
                      _newPassword,
                      'Password baru (minimal 8 karakter)',
                    ),
                    _passwordField(_confirmation, 'Konfirmasi password baru'),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _changePassword,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan password baru'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
