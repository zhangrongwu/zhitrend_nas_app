import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import '../services/database_service.dart';
import '../widgets/preview/image_preview.dart';
import '../widgets/preview/video_preview.dart';
import '../widgets/preview/pdf_preview.dart';
import '../widgets/preview/text_preview.dart';
import '../widgets/preview/audio_preview.dart';
import '../widgets/preview/office_preview.dart';
import '../widgets/dialogs/share_dialog.dart';

class PreviewScreen extends StatelessWidget {
  final FileItem file;

  const PreviewScreen({
    super.key,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
        actions: [
          if (!file.isLocal)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(context),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareFile(context),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: _buildPreviewWidget(context),
    );
  }

  Widget _buildPreviewWidget(BuildContext context) {
    final apiService = context.read<ApiService>();
    final databaseService = context.read<DatabaseService>();
    
    String? previewUrl;
    if (file.isLocal && file.localPath != null) {
      previewUrl = 'file://${file.localPath}';
    } else {
      previewUrl = apiService.getPreviewUrl(file.path);
    }

    if (file.isImage) {
      return ImagePreview(
        url: previewUrl,
        isLocal: file.isLocal,
      );
    }

    if (file.isVideo) {
      return VideoPreview(
        url: previewUrl,
        isLocal: file.isLocal,
      );
    }

    if (file.isPdf) {
      return PdfPreview(
        url: previewUrl,
        isLocal: file.isLocal,
      );
    }

    if (file.isText || file.isCode) {
      return TextPreview(
        url: previewUrl,
        isLocal: file.isLocal,
      );
    }

    if (file.isAudio) {
      return AudioPreview(
        url: previewUrl,
        isLocal: file.isLocal,
      );
    }

    if (file.isOffice) {
      return OfficePreview(
        url: previewUrl,
        isLocal: file.isLocal,
      );
    }

    return const Center(
      child: Text('This file type is not supported for preview'),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    final downloadService = context.read<DownloadService>();
    final databaseService = context.read<DatabaseService>();
    
    try {
      final taskId = await downloadService.downloadFile(file);
      if (taskId != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${file.name}...'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 监听下载进度
        downloadService.progress(taskId).listen(
          (progress) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading ${file.name}: ${(progress * 100).toStringAsFixed(1)}%'),
                  duration: const Duration(milliseconds: 500),
                ),
              );
            }
          },
          onDone: () async {
            // 下载完成后更新数据库
            final localPath = await downloadService.getLocalPath(taskId);
            if (localPath != null) {
              final updatedFile = file.copyWith(
                isLocal: true,
                localPath: localPath,
                isSynced: true,
              );
              await databaseService.updateFile(updatedFile);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${file.name} downloaded successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
          onError: (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error downloading file: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareFile(BuildContext context) async {
    final apiService = context.read<ApiService>();
    try {
      final shareUrl = await apiService.createShareLink(file.path);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => ShareDialog(shareUrl: shareUrl),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating share link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('File Info'),
            onTap: () {
              Navigator.pop(context);
              _showFileInfo(context);
            },
          ),
          if (!file.isLocal)
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                _downloadFile(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              _shareFile(context);
            },
          ),
        ],
      ),
    );
  }

  void _showFileInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${file.name}'),
            Text('Size: ${file.sizeString}'),
            Text('Modified: ${file.modifiedString}'),
            Text('Path: ${file.path}'),
            if (file.isLocal) Text('Local Path: ${file.localPath}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
