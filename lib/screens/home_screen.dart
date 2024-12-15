import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/file_manager.dart';
import '../services/selection_manager.dart';
import '../models/file_item.dart';
import '../widgets/file_list_item.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/sort_dialog.dart';
import '../widgets/create_folder_dialog.dart';
import '../widgets/share_dialog.dart';
import '../widgets/bulk_action_bar.dart';
import 'preview_screen.dart';
import 'search_screen.dart';
import 'shares_screen.dart';
import '../services/share_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectionManager(),
      child: Consumer3<FileManager, SelectionManager, ShareService>(
        builder: (context, fileManager, selectionManager, shareService, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('ZhiTrend NAS'),
              leading: selectionManager.isSelectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: selectionManager.clearSelection,
                    )
                  : null,
              actions: [
                if (selectionManager.isSelectionMode) ...[
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: () => selectionManager.selectAll(fileManager.items),
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive),
                    onPressed: () => _handleCompress(
                      context,
                      selectionManager.selectedItems
                          .map((item) => item.path)
                          .toList(),
                    ),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const SortDialog(),
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'create_folder',
                        child: Text('新建文件夹'),
                      ),
                      const PopupMenuItem(
                        value: 'upload',
                        child: Text('上传文件'),
                      ),
                    ],
                    onSelected: (value) async {
                      switch (value) {
                        case 'create_folder':
                          showDialog(
                            context: context,
                            builder: (context) => const CreateFolderDialog(),
                          );
                          break;
                        case 'upload':
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: true,
                          );
                          if (result != null) {
                            for (final file in result.files) {
                              if (file.path != null) {
                                await fileManager.uploadFile(File(file.path!));
                              }
                            }
                          }
                          break;
                      }
                    },
                  ),
                ],
              ],
            ),
            body: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => fileManager.refresh(),
                  child: ListView.builder(
                    itemCount: fileManager.items.length,
                    itemBuilder: (context, index) {
                      final file = fileManager.items[index];
                      return FileListItem(
                        file: file,
                        onTap: () => _handleFileTap(context, file),
                        onShare: () => _handleShare(context, file),
                        onDelete: () => _handleDelete(context, file),
                        onCompress: () => _handleCompress(context, [file.path]),
                        onExtract: file.name.toLowerCase().endsWith('.zip')
                            ? () => _handleExtract(context, file)
                            : null,
                      );
                    },
                  ),
                ),
                if (fileManager.isLoading) const LoadingOverlay(),
              ],
            ),
            bottomNavigationBar: selectionManager.isSelectionMode
                ? const BulkActionBar()
                : null,
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                );
                if (result != null) {
                  for (final file in result.files) {
                    if (file.path != null) {
                      await fileManager.uploadFile(File(file.path!));
                    }
                  }
                }
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleShare(BuildContext context, FileItem file) async {
    try {
      final shareService = Provider.of<ShareService>(context, listen: false);
      final result = await shareService.createShareLink(file.path);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => ShareDialog(
          shareUrl: result['share_url'],
          expiresAt: DateTime.parse(result['expires_at']),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(message: '创建分享链接失败: $e'),
      );
    }
  }

  Future<void> _handleCompress(BuildContext context, List<String> paths) async {
    try {
      final fileManager = Provider.of<FileManager>(context, listen: false);
      final archiveName = 'archive_${DateTime.now().millisecondsSinceEpoch}.zip';
      
      await fileManager.compressFiles(paths, archiveName);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件压缩完成')),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(message: '压缩文件失败: $e'),
      );
    }
  }

  Future<void> _handleExtract(BuildContext context, FileItem file) async {
    try {
      final fileManager = Provider.of<FileManager>(context, listen: false);
      await fileManager.extractArchive(file.path);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件解压完成')),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(message: '解压文件失败: $e'),
      );
    }
  }

  void _handleFileTap(BuildContext context, FileItem file) {
    if (file.isImage || file.isVideo || file.isPdf || file.isText) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(file: file),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(file.name),
          content: const Text('This file type cannot be previewed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement download functionality
                Navigator.pop(context);
              },
              child: const Text('Download'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, FileItem file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
          'Are you sure you want to delete ${file.name}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<FileManager>(context, listen: false).deleteItem(file);
    }
  }
}
