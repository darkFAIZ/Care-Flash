import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:care_flash/features/auth/bloc/auth_bloc.dart';
import 'package:care_flash/features/auth/bloc/auth_state.dart';
import 'package:care_flash/features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthUnauthenticated) {
            return const LoginScreen();
          }
          return const Scaffold(body: Center(child: Text('Home')));
        },
      ),
    );
  }
}
