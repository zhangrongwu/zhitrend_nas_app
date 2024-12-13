import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/share_service.dart';
import 'package:intl/intl.dart';

class SharesScreen extends StatefulWidget {
  const SharesScreen({super.key});

  @override
  State<SharesScreen> createState() => _SharesScreenState();
}

class _SharesScreenState extends State<SharesScreen> {
  List<ShareInfo>? _shares;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  Future<void> _loadShares() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shareService = context.read<ShareService>();
      final shares = await shareService.getSharedFiles();
      setState(() {
        _shares = shares;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeShare(ShareInfo share) async {
    try {
      final shareService = context.read<ShareService>();
      await shareService.removeShare(share.id);
      _loadShares();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShares,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadShares,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_shares == null || _shares!.isEmpty) {
      return const Center(
        child: Text('No shared files'),
      );
    }

    return ListView.builder(
      itemCount: _shares!.length,
      itemBuilder: (context, index) {
        final share = _shares![index];
        return _buildShareItem(share);
      },
    );
  }

  Widget _buildShareItem(ShareInfo share) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(share.path.split('/').last),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Created: ${dateFormat.format(share.createdAt)}'),
            if (share.expiresAt != null)
              Text('Expires: ${dateFormat.format(share.expiresAt!)}'),
            Row(
              children: [
                if (share.requirePassword)
                  Icon(Icons.lock, size: 16, color: theme.colorScheme.secondary),
                if (share.allowDownload)
                  Icon(Icons.download, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text('Accessed: ${share.accessCount} times'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.copy),
                title: Text('Copy Link'),
              ),
              onTap: () {
                // Copy to clipboard
              },
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
              ),
              onTap: () {
                // Share via system
              },
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.delete),
                title: Text('Remove'),
              ),
              onTap: () => _removeShare(share),
            ),
          ],
        ),
      ),
    );
  }
}
