import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/core/auth/auth_repository.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      if (_isSignUp) {
        await client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          data: {'full_name': _nameCtrl.text.trim()},
        );
      } else {
        await client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Ocurrió un error inesperado.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Envía el correo de recuperación.
  ///
  /// El flujo completo faltaba entero: `AuthRepository` tenía 31 líneas y solo
  /// exponía `signUp`, `signIn` y `signOut`, y ninguna pantalla ofrecía
  /// siquiera el enlace. Un usuario que olvidara su contraseña se quedaba
  /// fuera de su cuenta para siempre.
  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      setState(() {
        _error = 'Escribe tu correo y vuelve a tocar "¿Olvidaste tu contraseña?".';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthRepository(
      Supabase.instance.client,
    ).sendPasswordReset(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.ok) {
      setState(() => _error = result.messageEs);
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revisa tu correo'),
        content: Text(
          result.messageEs ??
              'Si ese correo tiene una cuenta, te enviamos un enlace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Crear cuenta' : 'Iniciar sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_isSignUp)
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
            if (_isSignUp) const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isSignUp ? 'Crear cuenta' : 'Entrar'),
              ),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                      });
                    },
              child: Text(_isSignUp ? 'Ya tengo cuenta' : 'No tengo cuenta'),
            ),
            if (!_isSignUp)
              TextButton(
                onPressed: _isLoading ? null : _forgotPassword,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
          ],
        ),
      ),
    );
  }
}
