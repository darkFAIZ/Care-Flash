import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController =
      TextEditingController(text: 'alya.putri@ui.ac.id');
  final _passwordController = TextEditingController(text: 'secret123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    context.read<AuthBloc>().add(
          LoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.health_and_safety,
                  size: 64,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: 12),
                Text(
                  'Care-Merchant',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verified Student Caregiver Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'University Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitLogin,
                  child: const Text('Sign In as Caregiver'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    // Quick login as pending student
                    _emailController.text = 'budi.santoso@itb.ac.id';
                    _submitLogin();
                  },
                  child: const Text('Demo: Pending Student'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
