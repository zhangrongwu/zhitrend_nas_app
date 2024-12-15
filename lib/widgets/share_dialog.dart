import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ShareDialog extends StatelessWidget {
  final String shareUrl;
  final DateTime expiresAt;

  const ShareDialog({
    super.key,
    required this.shareUrl,
    required this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('分享链接'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('分享链接已创建：'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shareUrl,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('链接已复制到剪贴板')),
                    );
                  },
                  tooltip: '复制链接',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '过期时间：${DateFormat('yyyy-MM-dd HH:mm').format(expiresAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: () {
            Share.share(shareUrl);
          },
          icon: const Icon(Icons.share),
          label: const Text('分享'),
        ),
      ],
    );
  }
}
