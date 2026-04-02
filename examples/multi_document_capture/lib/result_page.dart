import 'dart:io';
import 'dart:typed_data';

import 'package:dynamsoft_capture_vision_flutter/dynamsoft_capture_vision_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

import 'app_theme.dart';
import 'constants.dart';
import 'document_page.dart';
import 'edit_page.dart';
import 'scan_page.dart';
import 'sort_pages_page.dart';

class ResultPage extends StatefulWidget {
  final List<DocumentPage> pages;

  const ResultPage({super.key, required this.pages});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late List<DocumentPage> _pages;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pages = List.from(widget.pages);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  // ── Actions ───────────────────────────────────────────────────────────

  void _continueShooting() {
    Navigator.pop(context, _pages);
  }

  void _retakeCurrent() {
    Navigator.push<List<DocumentPage>>(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerPage(
          existingPages: _pages,
          retakeIndex: _currentIndex,
        ),
      ),
    ).then((updatedPages) {
      if (updatedPages != null && mounted) {
        setState(() {
          _pages.clear();
          _pages.addAll(updatedPages);
          if (_currentIndex >= _pages.length) {
            _currentIndex = _pages.length - 1;
          }
        });
      }
    });
  }

  void _editQuad() {
    final page = _pages[_currentIndex];
    if (!page.hasOriginalImage || page.quad == null) return;

    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPage(
          originalImageData: page.originalImage!,
          quad: page.quad!,
        ),
      ),
    ).then((result) {
      if (result != null && mounted) {
        setState(() {
          if (result['croppedImageData'] != null &&
              result['updatedQuad'] != null) {
            page.updateFromQuadEdit(
              result['croppedImageData'] as ImageData,
              result['updatedQuad'] as Quadrilateral,
            );
          }
        });
      }
    });
  }

  void _rotateCurrent() {
    setState(() {
      _pages[_currentIndex].rotate90();
    });
  }

  void _sortPages() {
    Navigator.push<List<DocumentPage>>(
      context,
      MaterialPageRoute(
        builder: (_) => SortPagesPage(pages: List.from(_pages)),
      ),
    ).then((reordered) {
      if (reordered != null && mounted) {
        setState(() {
          _pages.clear();
          _pages.addAll(reordered);
          _currentIndex = 0;
          _pageController.jumpToPage(0);
        });
      }
    });
  }

  void _showSaveMenu() {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        kToolbarHeight + MediaQuery.of(context).padding.top,
        0,
        0,
      ),
      color: AppTheme.dyBlack34,
      items: const [
        PopupMenuItem(
            value: 'pdf',
            child: Text('Export as PDF',
                style: TextStyle(color: Colors.white))),
        PopupMenuItem(
            value: 'image',
            child: Text('Export as Images',
                style: TextStyle(color: Colors.white))),
      ],
    ).then((value) {
      if (value == 'pdf') _exportPdf();
      if (value == 'image') _exportImages();
    });
  }

  // ── Export images to system gallery ───────────────────────────────────

  Future<void> _exportImages() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      // Request storage permission on Android < 33
      if (Platform.isAndroid) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          // Try legacy storage permission for older Android
          await Permission.storage.request();
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      int saved = 0;

      for (int i = 0; i < _pages.length; i++) {
        final bytes = await _pages[i].getDisplayBytes();
        if (bytes == null) continue;

        final fileName = '${AppConstants.exportFilePrefix}${timestamp}_${i + 1}.png';
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 95,
          name: fileName,
        );

        if (result != null && result['isSuccess'] == true) {
          saved++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$saved image(s) saved to gallery'),
            duration: AppConstants.snackBarDuration,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save images: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Export as PDF to documents directory ──────────────────────────────

  Future<void> _exportPdf() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final pdf = pw.Document();

      for (int i = 0; i < _pages.length; i++) {
        final bytes = await _pages[i].getDisplayBytes();
        if (bytes == null) continue;

        final image = pw.MemoryImage(bytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Save to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${dir.path}/documents');
      if (!documentsDir.existsSync()) {
        documentsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${AppConstants.exportFilePrefix}$timestamp.pdf';
      final file = File('${documentsDir.path}/$fileName');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: ${file.path}'),
            duration: AppConstants.snackBarDuration,
          ),
        );
      }

      // Open with system PDF viewer
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _applyFilter(int colorMode) {
    setState(() {
      _pages[_currentIndex].setColorMode(colorMode);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final page = _pages.isNotEmpty ? _pages[_currentIndex] : null;
    final bool canEdit =
        page != null && page.hasOriginalImage && page.quad != null;

    return Scaffold(
      backgroundColor: AppTheme.dyBlack2B,
      appBar: AppBar(
        backgroundColor: AppTheme.dyBlack2B,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _pages),
        ),
        title: const Text('Result'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top action bar
          Container(
            height: 56,
            color: AppTheme.dyBlack34,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.add_a_photo,
                  label: 'Continue',
                  onTap: _continueShooting,
                ),
                _ActionButton(
                  icon: Icons.refresh,
                  label: 'Retake',
                  onTap: _retakeCurrent,
                ),
                _ActionButton(
                  icon: Icons.edit,
                  label: 'Edit',
                  onTap: canEdit ? _editQuad : null,
                  enabled: canEdit,
                ),
                _ActionButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate',
                  onTap: _rotateCurrent,
                ),
                _ActionButton(
                  icon: Icons.sort,
                  label: 'Sort',
                  onTap: _pages.length > 1 ? _sortPages : null,
                  enabled: _pages.length > 1,
                ),
                _ActionButton(
                  icon: _isSaving ? null : Icons.save,
                  label: 'Save',
                  onTap: _isSaving ? null : _showSaveMenu,
                  enabled: !_isSaving,
                  loading: _isSaving,
                ),
              ],
            ),
          ),

          // Page indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${_currentIndex + 1} / ${_pages.length}',
              style: const TextStyle(color: AppTheme.dyGray, fontSize: 14),
            ),
          ),

          // Page viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (ctx, index) => _PageItem(page: _pages[index]),
            ),
          ),

          // Bottom filter bar
          Container(
            height: 56,
            color: AppTheme.dyBlack34,
            child: Row(
              children: [
                _FilterButton(
                  label: 'Color',
                  selected: page?.colorMode == 0,
                  onTap: () => _applyFilter(0),
                ),
                _FilterButton(
                  label: 'Grayscale',
                  selected: page?.colorMode == 1,
                  onTap: () => _applyFilter(1),
                ),
                _FilterButton(
                  label: 'Binary',
                  selected: page?.colorMode == 2,
                  onTap: () => _applyFilter(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget helpers ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageItem extends StatelessWidget {
  final DocumentPage page;

  const _PageItem({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: FutureBuilder<Uint8List?>(
        future: page.getDisplayBytes(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.data == null) {
            return const Center(
              child: Text('Unable to render image.',
                  style: TextStyle(color: AppTheme.dyGray)),
            );
          }
          return Image.memory(snapshot.data!, fit: BoxFit.contain);
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.dyOrange : AppTheme.dyGray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
