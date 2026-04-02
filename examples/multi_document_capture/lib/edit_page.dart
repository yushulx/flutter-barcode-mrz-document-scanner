import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'constants.dart';

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
  bool _isApplying = false;

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

  Future<void> _applyEdit() async {
    if (_controller == null || _isApplying) return;
    setState(() => _isApplying = true);

    try {
      final selectedQuad = await _controller!.getSelectedQuad();
      final croppedImageData = await ImageProcessor()
          .cropAndDeskewImage(widget.originalImageData, selectedQuad);

      if (mounted) {
        Navigator.pop(context, {
          'croppedImageData': croppedImageData,
          'updatedQuad': selectedQuad,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'The selected area is not a valid quadrilateral. '
              'Please drag the corners to form a proper rectangle.',
            ),
            duration: AppConstants.snackBarDuration,
          ),
        );
      }
    }
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
        title: const Text('Edit Quad'),
        centerTitle: true,
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

          // Bottom bar with Cancel / Apply
          Container(
            height: 56,
            color: AppTheme.dyBlack34,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.dyGray, fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _isApplying ? null : _applyEdit,
                    child: _isApplying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.dyOrange,
                            ),
                          )
                        : const Text(
                            'Apply',
                            style: TextStyle(
                                color: AppTheme.dyOrange, fontSize: 16),
                          ),
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
