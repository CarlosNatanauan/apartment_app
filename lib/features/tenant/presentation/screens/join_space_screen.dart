import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_memberships_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class JoinSpaceScreen extends ConsumerStatefulWidget {
  const JoinSpaceScreen({super.key});

  @override
  ConsumerState<JoinSpaceScreen> createState() => _JoinSpaceScreenState();
}

class _JoinSpaceScreenState extends ConsumerState<JoinSpaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _joinCodeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _openQrScanner() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScannerPage()),
    );
    if (code != null && mounted) {
      setState(() => _joinCodeController.text = code);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(tenantMembershipsProvider.notifier).joinSpace(
            _joinCodeController.text,
          );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Request sent! Waiting for manager approval.'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join space: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Space'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tenantColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.tenantColor.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.tenantColor,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ask your space manager for the join code to request access to their space.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.tenantColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Illustration
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.tenantColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key,
                  size: 64,
                  color: AppTheme.tenantColor,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Join Code Input
            Text(
              'Enter Join Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _joinCodeController,
              decoration: const InputDecoration(
                hintText: 'ABC123XYZ',
                prefixIcon: Icon(Icons.vpn_key_outlined),
                helperText: '6-character code from your space manager',
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a join code';
                }
                if (value.length != 6) {
                  return 'Join code must be 6 characters';
                }
                return null;
              },
              enabled: !_isSubmitting,
            ),

            const SizedBox(height: 16),

            // Scan QR Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _openQrScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.tenantColor,
                  side: const BorderSide(color: AppTheme.tenantColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tenantColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Request to Join'),
              ),
            ),

            const SizedBox(height: 16),

            // Help text
            Center(
              child: Text(
                'Your request will be sent to the manager for approval',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final _codeRegex = RegExp(r'^[A-Z0-9]{6}$');
  bool _processed = false;
  String? _errorMessage;

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim().toUpperCase();
      if (value != null && _codeRegex.hasMatch(value)) {
        _processed = true;
        Navigator.pop(context, value);
        return;
      }
    }
    if (mounted) {
      setState(() => _errorMessage = 'Invalid code — try again');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _errorMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Join Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          // Viewfinder overlay
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.tenantColor, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Label
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Point at the landlord\'s QR code',
                    style: TextStyle(color: Colors.white, fontSize: 14),
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