import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Keep state alive

final _formKey = GlobalKey<FormState>();
final _firstNameController = TextEditingController();  // 🆕 NEW
final _lastNameController = TextEditingController();   // 🆕 NEW
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _confirmPasswordController = TextEditingController();
final _firstNameFocusNode = FocusNode();   // 🆕 NEW
final _lastNameFocusNode = FocusNode();    // 🆕 NEW
final _emailFocusNode = FocusNode();
final _passwordFocusNode = FocusNode();
final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'TENANT'; // Default role

@override
void dispose() {
  _firstNameController.dispose();   // 🆕 NEW
  _lastNameController.dispose();    // 🆕 NEW
  _emailController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
  _firstNameFocusNode.dispose();    // 🆕 NEW
  _lastNameFocusNode.dispose();     // 🆕 NEW
  _emailFocusNode.dispose();
  _passwordFocusNode.dispose();
  _confirmPasswordFocusNode.dispose();
  super.dispose();
}

  // ✅ Handle multiple errors nicely
  Widget _buildErrorText(String error) {
    if (error.contains(', ')) {
      final errors = error.split(', ');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors.map((err) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: Colors.red.shade700, fontSize: 14)),
              Expanded(
                child: Text(
                  err,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                ),
              ),
            ],
          ),
        )).toList(),
      );
    }
    
    return Text(
      error,
      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    ref.read(authProvider.notifier).clearError();

    try {
      await GoogleSignIn.instance.signOut();
      final account = await GoogleSignIn.instance.authenticate();

      final idToken = account.authentication.idToken;

      if (idToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign-in failed: no ID token received')),
          );
        }
        return;
      }

      await ref.read(authProvider.notifier).googleSignIn(idToken);
      // Success — router redirects automatically
    } catch (e) {
      final msg = e.toString();
      final isBackendError = ref.read(authProvider).error != null;
      if (!isBackendError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: $msg')),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear any previous errors
    ref.read(authProvider.notifier).clearError();

    try {
await ref.read(authProvider.notifier).register(
  _firstNameController.text.trim(),      // 🆕 NEW
  _lastNameController.text.trim(),       // 🆕 NEW
  _emailController.text.trim(),
  _passwordController.text,
  _selectedRole,
);

      // Router will automatically navigate to home
    } catch (e) {
      // On error: Keep fields, give user feedback
      if (mounted) {
        // Use WidgetsBinding to ensure this happens after the current build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Select password text for easy correction
            _passwordController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _passwordController.text.length,
            );
            
            // Focus password field
            _passwordFocusNode.requestFocus();
          }
        });
      }
    }
  }

@override
Widget build(BuildContext context) {
  super.build(context); // ✅ Must call super.build
  final authState = ref.watch(authProvider);

  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: authState.isLoading
            ? null
            : () => context.go('/auth/login'),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Icon - 🆕 SMALLER
                Icon(
                  Icons.domain,
                  size: 60,  // 🆕 CHANGED from 80 to 60
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),  // 🆕 CHANGED from 24 to 16

                // Title
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,  // 🆕 CHANGED from displaySmall
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),  // 🆕 CHANGED from 8 to 4

                // Subtitle
                Text(
                  'Join us to manage your spaces',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),  // 🆕 CHANGED from 48 to 32

                // ✅ Error Message (Inline)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: authState.error != null
                      ? Container(
                          key: const ValueKey('error'),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(Icons.error_outline, 
                                    color: Colors.red.shade700, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildErrorText(authState.error!),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, 
                                    color: Colors.red.shade700, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  ref.read(authProvider.notifier).clearError();
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-error')),
                ),

                // First Name Field - 🆕 NEW
                TextFormField(
                  controller: _firstNameController,
                  focusNode: _firstNameFocusNode,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  enabled: !authState.isLoading,
                  onChanged: (_) {
                    if (authState.error != null) {
                      ref.read(authProvider.notifier).clearError();
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    hintText: 'Enter your first name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    if (value.trim().length < 2) {
                      return 'First name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last Name Field - 🆕 NEW
                TextFormField(
                  controller: _lastNameController,
                  focusNode: _lastNameFocusNode,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  enabled: !authState.isLoading,
                  onChanged: (_) {
                    if (authState.error != null) {
                      ref.read(authProvider.notifier).clearError();
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Enter your last name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your last name';
                    }
                    if (value.trim().length < 2) {
                      return 'Last name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role Selection
                Text(
                  'I am a:',
                  style: Theme.of(context).textTheme.titleMedium,  // 🆕 CHANGED from titleLarge
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        role: 'TENANT',
                        label: 'Tenant',
                        icon: Icons.person,
                        color: AppTheme.tenantColor,
                        isSelected: _selectedRole == 'TENANT',
                        isEnabled: !authState.isLoading,
                        onTap: () {
                          if (!authState.isLoading) {
                            setState(() {
                              _selectedRole = 'TENANT';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        role: 'LANDLORD',
                        label: 'Landlord',
                        icon: Icons.business,
                        color: AppTheme.landlordColor,
                        isSelected: _selectedRole == 'LANDLORD',
                        isEnabled: !authState.isLoading,
                        onTap: () {
                          if (!authState.isLoading) {
                            setState(() {
                              _selectedRole = 'LANDLORD';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),  // 🆕 CHANGED from 32 to 24

                // Email Field
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !authState.isLoading,
                  onChanged: (_) {
                    if (authState.error != null) {
                      ref.read(authProvider.notifier).clearError();
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

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  enabled: !authState.isLoading,
                  onChanged: (_) {
                    if (authState.error != null) {
                      ref.read(authProvider.notifier).clearError();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {  // 🆕 CHANGED from 8 to 6 (backend requires min 6)
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !authState.isLoading,
                  onChanged: (_) {
                    if (authState.error != null) {
                      ref.read(authProvider.notifier).clearError();
                    }
                  },
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
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

                // Register Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleRegister,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Register'),
                  ),
                ),
                const SizedBox(height: 12),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),

                // Google Sign-In Button (registers as Tenant)
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading ? null : _handleGoogleSignIn,
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
                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => context.go('/auth/login'),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

// Role Selection Card Widget
class _RoleCard extends StatelessWidget {
  final String role;
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isEnabled; // ✅ Add enabled state
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isEnabled, // ✅ Required parameter
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null, // ✅ Only tap if enabled
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5, // ✅ Visual feedback when disabled
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? color : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}