import 'package:dynamsoft_mrz_scanner_bundle_flutter/dynamsoft_mrz_scanner_bundle_flutter.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/mrz_result_model.dart';
import 'result_screen.dart';

/// The main landing screen of the MRZ Scanner app.
///
/// Presents branding, instructions, and the primary scan action. After a
/// successful scan the user is pushed to [ResultScreen]. Errors and
/// cancellations are surfaced via a [SnackBar].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScanning = false;

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final config = MRZScannerConfig(license: AppConfig.licenseKey);
      final mrzScanResult = await MRZScanner.launch(config);

      if (!mounted) return;

      switch (mrzScanResult.status) {
        case EnumResultStatus.finished:
          final model = MrzResultModel(data: mrzScanResult.mrzData!);
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ResultScreen(result: model)),
          );

        case EnumResultStatus.canceled:
          // User dismissed the scanner – nothing to do.
          break;

        case EnumResultStatus.exception:
          _showError(
            'Scan failed: ${mrzScanResult.errorMessage ?? 'Unknown error'} '
            '(code ${mrzScanResult.errorCode})',
          );
      }
    } catch (e) {
      if (mounted) _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hero illustration
                    Container(
                      width: size.width * 0.55,
                      height: size.width * 0.55,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.document_scanner_outlined,
                        size: size.width * 0.28,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      'MRZ Scanner',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Point your camera at the Machine Readable Zone '
                      '(MRZ) on a passport, ID card, or travel document '
                      'to extract the encoded information instantly.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Supported document chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: const [
                        _DocTypeChip(label: 'Passport (TD3)'),
                        _DocTypeChip(label: 'ID Card (TD1)'),
                        _DocTypeChip(label: 'ID Card (TD2)'),
                      ],
                    ),
                  ],
                ),
              ),

              // Scan button
              Padding(
                padding: const EdgeInsets.only(bottom: 32, top: 16),
                child: FilledButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.document_scanner_outlined),
                  label: Text(_isScanning ? 'Opening Scanner…' : 'Scan Document'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small chip that labels a supported document type.
class _DocTypeChip extends StatelessWidget {
  const _DocTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: theme.colorScheme.secondaryContainer,
      padding: EdgeInsets.zero,
      side: BorderSide.none,
    );
  }
}
