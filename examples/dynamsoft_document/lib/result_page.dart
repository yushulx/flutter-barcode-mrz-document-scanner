import 'dart:io';
import 'dart:typed_data';

import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'constants.dart';
import 'edit_page.dart';

/// Displays the deskewed document and lets the user switch colour modes or export.
class ResultPage extends StatefulWidget {
  final ImageData deskewedImage;
  final ImageData originalImage;
  final Quadrilateral sourceDeskewQuad;

  const ResultPage({
    super.key,
    required this.originalImage,
    required this.deskewedImage,
    required this.sourceDeskewQuad,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

enum _ColourMode { colour, grayscale, binary }

class _ResultPageState extends State<ResultPage> {
  late ImageData _deskewedColorfulImage;
  late ImageData _showingImage;
  late Quadrilateral _quad;

  _ColourMode _currentMode = _ColourMode.colour;
  bool _isConverting = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _deskewedColorfulImage = widget.deskewedImage;
    _showingImage = _deskewedColorfulImage;
    _quad = widget.sourceDeskewQuad;
  }

  // ── Colour mode ─────────────────────────────────────────────────────────

  Future<void> _changeColourMode(_ColourMode mode) async {
    if (_currentMode == mode || _isConverting) return;
    setState(() => _isConverting = true);

    try {
      ImageData? converted;
      switch (mode) {
        case _ColourMode.colour:
          converted = _deskewedColorfulImage;
        case _ColourMode.grayscale:
          converted = await ImageProcessor()
              .convertToGray(_deskewedColorfulImage);
        case _ColourMode.binary:
          converted = await ImageProcessor()
              .convertToBinaryLocal(_deskewedColorfulImage, compensation: 15);
      }
      if (mounted && converted != null) {
        setState(() {
          _showingImage = converted!;
          _currentMode = mode;
        });
      }
    } catch (e) {
      _showSnack('Colour conversion failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  // ── Edit ───────────────────────────────────────────────────────────────

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPage(
          originalImageData: widget.originalImage,
          quad: _quad,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result['croppedImageData'] != null) {
          _deskewedColorfulImage = result['croppedImageData'] as ImageData;
          _showingImage = _deskewedColorfulImage;
          _currentMode = _ColourMode.colour;
        }
        if (result['updatedQuad'] != null) {
          _quad = result['updatedQuad'] as Quadrilateral;
        }
      });
    }
  }

  // ── Export ─────────────────────────────────────────────────────────────

  Future<void> _exportImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final Directory directory;
      if (Platform.isAndroid) {
        directory = (await getExternalStorageDirectory())!;
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '${directory.path}/${AppConstants.exportFilePrefix}$timestamp${AppConstants.exportFileExtension}';

      await ImageIO().saveToFile(_showingImage, filePath, true);

      if (mounted) {
        _showSnack('Saved to: $filePath');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Export failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: AppConstants.snackBarDuration,
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  void _showColourModeSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BottomSheetHandle(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Colour Mode',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              _ColourModeOption(
                icon: Icons.color_lens_outlined,
                label: 'Colour',
                selected: _currentMode == _ColourMode.colour,
                onTap: () {
                  Navigator.pop(ctx);
                  _changeColourMode(_ColourMode.colour);
                },
              ),
              _ColourModeOption(
                icon: Icons.gradient_outlined,
                label: 'Grayscale',
                selected: _currentMode == _ColourMode.grayscale,
                onTap: () {
                  Navigator.pop(ctx);
                  _changeColourMode(_ColourMode.grayscale);
                },
              ),
              _ColourModeOption(
                icon: Icons.contrast_outlined,
                label: 'Binary (B&W)',
                selected: _currentMode == _ColourMode.binary,
                onTap: () {
                  Navigator.pop(ctx);
                  _changeColourMode(_ColourMode.binary);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Result'),
        actions: [
          if (_isExporting)
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
            IconButton(
              icon: const Icon(Icons.save_alt_outlined),
              tooltip: 'Export PNG',
              onPressed: _exportImage,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Colour mode chip bar
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Mode:',
                      style: TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    _ModeChip(
                      label: 'Colour',
                      selected: _currentMode == _ColourMode.colour,
                      onTap: () => _changeColourMode(_ColourMode.colour),
                    ),
                    const SizedBox(width: 6),
                    _ModeChip(
                      label: 'Gray',
                      selected: _currentMode == _ColourMode.grayscale,
                      onTap: () =>
                          _changeColourMode(_ColourMode.grayscale),
                    ),
                    const SizedBox(width: 6),
                    _ModeChip(
                      label: 'B&W',
                      selected: _currentMode == _ColourMode.binary,
                      onTap: () => _changeColourMode(_ColourMode.binary),
                    ),
                  ],
                ),
              ),
              // Document preview
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: FutureBuilder<Uint8List?>(
                    future: ImageIO().saveToMemory(
                        _showingImage, EnumImageFileFormat.png),
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.data == null) {
                        return const Center(
                          child: Text('Unable to render image.'),
                        );
                      }
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(snapshot.data!,
                              fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_isConverting)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_outlined),
            label: 'Edit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.color_lens_outlined),
            label: 'Colour Mode',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.save_alt_outlined),
            label: 'Export',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              _navigateToEdit();
            case 1:
              _showColourModeSheet();
            case 2:
              _exportImage();
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _ColourModeOption extends StatelessWidget {
  const _ColourModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check,
              color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? null
              : Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
