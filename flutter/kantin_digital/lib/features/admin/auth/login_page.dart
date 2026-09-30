import 'package:flutter/material.dart';

import '../../../core/utils/validator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../router/route_name.dart';
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login Staff',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      validator: Validator.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      obscureText: true,
                      validator: (v) => Validator.requiredText(v, label: 'Password'),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _loading ? 'Memproses...' : 'Masuk',
                      onPressed: _loading ? null : _onSubmit,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(RouteName.customerMenu);
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Kembali ke Halaman Pelanggan'),
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
    );
  }
}

