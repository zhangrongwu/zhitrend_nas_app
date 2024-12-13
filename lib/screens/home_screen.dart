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
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SharesScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: () => _showSortDialog(context),
                  ),
                ],
              ],
            ),
            body: Column(
              children: [
                if (!selectionManager.isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: fileManager.currentPath == '/'
                              ? null
                              : () => fileManager.navigateUp(),
                        ),
                        Expanded(
                          child: Text(
                            fileManager.currentPath,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (fileManager.isLoading)
                  const LinearProgressIndicator()
                else if (fileManager.error != null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${fileManager.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => fileManager.loadFiles(fileManager.currentPath),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => fileManager.loadFiles(fileManager.currentPath),
                      child: ListView.builder(
                        itemCount: fileManager.items.length,
                        itemBuilder: (context, index) {
                          final item = fileManager.items[index];
                          return FileListItem(
                            file: item,
                            onTap: () {
                              if (selectionManager.isSelectionMode) {
                                selectionManager.toggleSelection(item);
                              } else if (item.isDirectory) {
                                fileManager.navigateToDirectory(item.path);
                              } else {
                                _handleItemTap(context, item);
                              }
                            },
                            onShare: () async {
                              final shareLink = await shareService.createShareLink(
                                path: item.path,
                                expirationDays: 7,
                                allowDownload: true,
                              );
                              Share.share(shareLink);
                            },
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete File'),
                                  content: Text(
                                    'Are you sure you want to delete ${item.name}?'
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
                                await fileManager.deleteItem(item);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                const BulkActionBar(),
              ],
            ),
            floatingActionButton: !selectionManager.isSelectionMode
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'upload',
                        onPressed: () => _pickAndUploadFiles(context),
                        child: const Icon(Icons.upload),
                      ),
                      const SizedBox(height: 16),
                      FloatingActionButton(
                        heroTag: 'create_folder',
                        onPressed: () => _showCreateFolderDialog(context),
                        child: const Icon(Icons.create_new_folder),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SortDialog(
        currentSortBy: context.read<FileManager>().sortBy,
        currentSortOrder: context.read<FileManager>().sortOrder,
        onSort: (by, order) {
          context.read<FileManager>().setSort(by, order);
        },
      ),
    );
  }

  Future<void> _handleItemTap(BuildContext context, FileItem item) async {
    if (item.isImage || item.isVideo || item.isPdf || item.isText) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewScreen(file: item),
          ),
        );
      }
    } else {
      // For other file types, show a dialog with options
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(item.name),
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
  }

  Future<void> _pickAndUploadFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        final files = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
        await context.read<FileManager>().uploadFiles(files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading files: $e')),
        );
      }
    }
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateFolderDialog(
        onSubmit: (name) {
          context.read<FileManager>().createDirectory(name);
        },
      ),
    );
  }
}
