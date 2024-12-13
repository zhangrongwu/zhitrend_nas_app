import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/selection_manager.dart';
import 'package:intl/intl.dart';

class FileListItem extends StatelessWidget {
  final FileItem file;
  final VoidCallback onTap;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const FileListItem({
    super.key,
    required this.file,
    required this.onTap,
    this.onShare,
    this.onDelete,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat.Hm().format(date);
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(date);
    } else {
      return DateFormat.yMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionManager>(
      builder: (context, selectionManager, child) {
        final isSelected = selectionManager.isSelected(file);

        return ListTile(
          leading: Stack(
            children: [
              Icon(
                file.isDirectory
                    ? Icons.folder
                    : file.isImage
                        ? Icons.image
                        : file.isVideo
                            ? Icons.video_library
                            : file.isPdf
                                ? Icons.picture_as_pdf
                                : Icons.insert_drive_file,
                color: file.isDirectory ? Colors.amber : null,
              ),
              if (selectionManager.isSelectionMode)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${_formatDate(file.modifiedAt)} - ${file.isDirectory ? "${file.childCount} items" : _formatFileSize(file.size)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: selectionManager.isSelectionMode
              ? null
              : PopupMenuButton(
                  itemBuilder: (context) => [
                    if (onShare != null)
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Share'),
                        ),
                        onTap: onShare,
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                        ),
                        onTap: onDelete,
                      ),
                  ],
                ),
          onTap: selectionManager.isSelectionMode
              ? () => selectionManager.toggleSelection(file)
              : onTap,
          onLongPress: () {
            if (!selectionManager.isSelectionMode) {
              selectionManager.toggleSelectionMode();
              selectionManager.toggleSelection(file);
            }
          },
          selected: isSelected,
        );
      },
    );
  }
}
