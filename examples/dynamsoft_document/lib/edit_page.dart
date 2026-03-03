import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';

import 'constants.dart';

/// Allows the user to manually adjust the crop region before confirming.
class EditPage extends StatefulWidget {
  final ImageData originalImageData;
  final Quadrilateral quad;

  const EditPage({
    super.key,
    required this.originalImageData,
    required this.quad,
  });

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  ImageEditorViewController? _controller;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller?.setImageData(widget.originalImageData);
      _controller?.setDrawingQuads(
        [widget.quad],
        EnumDrawingLayerId.ddn.value,
      );
    });
  }

  Future<void> _cropImageAndPop() async {
    if (_controller == null || _isConfirming) return;
    setState(() => _isConfirming = true);

    try {
      final selectedQuad = await _controller!.getSelectedQuad();
      final croppedImageData = await ImageProcessor()
          .cropAndDeskewImage(widget.originalImageData, selectedQuad);

      if (mounted) {
        Navigator.pop(
          context,
          {'croppedImageData': croppedImageData, 'updatedQuad': selectedQuad},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'The selected area is not a valid quadrilateral. '
                'Please drag the corners to form a proper rectangle.'),
            duration: AppConstants.snackBarDuration,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust Crop Region'),
        actions: [
          if (_isConfirming)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton.icon(
              onPressed: _cropImageAndPop,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ImageEditorView(
              imageData: widget.originalImageData,
              drawingQuadsByLayer: {
                EnumDrawingLayerId.ddn: [widget.quad],
              },
              onPlatformViewCreated: (controller) {
                _controller = controller;
              },
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag the corner handles to adjust the crop boundaries.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isConfirming ? null : _cropImageAndPop,
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.crop),
                  label: Text(_isConfirming ? 'Processing…' : 'Crop & Confirm'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
