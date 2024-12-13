import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/share_service.dart';
import '../models/file_item.dart';

class ShareDialog extends StatefulWidget {
  final FileItem file;

  const ShareDialog({
    super.key,
    required this.file,
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  int _expirationDays = 7;
  bool _requirePassword = false;
  final TextEditingController _passwordController = TextEditingController();
  bool _allowDownload = true;
  bool _isCreatingLink = false;
  String? _shareLink;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createShareLink() async {
    setState(() {
      _isCreatingLink = true;
      _error = null;
    });

    try {
      final shareService = context.read<ShareService>();
      final link = await shareService.createShareLink(
        path: widget.file.path,
        expirationDays: _expirationDays,
        requirePassword: _requirePassword,
        password: _requirePassword ? _passwordController.text : null,
        allowDownload: _allowDownload,
      );

      setState(() {
        _shareLink = link;
        _isCreatingLink = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCreatingLink = false;
      });
    }
  }

  Future<void> _shareViaSystem() async {
    try {
      final shareService = context.read<ShareService>();
      await shareService.shareViaSystem(widget.file);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share File'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${widget.file.name}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _expirationDays,
              decoration: const InputDecoration(
                labelText: 'Link Expiration',
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 day')),
                DropdownMenuItem(value: 7, child: Text('7 days')),
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: -1, child: Text('Never')),
              ],
              onChanged: (value) {
                setState(() {
                  _expirationDays = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Require Password'),
              value: _requirePassword,
              onChanged: (value) {
                setState(() {
                  _requirePassword = value;
                });
              },
            ),
            if (_requirePassword) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Allow Download'),
              value: _allowDownload,
              onChanged: (value) {
                setState(() {
                  _allowDownload = value;
                });
              },
            ),
            if (_shareLink != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _shareLink!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      // Copy to clipboard
                    },
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _shareViaSystem,
          child: const Text('Share via System'),
        ),
        ElevatedButton(
          onPressed: _isCreatingLink ? null : _createShareLink,
          child: _isCreatingLink
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Link'),
        ),
      ],
    );
  }
}
