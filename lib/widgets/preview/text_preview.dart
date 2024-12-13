import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class TextPreview extends StatefulWidget {
  final String url;
  final bool isLocal;

  const TextPreview({
    super.key,
    required this.url,
    this.isLocal = false,
  });

  @override
  State<TextPreview> createState() => _TextPreviewState();
}

class _TextPreviewState extends State<TextPreview> {
  String? _content;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      String content;
      if (widget.isLocal) {
        final file = File(widget.url.replaceFirst('file://', ''));
        content = await file.readAsString();
      } else {
        final response = await http.get(Uri.parse(widget.url));
        if (response.statusCode == 200) {
          content = response.body;
        } else {
          throw Exception('Failed to load text file');
        }
      }

      if (mounted) {
        setState(() {
          _content = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading text: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_content == null) {
      return const Center(
        child: Text('No content available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _content!,
        style: GoogleFonts.firaCode(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
