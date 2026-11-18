import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/shop_scope.dart';
import '../../core/theme/app_tokens.dart';
import '../../models/password_strength.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/shop_snack.dart';

/// Register page; form/validation owned by [AuthController].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register(AuthController auth) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final String? error = await auth.register(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (error != null && mounted) {
      ShopSnack.show(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AuthController auth = ShopScope.of(context).auth;
    final PasswordStrength strength = AuthController.strengthOf(
      _passwordController.text,
    );

    return AuthScaffold(
      onBack: auth.showSignIn,
      trailing: IconButton(
        key: const Key('register_help_button'),
        tooltip: 'Why we ask for this',
        onPressed: () => _showPrivacyNote(context),
        icon: const Icon(Icons.shield_outlined),
      ),
      title: 'Create your account',
      subtitle:
          'One account for the catalog, your saved cart and your order history.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            'Already have an account?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            key: const Key('sign_in_link'),
            onPressed: auth.showSignIn,
            child: const Text('Sign in'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              key: const Key('name_field'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Ada Lovelace',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: AuthController.validateName,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const Key('email_field'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@school.edu',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: AuthController.validateEmail,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const Key('password_field'),
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least ${AuthController.minPasswordLength} characters',
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
            const SizedBox(height: AppSpacing.sm),
            _StrengthMeter(strength: strength),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const Key('confirm_field'),
              controller: _confirmController,
              obscureText: _obscureConfirmation,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(auth),
              decoration: InputDecoration(
                labelText: 'Repeat password',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  key: const Key('toggle_confirmation'),
                  tooltip: _obscureConfirmation
                      ? 'Show password'
                      : 'Hide password',
                  icon: Icon(
                    _obscureConfirmation
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmation = !_obscureConfirmation,
                  ),
                ),
              ),
              validator: (String? value) => AuthController.validateConfirmation(
                _passwordController.text,
                value,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('create_account_button'),
              onPressed: auth.isBusy ? null : () => _register(auth),
              icon: auth.isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded),
              label: Text(auth.isBusy ? 'Creating account' : 'Create account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPrivacyNote(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.card),
      builder: (BuildContext sheetContext) {
        final ThemeData sheetTheme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              0,
              AppSpacing.page,
              AppSpacing.page,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Your data stays on this device',
                  style: sheetTheme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'This is a coursework demo, so nothing leaves the phone. '
                  'The name, email and cart you type are stored with '
                  'SharedPreferences and are wiped when you sign out.',
                  style: sheetTheme.textTheme.bodyMedium?.copyWith(
                    color: sheetTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  key: const Key('close_privacy_note'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Four-segment password strength meter.
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final PasswordStrength strength;

  Color _color(ColorScheme scheme) {
    if (strength == PasswordStrength.tooShort) return scheme.outlineVariant;
    if (strength == PasswordStrength.weak) return scheme.error;
    if (strength == PasswordStrength.fair) return scheme.tertiary;
    if (strength == PasswordStrength.good) return scheme.primary;
    return scheme.tertiary;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color color = _color(scheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int segment = 1; segment <= 4; segment++) ...<Widget>[
              Expanded(
                child: AnimatedContainer(
                  key: Key('strength_segment_$segment'),
                  duration: AppMotion.medium,
                  curve: AppMotion.enter,
                  height: 5,
                  decoration: BoxDecoration(
                    color: segment <= strength.filledSegments
                        ? color
                        : scheme.surfaceContainerHighest,
                    borderRadius: AppRadii.chip,
                  ),
                ),
              ),
              if (segment < 4) const SizedBox(width: AppSpacing.xxs),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strength.isAcceptable
              ? 'Password strength: ${strength.label}'
              : 'Use at least ${AuthController.minPasswordLength} characters',
          key: const Key('strength_label'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: strength == PasswordStrength.weak
                ? scheme.error
                : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
