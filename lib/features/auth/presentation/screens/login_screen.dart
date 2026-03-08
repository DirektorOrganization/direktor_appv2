import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../shared/widgets/direktor_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController(text: 'diego@direktor.pe');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscureText = true;
  bool _keepSession = true;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 36),
              const DirektorLogo(size: 118, showLabel: true),
              const SizedBox(height: 10),
              const Text('Gestion de proyectos y restricciones', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Usuario o correo electronico')),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Contrasena',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                    icon: Icon(_obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              CheckboxListTile(
                value: _keepSession,
                contentPadding: EdgeInsets.zero,
                title: const Text('Mantener sesion iniciada'),
                onChanged: (value) => setState(() => _keepSession = value ?? false),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.projects),
                  child: const Text('Ingresar'),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('Olvidaste tu contrasena?')),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF2B6CB0), borderRadius: BorderRadius.circular(16)),
                child: const Text('Modo offline disponible.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),
              const Text('Conexion segura'),
              const SizedBox(height: 8),
              const Text('v1.0'),
            ],
          ),
        ),
      ),
    );
  }
}
