import 'package:flutter/material.dart';

class CreateFolderDialog extends StatefulWidget {
  final Function(String) onSubmit;

  const CreateFolderDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
  }

  void _validateInput() {
    setState(() {
      _isValid = _controller.text.trim().isNotEmpty &&
          !_controller.text.contains('/') &&
          !_controller.text.contains('\\');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Folder'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Folder name',
          errorText: 'Please enter a valid folder name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isValid
              ? () {
                  widget.onSubmit(_controller.text.trim());
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
