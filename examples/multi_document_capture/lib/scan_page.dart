import 'dart:async';

import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_theme.dart';
import 'constants.dart';
import 'document_page.dart';
import 'main.dart';
import 'quad_stabilizer.dart';
import 'result_page.dart';

class ScannerPage extends StatefulWidget {
  final List<DocumentPage>? existingPages;
  final int? retakeIndex;

  const ScannerPage({super.key, this.existingPages, this.retakeIndex});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with RouteAware {
  late final CaptureVisionRouter _cvr;
  final CameraEnhancer _camera = CameraEnhancer.instance;
  final String _template = EnumPresetTemplate.detectAndNormalizeDocument;
  late final CapturedResultReceiver _receiver;
  late final QuadStabilizer _quadStabilizer;

  bool _isSdkReady = false;
  bool _isProcessing = false;
  bool _isBtnClicked = false;
  bool _cooldown = false;
  bool _showAutoIndicator = false;
  String? _licenseError;

  // Store the latest detection for manual-capture fallback
  DeskewedImageResultItem? _latestDeskewedItem;
  String? _latestOriginalImageHashId;

  // Manual capture timeout (500ms like Android)
  Timer? _captureTimeoutTimer;

  final List<DocumentPage> _pages = [];
  bool _isRetakeMode = false;
  int _retakeIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.existingPages != null) {
      _pages.addAll(widget.existingPages!);
    }
    _isRetakeMode = widget.retakeIndex != null && widget.retakeIndex! >= 0;
    _retakeIndex = _isRetakeMode ? widget.retakeIndex! : -1;

    _quadStabilizer = QuadStabilizer(
      onStable: _onAutoCapture,
    );

    PermissionUtil.requestCameraPermission();
    _initSdk();
  }

  Future<void> _initSdk() async {
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
        if (_isProcessing || _cooldown) return;
        final items = result.deskewedImageResultItems;
        if (items == null || items.isEmpty) return;

        final item = items.first;

        // Store latest for manual capture
        _latestDeskewedItem = item;
        _latestOriginalImageHashId = result.originalImageHashId;

        if (_isBtnClicked) {
          // Manual capture — use this fresh detection
          _isBtnClicked = false;
          _captureTimeoutTimer?.cancel();
          _captureTimeoutTimer = null;
          _captureResult(item, result.originalImageHashId, autoCapture: false);
        } else if (item.crossVerificationStatus ==
            EnumCrossVerificationStatus.passed) {
          // Feed to stabilizer for auto-capture
          _quadStabilizer.feedQuad(item.sourceDeskewQuad);
        }
      };

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
      if (mounted) setState(() => _licenseError = e.toString());
    }
  }

  // ── Auto-capture via QuadStabilizer ───────────────────────────────────

  void _onAutoCapture() {
    if (_cooldown || _latestDeskewedItem == null) return;
    _captureResult(
        _latestDeskewedItem!, _latestOriginalImageHashId ?? '', autoCapture: true);
  }

  // ── Capture result with original image ────────────────────────────────

  Future<void> _captureResult(
      DeskewedImageResultItem item, String originalImageHashId,
      {required bool autoCapture}) async {
    if (_cooldown) return;
    _cooldown = true;
    _isProcessing = true;

    if (autoCapture && mounted) {
      setState(() => _showAutoIndicator = true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showAutoIndicator = false);
      });
    }

    final originalImage = await _cvr
        .getIntermediateResultManager()
        .getOriginalImage(originalImageHashId);

    final deskewedImage = item.imageData;
    final sourceDeskewQuad = item.sourceDeskewQuad;

    if (deskewedImage == null || originalImage == null) {
      _isProcessing = false;
      _cooldown = false;
      return;
    }

    final page = DocumentPage(
      originalImage: originalImage,
      normalizedImage: deskewedImage,
      quad: sourceDeskewQuad,
    );

    if (mounted) {
      setState(() {
        if (_isRetakeMode && _retakeIndex >= 0) {
          _pages[_retakeIndex] = page;
        } else {
          _pages.add(page);
        }
        _isProcessing = false;
      });
    }

    _quadStabilizer.reset();

    if (_isRetakeMode) {
      if (mounted) Navigator.pop(context, _pages);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    _cooldown = false;
  }

  // ── Manual capture with 500ms timeout fallback ────────────────────────

  void _onCapturePressed() {
    if (!_isSdkReady || _isProcessing || _cooldown) return;
    _isBtnClicked = true;
    _latestDeskewedItem = null;
    _latestOriginalImageHashId = null;
    // If no detection within 500ms, capture raw frame
    _captureTimeoutTimer?.cancel();
    _captureTimeoutTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isBtnClicked) {
        _isBtnClicked = false;
        _captureRawFrame();
      }
    });
  }

  /// Capture the current raw camera frame when no document was detected
  /// within the timeout (mirrors Android `captureRawFrame`).
  Future<void> _captureRawFrame() async {
    if (_cooldown) return;
    _cooldown = true;

    try {
      final ImageData? frame = await _camera.getImage();
      if (frame != null && mounted) {
        final page = DocumentPage(
          originalImage: frame,
          normalizedImage: frame,
          quad: null,
        );
        setState(() {
          if (_isRetakeMode && _retakeIndex >= 0) {
            _pages[_retakeIndex] = page;
          } else {
            _pages.add(page);
          }
        });

        if (_isRetakeMode) {
          Navigator.pop(context, _pages);
          return;
        }
      }
    } catch (e) {
      debugPrint('captureRawFrame error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    _cooldown = false;
  }

  // ── Gallery with fallback ─────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    if (mounted) setState(() => _isProcessing = true);

    try {
      final result = await _cvr.captureFile(file.path, _template);

      final docResult = result.processedDocumentResult;
      final items = docResult?.deskewedImageResultItems;

      if (items != null && items.isNotEmpty) {
        final item = items.first;
        final originalImage = await _cvr
            .getIntermediateResultManager()
            .getOriginalImage(result.originalImageHashId);

        final page = DocumentPage(
          originalImage: originalImage,
          normalizedImage: item.imageData!,
          quad: item.sourceDeskewQuad,
        );
        if (mounted) setState(() => _pages.add(page));
      } else {
        // No document detected — load file directly as ImageData
        final originalImage = await ImageIO().readFromFile(file.path);
        if (originalImage != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No document detected. Using original image.')),
          );
          final page = DocumentPage(
            originalImage: originalImage,
            normalizedImage: originalImage,
            quad: null,
          );
          setState(() => _pages.add(page));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Settings dialog ───────────────────────────────────────────────────

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.dyBlack34,
            title: const Text('Stabilization Settings',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Auto Capture',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    'Capture when quad is stable',
                    style: TextStyle(color: AppTheme.dyGray, fontSize: 12),
                  ),
                  value: _quadStabilizer.autoCaptureEnabled,
                  activeThumbColor: AppTheme.dyOrange,
                  onChanged: (value) {
                    setDialogState(() {});
                    setState(() {
                      _quadStabilizer.autoCaptureEnabled = value;
                      _quadStabilizer.reset();
                    });
                  },
                ),
                const Divider(color: AppTheme.dyGray),
                _SettingSlider(
                  label: 'IoU Threshold',
                  value: _quadStabilizer.iouThreshold,
                  min: 0.5,
                  max: 1.0,
                  onChanged: (v) {
                    setDialogState(() {});
                    _quadStabilizer.iouThreshold = v;
                    _quadStabilizer.reset();
                  },
                ),
                _SettingSlider(
                  label: 'Area Delta Threshold',
                  value: _quadStabilizer.areaDeltaThreshold,
                  min: 0.01,
                  max: 0.5,
                  onChanged: (v) {
                    setDialogState(() {});
                    _quadStabilizer.areaDeltaThreshold = v;
                    _quadStabilizer.reset();
                  },
                ),
                _SettingSlider(
                  label: 'Stable Frame Count',
                  value: _quadStabilizer.stableFrameCount.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  isInt: true,
                  onChanged: (v) {
                    setDialogState(() {});
                    _quadStabilizer.stableFrameCount = v.round();
                    _quadStabilizer.reset();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close',
                    style: TextStyle(color: AppTheme.dyOrange)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _goToResult() {
    if (_pages.isEmpty) return;
    Navigator.push<List<DocumentPage>>(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(pages: List.from(_pages)),
      ),
    ).then((updatedPages) {
      if (updatedPages != null && mounted) {
        setState(() {
          _pages.clear();
          _pages.addAll(updatedPages);
        });
      }
    });
  }

  void _removePage(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _pages.removeAt(index));
    }
  }

  Future<void> _resumeCapturing() async {
    try {
      await _camera.open();
      await _cvr.startCapturing(_template);
    } catch (_) {}
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
    _captureTimeoutTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dyBlack2B,
      appBar: AppBar(
        backgroundColor: AppTheme.dyBlack2B,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Document Scanner'),
        centerTitle: true,
      ),
      body: _licenseError != null
          ? _buildLicenseErrorView()
          : _buildCameraView(),
    );
  }

  Widget _buildLicenseErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('License Error',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(_licenseError ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.dyGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraView(cameraEnhancer: _camera),

        // Settings button (top right)
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: _showSettingsDialog,
          ),
        ),

        // Auto-capture indicator
        if (_showAutoIndicator)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: AppTheme.semiTransparentBlack,
                child: const Text(
                  'Document auto-captured',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),

        if (!_isSdkReady || _isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // Thumbnail bar
        if (!_isRetakeMode && _pages.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 108,
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => _ThumbnailItem(
                  page: _pages[i],
                  onRemove: () => _removePage(i),
                ),
              ),
            ),
          ),

        // Bottom controls bar
        if (_isSdkReady && !_isProcessing)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: AppTheme.semiTransparentBlack,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Gallery button (left)
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.photo_library_outlined,
                            color: Colors.white, size: 32),
                      ),
                    ),

                    const Spacer(),

                    // Capture button (center)
                    GestureDetector(
                      onTap: _onCapturePressed,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        child: Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Next button (right)
                    if (!_isRetakeMode)
                      GestureDetector(
                        onTap: _pages.isNotEmpty ? _goToResult : null,
                        child: Opacity(
                          opacity: _pages.isNotEmpty ? 1.0 : 0.3,
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(Icons.arrow_forward,
                                color: Colors.white, size: 32),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48, height: 48),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Setting slider helper ───────────────────────────────────────────────────

class _SettingSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final bool isInt;
  final ValueChanged<double> onChanged;

  const _SettingSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.isInt = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13)),
            Text(
              isInt ? value.round().toString() : value.toStringAsFixed(2),
              style: const TextStyle(color: AppTheme.dyGray, fontSize: 13),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.dyOrange,
            thumbColor: AppTheme.dyOrange,
            inactiveTrackColor: AppTheme.dyGray.withValues(alpha: 0.3),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ── Thumbnail widget ────────────────────────────────────────────────────────

class _ThumbnailItem extends StatelessWidget {
  final DocumentPage page;
  final VoidCallback onRemove;

  const _ThumbnailItem({required this.page, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 72,
            color: AppTheme.dyBlack34,
            child: FutureBuilder<dynamic>(
              future: page.getDisplayBytes(),
              builder: (ctx, snap) {
                if (snap.hasData && snap.data != null) {
                  return Image.memory(snap.data!, fit: BoxFit.cover);
                }
                return const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                color: AppTheme.semiTransparentBlack,
                child:
                    const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
