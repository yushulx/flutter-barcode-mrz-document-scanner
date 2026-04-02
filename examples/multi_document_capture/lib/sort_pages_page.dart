import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'document_page.dart';

class SortPagesPage extends StatefulWidget {
  final List<DocumentPage> pages;

  const SortPagesPage({super.key, required this.pages});

  @override
  State<SortPagesPage> createState() => _SortPagesPageState();
}

class _SortPagesPageState extends State<SortPagesPage> {
  late List<DocumentPage> _workingList;

  @override
  void initState() {
    super.initState();
    _workingList = List.from(widget.pages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dyBlack2B,
      body: Column(
        children: [
          // Top bar
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              color: AppTheme.dyBlack34,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Reorder Pages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _workingList),
                    child: const Text(
                      'Done',
                      style: TextStyle(color: AppTheme.dyOrange, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hint text
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Drag to reorder pages',
              style: TextStyle(color: AppTheme.dyGray, fontSize: 14),
            ),
          ),

          // Grid with reorderable items
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _workingList.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _workingList.removeAt(oldIndex);
                  _workingList.insert(newIndex, item);
                });
              },
              itemBuilder: (ctx, index) {
                return _SortPageItem(
                  key: ValueKey(index),
                  page: _workingList[index],
                  pageNumber: index + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortPageItem extends StatelessWidget {
  final DocumentPage page;
  final int pageNumber;

  const _SortPageItem({
    super.key,
    required this.page,
    required this.pageNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.dyBlack34,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: FutureBuilder<Uint8List?>(
            future: page.getDisplayBytes(),
            builder: (ctx, snap) {
              if (snap.hasData && snap.data != null) {
                return Image.memory(snap.data!, fit: BoxFit.cover);
              }
              return Container(
                color: AppTheme.dyBlack2B,
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
        title: Text(
          'Page $pageNumber',
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.drag_handle, color: AppTheme.dyGray),
      ),
    );
  }
}
