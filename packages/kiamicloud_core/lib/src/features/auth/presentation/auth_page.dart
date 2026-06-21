import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../bootstrap/kiami_google_sign_in.dart';
import '../../../constants/kiami_strings.dart';
import '../../../firebase/kiami_firebase.dart';
import '../../../routing/kiami_routes.dart';
import '../../../theme/kiami_colors.dart';
import '../../../theme/kiami_decorations.dart';
import '../../../utils/kiami_layout.dart';
import '../../../widgets/kiami_button.dart';
import '../../../widgets/kiami_card.dart';
import '../../../widgets/kiami_logo_bar.dart';
import '../data/auth_exception_messages.dart';
import '../domain/kiami_user.dart';
import '../providers/auth_providers.dart';
import 'forgot_password_dialog.dart';

enum _AuthMode { login, register }

/// Autenticação Firebase — e-mail, Google e recuperação de senha.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _AuthMode _mode = _AuthMode.login;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_mode == _AuthMode.login) {
        await repo.signInWithEmail(email: email, password: password);
      } else {
        await repo.registerWithEmail(email: email, password: password);
      }
      if (mounted) context.go(KiamiRoutes.home);
    } catch (e) {
      setState(() => _errorMessage = AuthExceptionMessages.fromObject(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isDesktop {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);
  }

  bool get _canUseGoogle =>
      !_isDesktop || KiamiGoogleSignIn.isDesktopRegistered;

  bool get _showDesktopGoogleHint => _isDesktop && !_canUseGoogle;

  Future<void> _signInGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    var keepLoading = false;
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) context.go(KiamiRoutes.home);
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'redirect-initiated') {
        keepLoading = true;
        return;
      }
      setState(() => _errorMessage = AuthExceptionMessages.fromObject(e));
    } finally {
      if (mounted && !keepLoading) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<KiamiUser?>>(authStateProvider, (previous, next) {
      if (next.valueOrNull != null && mounted) {
        context.go(KiamiRoutes.home);
      }
    });

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: KiamiDecorations.authBackgroundFor(brightness),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: isWide
                  ? kiamiScrollPadding(
                      context,
                      left: 24,
                      top: 24,
                      right: 24,
                      bottomExtra: 24,
                    )
                  : kiamiScrollPadding(
                      context,
                      left: 0,
                      top: 0,
                      right: 0,
                      bottomExtra: 24,
                    ),
              child: isWide
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _BrandPanel(isDark: isDark)),
                            const SizedBox(width: 32),
                            Expanded(
                              child: _AuthFormCard(
                                child: _buildForm(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _AuthLoginLogo(),
                        const SizedBox(height: 28),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: _AuthFormCard(child: _buildForm()),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _mode == _AuthMode.login
                ? KiamiStrings.authTitle
                : KiamiStrings.registerTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _mode == _AuthMode.login
                ? KiamiStrings.authSubtitle
                : KiamiStrings.registerSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (!KiamiFirebase.isConfigured) ...[
            const SizedBox(height: 16),
            const _FirebaseSetupBanner(),
          ],
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: KiamiStrings.emailLabel,
              prefixIcon: Icon(Icons.email_outlined, size: 22),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enabled: !_loading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Introduza o e-mail.';
              if (!v.contains('@')) return 'E-mail inválido.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: KiamiStrings.passwordLabel,
              prefixIcon: const Icon(Icons.lock_outline, size: 22),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 22,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            enabled: !_loading,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Introduza a palavra-passe.';
              if (_mode == _AuthMode.register && v.length < 6) {
                return 'Mínimo 6 caracteres.';
              }
              return null;
            },
          ),
          if (_mode == _AuthMode.login)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed:
                    _loading ? null : () => showForgotPasswordDialog(context),
                child: const Text(KiamiStrings.forgotPassword),
              ),
            ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          KiamiButton(
            label: _mode == _AuthMode.login
                ? KiamiStrings.loginButton
                : KiamiStrings.registerButton,
            icon: _mode == _AuthMode.login ? Icons.login : Icons.person_add,
            isLoading: _loading,
            onPressed: _loading ? null : _submitEmail,
          ),
          if (_showDesktopGoogleHint) ...[
            const SizedBox(height: 12),
            const _DesktopGoogleHint(),
          ],
          const SizedBox(height: 12),
          KiamiButton(
            label: KiamiStrings.googleButton,
            variant: KiamiButtonVariant.secondary,
            icon: Icons.g_mobiledata_rounded,
            isLoading: _loading,
            onPressed: _loading || !_canUseGoogle ? null : _signInGoogle,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _mode = _mode == _AuthMode.login
                          ? _AuthMode.register
                          : _AuthMode.login;
                      _errorMessage = null;
                    }),
            child: Text(
              _mode == _AuthMode.login
                  ? KiamiStrings.switchToRegister
                  : KiamiStrings.switchToLogin,
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo barra no login (sem card / ícone extra).
class _AuthLoginLogo extends StatelessWidget {
  const _AuthLoginLogo({this.compact = false});

  final bool compact;

  static const double _scale = 1.2;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoHeight = (compact ? 48.0 : 64.0) * _scale;
    final maxLogoWidth = compact
        ? 260.0 * _scale
        : (width - 48).clamp(280.0, 400.0) * _scale;

    return KiamiLogoBar(
      height: logoHeight,
      maxWidth: maxLogoWidth,
      onDarkBackground: isDark,
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KiamiCard(
      padding: const EdgeInsets.all(28),
      child: child,
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: KiamiDecorations.authBrandPanelGradient,
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusXl),
        boxShadow: [
          BoxShadow(
            color: KiamiColors.deepBlue.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: _AuthLoginLogo(compact: true),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  KiamiStrings.slogan,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  KiamiStrings.authBrandHint,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: KiamiColors.softWhite.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopGoogleHint extends StatelessWidget {
  const _DesktopGoogleHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.computer_outlined, color: scheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              KiamiStrings.googleDesktopNotConfigured,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _FirebaseSetupBanner extends StatelessWidget {
  const _FirebaseSetupBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KiamiColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KiamiDecorations.radiusMd),
        border: Border.all(color: KiamiColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: KiamiColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              KiamiStrings.firebaseNotConfigured,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: KiamiColors.textPrimary(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
