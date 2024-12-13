import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImagePreview extends StatelessWidget {
  final String url;
  final bool isLocal;

  const ImagePreview({
    super.key,
    required this.url,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: isLocal 
        ? FileImage(File(url.replaceFirst('file://', ''))) as ImageProvider
        : NetworkImage(url),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2,
      backgroundDecoration: const BoxDecoration(
        color: Colors.black,
      ),
      loadingBuilder: (context, event) => Center(
        child: CircularProgressIndicator(
          value: event == null
              ? 0
              : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
        ),
      ),
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.broken_image,
          size: 64,
          color: Colors.white54,
        ),
      ),
    );
  }
}
