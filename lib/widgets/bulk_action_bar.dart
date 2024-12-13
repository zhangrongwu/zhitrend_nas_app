import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/selection_manager.dart';
import '../services/file_manager.dart';
import '../services/share_service.dart';
import '../models/file_item.dart';

class BulkActionBar extends StatelessWidget {
  const BulkActionBar({super.key});

  Future<void> _handleDelete(BuildContext context) async {
    final selectionManager = context.read<SelectionManager>();
    final fileManager = context.read<FileManager>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Files'),
        content: Text(
          'Are you sure you want to delete ${selectionManager.selectedCount} items?'
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

    if (confirmed == true && context.mounted) {
      try {
        for (var path in selectionManager.selectedPaths) {
          try {
            final file = await fileManager.getFile(path);
            await fileManager.deleteItem(file);
          } catch (e) {
            debugPrint('Error deleting file $path: $e');
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Items deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting items: $e')),
          );
        }
      } finally {
        selectionManager.clearSelection();
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    final selectionManager = context.read<SelectionManager>();
    final fileManager = context.read<FileManager>();
    final shareService = context.read<ShareService>();

    try {
      final files = <FileItem>[];
      for (var path in selectionManager.selectedPaths) {
        try {
          final file = await fileManager.getFile(path);
          files.add(file);
        } catch (e) {
          debugPrint('Error getting file $path: $e');
        }
      }
      
      if (files.isNotEmpty) {
        await shareService.shareFiles(files);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing files: $e')),
        );
      }
    }
  }

  Future<void> _handleMove(BuildContext context) async {
    // TODO: Implement move functionality
  }

  Future<void> _handleCopy(BuildContext context) async {
    // TODO: Implement copy functionality
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionManager>(
      builder: (context, selectionManager, child) {
        if (!selectionManager.isSelectionMode) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Theme.of(context).primaryColor,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        '${selectionManager.selectedCount} selected',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: selectionManager.clearSelection,
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text('Share', style: TextStyle(color: Colors.white)),
                        onPressed: () => _handleShare(context),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text('Delete', style: TextStyle(color: Colors.white)),
                        onPressed: () => _handleDelete(context),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.drive_file_move, color: Colors.white),
                        label: const Text('Move', style: TextStyle(color: Colors.white)),
                        onPressed: () => _handleMove(context),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        label: const Text('Copy', style: TextStyle(color: Colors.white)),
                        onPressed: () => _handleCopy(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
