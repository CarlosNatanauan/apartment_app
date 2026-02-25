import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/auth_provider.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Keep state alive
  

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;


@override
void initState() {
  super.initState();
  
  // Add listeners to track when text changes
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


// ✅ Add this method to handle multiple errors nicely
Widget _buildErrorText(String error) {
  // Check if error contains multiple messages (comma-separated)
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
  
  // Single error - show as before
  return Text(
    error,
    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
  );
}

Future<void> _handleGoogleSignIn() async {
  ref.read(authProvider.notifier).clearError();

  try {
    // Force account chooser every time
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
    // googleSignIn() sets error on authProvider state for backend errors.
    // For Google-side errors (account picker cancelled, no token, etc.),
    // show directly.
    final msg = e.toString();
    final isBackendError = ref.read(authProvider).error != null;
    if (!isBackendError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: $msg')),
      );
    }
  }
}

Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  // Clear any previous errors
  ref.read(authProvider.notifier).clearError();

  try {
    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    // Success - router will automatically navigate to home
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
          
          // ❌ REMOVED SNACKBAR - inline error is enough
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
                  // Logo/Icon
                  Icon(
                    Icons.domain,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Login to manage your spaces',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Error Message (Inline)
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
            crossAxisAlignment: CrossAxisAlignment.start, // ✅ Changed to start
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.error_outline, 
                    color: Colors.red.shade700, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildErrorText(authState.error!), // ✅ New method
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
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !authState.isLoading,
                    onChanged: (_) {
                      // Clear error when user starts typing
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
                    textInputAction: TextInputAction.done,
                    enabled: !authState.isLoading,
                    onChanged: (_) {
                      // Clear error when user starts typing
                      if (authState.error != null) {
                        ref.read(authProvider.notifier).clearError();
                      }
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
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
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Login'),
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

                  // Google Sign-In Button
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

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () => context.go('/auth/register'),
                        child: const Text('Register'),
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