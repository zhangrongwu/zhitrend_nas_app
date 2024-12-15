import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class OfficePreview extends StatefulWidget {
  final String? url;
  final bool isLocal;

  const OfficePreview({
    super.key,
    required this.url,
    required this.isLocal,
  });

  @override
  State<OfficePreview> createState() => _OfficePreviewState();
}

class _OfficePreviewState extends State<OfficePreview> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 等待一帧以确保widget已经完全构建
      await Future.delayed(Duration.zero);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载文档失败: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocument,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (widget.url == null) {
      return const Center(
        child: Text('无效的文档URL'),
      );
    }

    return SfPdfViewer.network(
      widget.url!,
      key: _pdfViewerKey,
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      pageLayoutMode: PdfPageLayoutMode.continuous,
      scrollDirection: PdfScrollDirection.vertical,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        if (mounted) {
          setState(() {
            _errorMessage = '加载文档失败: ${details.error}';
          });
        }
      },
    );
  }
}
