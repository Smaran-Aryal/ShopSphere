import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/shop_scope.dart';
import '../../core/theme/app_tokens.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/shop_snack.dart';

/// Sign in page; form/validation owned by [AuthController].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String demoEmail = 'student@school.edu';
  static const String demoPassword = 'flutter123';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn(AuthController auth) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final String? error = await auth.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (error != null && mounted) {
      ShopSnack.show(context, error);
    }
  }

  void _fillDemo() {
    setState(() {
      _emailController.text = demoEmail;
      _passwordController.text = demoPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AuthController auth = ShopScope.of(context).auth;

    return AuthScaffold(
      title: 'Welcome to Shop',
      subtitle:
          'Sign in to browse the catalog, filter it and keep your cart between sessions.',
      footer: Column(
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              TextButton(
                key: const Key('forgot_password_link'),
                onPressed: auth.showForgotPassword,
                child: const Text('Forgot password?'),
              ),
              Text(
                '·',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                key: const Key('register_link'),
                onPressed: auth.showRegister,
                child: const Text('Create account'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Icon(Icons.lock_rounded, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Demo: $demoEmail · $demoPassword',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              key: const Key('email_field'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: demoEmail,
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: AuthController.validateEmail,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const Key('password_field'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signIn(auth),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText:
                    'At least ${AuthController.minPasswordLength} characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  key: const Key('toggle_password'),
                  tooltip: _obscurePassword
                      ? 'Show password'
                      : 'Hide password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
              validator: AuthController.validatePassword,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const Key('sign_in_button'),
              onPressed: auth.isBusy ? null : () => _signIn(auth),
              child: auth.isBusy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('demo_account_button'),
              onPressed: _fillDemo,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Fill demo account'),
            ),
          ],
        ),
      ),
    );
  }
}
