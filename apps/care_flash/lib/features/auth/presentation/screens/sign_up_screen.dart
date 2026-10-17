import 'package:care_flash/features/auth/bloc/auth_bloc.dart';
import 'package:care_flash/features/auth/bloc/auth_event.dart';
import 'package:care_flash/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              AuthTextField(
                controller: _passwordController,
                label: 'Password',
                isPassword: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                          SignUpRequested(
                            email: _emailController.text,
                            password: _passwordController.text,
                          ),
                        );
                  }
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
