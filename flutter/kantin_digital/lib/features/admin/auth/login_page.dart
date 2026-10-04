import 'package:flutter/material.dart';

import '../../../core/utils/validator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../router/route_name.dart';
import '../../../shared/services/demo_session_manager.dart';
import '../../../shared/services/tenant_service.dart';
import 'login_controller.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = AdminLoginController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pastikan keluar dari mode demo saat membuka halaman login resmi
    DemoSessionManager.disableDemoMode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final error = await _controller.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      onNavigate: (routeName) {
        Navigator.of(context).pushReplacementNamed(routeName);
      },
    );

    setState(() {
      _loading = false;
    });

    if (!mounted) return;

    if (error != null) {
      AppSnackBar.show(context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFF2563EB),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login Kasir & Admin Toko',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Masuk ke panel manajemen toko Anda',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Manual Form
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: Validator.email,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        obscureText: true,
                        validator: (v) =>
                            Validator.requiredText(v, label: 'Password'),
                      ),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: _loading ? 'Memproses Masuk...' : 'Masuk ke Sistem',
                        onPressed: _loading ? null : _onSubmit,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            if (TenantService.isRootDomain) {
                              Navigator.of(context)
                                  .pushReplacementNamed(RouteName.landingPage);
                            } else {
                              Navigator.of(context)
                                  .pushReplacementNamed(RouteName.customerMenu);
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(
                            TenantService.isRootDomain
                                ? 'Kembali ke Beranda Platform'
                                : 'Kembali ke Halaman Menu',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
