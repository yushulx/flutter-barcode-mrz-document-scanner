import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'main.dart';
import 'result_page.dart';

/// Full-screen camera page that continuously detects and deskews documents.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with RouteAware {
  // ── SDK objects ──────────────────────────────────────────────────────────
  late final CaptureVisionRouter _cvr;
  final CameraEnhancer _camera = CameraEnhancer.instance;
  final String _template = EnumPresetTemplate.detectAndNormalizeDocument;
  late final CapturedResultReceiver _receiver;

  // ── State ─────────────────────────────────────────────────────────────
  bool _isCapturing = false; // manual capture triggered
  bool _isSdkReady = false;
  bool _isProcessing = false; // navigating to result page
  String? _licenseError;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    PermissionUtil.requestCameraPermission();
    _initSdk();
  }

  Future<void> _initSdk() async {
    // Initialise the CVR with a cross-verification filter for stable results.
    _cvr = CaptureVisionRouter.instance
      ..addResultFilter(
        MultiFrameResultCrossFilter()
          ..enableResultCrossVerification(
            EnumCapturedResultItemType.deskewedImage.value,
            true,
          ),
      );

    _receiver = CapturedResultReceiver()
      ..onProcessedDocumentResultReceived =
          (ProcessedDocumentResult result) async {
        if (_isProcessing) return;
        final items = result.deskewedImageResultItems;
        if (items == null || items.isEmpty) return;

        final item = items.first;
        final bool autoVerified =
            item.crossVerificationStatus ==
            EnumCrossVerificationStatus.passed;
        final bool manualCapture = _isCapturing;

        if (!autoVerified && !manualCapture) return;

        _isCapturing = false;
        _isProcessing = true;

        // Fetch intermediate original image BEFORE stopping capture.
        final originalImage = await _cvr
            .getIntermediateResultManager()
            .getOriginalImage(result.originalImageHashId);

        final deskewedImage = item.imageData;
        final sourceDeskewQuad = item.sourceDeskewQuad;

        await _cvr.stopCapturing();
        _camera.close();

        if (!mounted) return;
        if (deskewedImage == null || originalImage == null) {
          _showErrorSnack('Failed to retrieve image data. Please retry.');
          _isProcessing = false;
          await _resumeCapturing();
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              deskewedImage: deskewedImage,
              originalImage: originalImage,
              sourceDeskewQuad: sourceDeskewQuad,
            ),
          ),
        );
        _isProcessing = false;
      };

    // Initialise license.
    final (isSuccess, message) =
        await LicenseManager.initLicense(AppConstants.licenseKey);
    if (!isSuccess && mounted) {
      setState(() => _licenseError = message);
      return;
    }

    try {
      await _cvr.setInput(_camera);
      _cvr.addResultReceiver(_receiver);
      await _camera.open();
      await _cvr.startCapturing(_template);
      if (mounted) setState(() => _isSdkReady = true);
    } catch (e) {
      if (mounted) {
        setState(() => _licenseError = e.toString());
      }
    }
  }

  Future<void> _resumeCapturing() async {
    try {
      await _camera.open();
      await _cvr.startCapturing(_template);
    } catch (_) {
      // ignore errors when resuming
    }
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: AppConstants.snackBarDuration,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _cvr.stopCapturing();
    _camera.close();
    _cvr.removeResultReceiver(_receiver);
    _cvr.removeAllResultFilters();
    super.dispose();
  }

  @override
  void didPushNext() {
    _cvr.stopCapturing();
    _camera.close();
  }

  @override
  void didPopNext() {
    _isProcessing = false;
    _resumeCapturing();
  }

  // ── Actions ────────────────────────────────────────────────────────────

  void _onCapturePressed() {
    if (!_isSdkReady || _isProcessing) return;
    setState(() => _isCapturing = true);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Document',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _licenseError != null
          ? _buildLicenseErrorView()
          : _buildCameraView(),
    );
  }

  Widget _buildLicenseErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'License Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _licenseError ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera feed
        CameraView(cameraEnhancer: _camera),

        // Initialising overlay
        if (!_isSdkReady)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initialising scanner…',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Processing document…',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

        // Bottom hint + capture button
        if (_isSdkReady && !_isProcessing)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isCapturing
                        ? 'Capturing…'
                        : 'Point camera at a document',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _CaptureButton(
                    onPressed: _onCapturePressed,
                    isCapturing: _isCapturing,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Circular shutter-style capture button.
class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.onPressed,
    required this.isCapturing,
  });

  final VoidCallback onPressed;
  final bool isCapturing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: AppConstants.fabSize,
        height: AppConstants.fabSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCapturing ? Colors.grey : Colors.white,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: isCapturing
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.orange),
              )
            : const Icon(Icons.camera, color: Colors.black87, size: 32),
      ),
    );
  }
}
