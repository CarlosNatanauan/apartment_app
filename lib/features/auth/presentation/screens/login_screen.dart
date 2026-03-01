import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      print('📧 Email changed: ${_emailController.text}');
    });
    _passwordController.addListener(() {
      print('🔒 Password changed: ${_passwordController.text}');
    });
    print('🎬 LoginScreen initState called');
  }

  @override
  void dispose() {
    print('💀 LoginScreen dispose called');
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Widget _buildErrorText(String error) {
    if (error.contains(', ')) {
      final errors = error.split(', ');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors
            .map((err) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              color: AppTheme.errorColor, fontSize: 14)),
                      Expanded(
                        child: Text(err,
                            style: const TextStyle(
                                color: AppTheme.errorColor, fontSize: 14)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
    }
    return Text(error,
        style: const TextStyle(color: AppTheme.errorColor, fontSize: 14));
  }

  Future<void> _handleGoogleSignIn() async {
    ref.read(authProvider.notifier).clearError();
    try {
      await GoogleSignIn.instance.signOut();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Google sign-in failed: no ID token received')));
        }
        return;
      }
      if (!mounted) return;
      await ref.read(authProvider.notifier).googleSignIn(idToken);
    } catch (e) {
      if (!mounted) return;
      final isBackendError = ref.read(authProvider).error != null;
      if (!isBackendError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google sign-in error: $e')));
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _passwordController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _passwordController.text.length,
            );
            _passwordFocusNode.requestFocus();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = ref.watch(authProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF2563EB),
        body: Stack(
          children: [
            // Full-screen gradient — fills corner gaps behind the white card
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // ── Brand header ───────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(32, topPadding + 36, 32, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.apartment_outlined,
                        size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // App name
                  const Text(
                    'SpaceNest',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Tagline
                  Text(
                    'Smart rental management',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // ── Form section ───────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    MediaQuery.of(context).padding.bottom + 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle indicator
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 10, bottom: 22),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Screen title
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in to your account',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error banner
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              SizeTransition(
                            sizeFactor: animation,
                            child: FadeTransition(
                                opacity: animation, child: child),
                          ),
                          child: authState.error != null
                              ? Container(
                                  key: const ValueKey('error'),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppTheme.errorColor
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2),
                                        child: const Icon(
                                            Icons.error_outline,
                                            color: AppTheme.errorColor,
                                            size: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: _buildErrorText(
                                              authState.error!)),
                                      GestureDetector(
                                        onTap: () => ref
                                            .read(authProvider.notifier)
                                            .clearError(),
                                        child: const Icon(Icons.close,
                                            color: AppTheme.errorColor,
                                            size: 18),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('no-error')),
                        ),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !authState.isLoading,
                          onChanged: (_) {
                            if (authState.error != null) {
                              ref
                                  .read(authProvider.notifier)
                                  .clearError();
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !authState.isLoading,
                          onChanged: (_) {
                            if (authState.error != null) {
                              ref
                                  .read(authProvider.notifier)
                                  .clearError();
                            }
                          },
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Login button
                        _GradientButton(
                          onPressed:
                              authState.isLoading ? null : _handleLogin,
                          isLoading: authState.isLoading,
                          label: 'Login',
                        ),
                        const SizedBox(height: 16),

                        // Or divider
                        const _OrDivider(),
                        const SizedBox(height: 16),

                        // Google button
                        SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : _handleGoogleSignIn,
                            icon: Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              height: 20,
                              width: 20,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.g_mobiledata, size: 22),
                            ),
                            label: const Text('Continue with Google'),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: authState.isLoading
                                  ? null
                                  : () => context.go('/auth/register'),
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? const LinearGradient(
                colors: [Color(0xFF1E40AF), AppTheme.primaryColor],
              )
            : null,
        color: isEnabled ? null : AppTheme.borderColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppTheme.borderColor)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.borderColor)),
      ],
    );
  }
}
