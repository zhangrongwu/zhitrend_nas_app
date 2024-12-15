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
  final VoidCallback? onCompress;
  final VoidCallback? onExtract;

  const FileListItem({
    super.key,
    required this.file,
    required this.onTap,
    this.onShare,
    this.onDelete,
    this.onCompress,
    this.onExtract,
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

  Widget _buildSubtitle() {
    final sizeText = file.isDirectory
        ? '${file.childCount} items'
        : _formatFileSize(file.size);
    final dateText = DateFormat('yyyy-MM-dd HH:mm').format(file.modifiedTime);
    return Text('$sizeText • $dateText');
  }

  Widget _buildActionButtons(BuildContext context) {
    final selectionManager = Provider.of<SelectionManager>(context);
    final isSelected = selectionManager.isSelected(file);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 分享按钮
        if (onShare != null && !file.isDirectory)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onShare,
            tooltip: '分享',
          ),

        // 压缩按钮
        if (onCompress != null)
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: onCompress,
            tooltip: '压缩',
          ),

        // 解压按钮
        if (onExtract != null && file.name.toLowerCase().endsWith('.zip'))
          IconButton(
            icon: const Icon(Icons.unarchive),
            onPressed: onExtract,
            tooltip: '解压',
          ),

        // 删除按钮
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: '删除',
          ),

        // 选择按钮
        Checkbox(
          value: isSelected,
          onChanged: (value) {
            if (value == true) {
              selectionManager.select(file);
            } else {
              selectionManager.deselect(file);
            }
          },
        ),
      ],
    );
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
          subtitle: _buildSubtitle(),
          trailing: selectionManager.isSelectionMode
              ? null
              : _buildActionButtons(context),
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
