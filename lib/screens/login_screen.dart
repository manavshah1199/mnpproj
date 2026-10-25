import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Sign in, or create an account the first time.
class LoginScreen extends StatefulWidget {
  final ValueChanged<Account> onSignedIn;
  const LoginScreen({super.key, required this.onSignedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _creating = false; // false = sign in, true = create account
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_creating && _passwordController.text != _confirmController.text) {
      setState(() => _error = 'Passwords don\'t match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final account = _creating
          ? await AuthService.register(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await AuthService.signIn(
              email: _emailController.text,
              password: _passwordController.text,
            );
      widget.onSignedIn(account);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Icon(Icons.shield_outlined, size: 64, color: scheme.primary),
            const SizedBox(height: 8),
            const Text(
              'WeatherSafe',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Personal weather safety for you and your family',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Sign in')),
                ButtonSegment(value: true, label: Text('Create account')),
              ],
              selected: {_creating},
              onSelectionChanged: (s) => setState(() {
                _creating = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
            if (_creating)
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Your name'),
              ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: _creating ? 'At least 6 characters' : null,
                suffixIcon: IconButton(
                  icon: Icon(
                      _hidePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
              ),
            ),
            if (_creating)
              TextField(
                controller: _confirmController,
                obscureText: _hidePassword,
                decoration:
                    const InputDecoration(labelText: 'Confirm password'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_creating ? 'Create account' : 'Sign in'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your account is stored only on this phone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
