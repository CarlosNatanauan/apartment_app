import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'TENANT';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    try {
      await ref.read(authProvider.notifier).register(
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
            _selectedRole,
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
              padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: authState.isLoading
                            ? null
                            : () => context.go('/auth/login'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_ios_new,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // App icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.apartment_outlined,
                        size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  // App name
                  const Text(
                    'SpaceNest',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Tagline
                  Text(
                    'Smart rental management',
                    style: TextStyle(
                      fontSize: 13,
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
                            margin: const EdgeInsets.only(top: 10, bottom: 20),
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Join SpaceNest to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

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

                        // Role selector label
                        const Text(
                          'I want to join as',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Role cards
                        Row(
                          children: [
                            Expanded(
                              child: _RoleCard(
                                label: 'Tenant',
                                icon: Icons.person_outline,
                                description: 'Rent units &\nmanage payments',
                                gradient: const [
                                  Color(0xFF059669),
                                  AppTheme.tenantColor
                                ],
                                borderColor: AppTheme.tenantColor,
                                isSelected: _selectedRole == 'TENANT',
                                isEnabled: !authState.isLoading,
                                onTap: () {
                                  if (!authState.isLoading) {
                                    setState(() => _selectedRole = 'TENANT');
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _RoleCard(
                                label: 'Landlord',
                                icon: Icons.business_outlined,
                                description:
                                    'Manage properties\n& tenants',
                                gradient: const [
                                  Color(0xFF1E40AF),
                                  AppTheme.landlordColor
                                ],
                                borderColor: AppTheme.landlordColor,
                                isSelected: _selectedRole == 'LANDLORD',
                                isEnabled: !authState.isLoading,
                                onTap: () {
                                  if (!authState.isLoading) {
                                    setState(
                                        () => _selectedRole = 'LANDLORD');
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // First + Last name side by side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                focusNode: _firstNameFocusNode,
                                textCapitalization:
                                    TextCapitalization.words,
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
                                  labelText: 'First Name',
                                  hintText: 'First',
                                  prefixIcon:
                                      Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Min 2 chars';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                focusNode: _lastNameFocusNode,
                                textCapitalization:
                                    TextCapitalization.words,
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
                                  labelText: 'Last Name',
                                  hintText: 'Last',
                                  prefixIcon:
                                      Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Min 2 chars';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

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
                          textInputAction: TextInputAction.next,
                          enabled: !authState.isLoading,
                          onChanged: (_) {
                            if (authState.error != null) {
                              ref
                                  .read(authProvider.notifier)
                                  .clearError();
                            }
                          },
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
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          enabled: !authState.isLoading,
                          onChanged: (_) {
                            if (authState.error != null) {
                              ref
                                  .read(authProvider.notifier)
                                  .clearError();
                            }
                          },
                          onFieldSubmitted: (_) => _handleRegister(),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Register button
                        _GradientButton(
                          onPressed:
                              authState.isLoading ? null : _handleRegister,
                          isLoading: authState.isLoading,
                          label: 'Create Account',
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

                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: authState.isLoading
                                  ? null
                                  : () => context.go('/auth/login'),
                              child: const Text(
                                'Login',
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

// ── Role card ───────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final List<Color> gradient;
  final Color borderColor;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.description,
    required this.gradient,
    required this.borderColor,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // begin == end on first build so there's no unwanted initial animation.
    // On subsequent rebuilds TweenAnimationBuilder overwrites begin with the
    // current animated value, producing a smooth bi-directional transition.
    final targetT = isSelected ? 1.0 : 0.0;
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: targetT, end: targetT),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final iconColor =
              Color.lerp(borderColor, Colors.white, t)!;
          final labelColor =
              Color.lerp(AppTheme.textPrimary, Colors.white, t)!;
          final descColor = Color.lerp(
            AppTheme.textSecondary,
            Colors.white.withValues(alpha: 0.82),
            t,
          )!;
          final iconBgColor = Color.lerp(
            borderColor.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.22),
            t,
          )!;
          final activeBorderColor = Color.lerp(
            borderColor.withValues(alpha: 0.3),
            Colors.transparent,
            t,
          )!;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: activeBorderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.35 * t),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                children: [
                  // White base layer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    color: Colors.white,
                  ),
                  // Gradient overlay — fades in/out smoothly
                  Positioned.fill(
                    child: Opacity(
                      opacity: t,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradient,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content on top of both layers
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 26, color: iconColor),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            color: descColor,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────

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
