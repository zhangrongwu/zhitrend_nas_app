import 'package:flutter/material.dart';

class SortDialog extends StatefulWidget {
  final String currentSortBy;
  final String currentSortOrder;
  final Function(String, String) onSort;

  const SortDialog({
    super.key,
    required this.currentSortBy,
    required this.currentSortOrder,
    required this.onSort,
  });

  @override
  State<SortDialog> createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  late String _sortBy;
  late String _sortOrder;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.currentSortBy;
    _sortOrder = widget.currentSortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sort Files'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: const Text('Name'),
            value: 'name',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          RadioListTile<String>(
            title: const Text('Size'),
            value: 'size',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          RadioListTile<String>(
            title: const Text('Modified Date'),
            value: 'modified',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Ascending'),
                  value: 'asc',
                  groupValue: _sortOrder,
                  onChanged: (value) => setState(() => _sortOrder = value!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Descending'),
                  value: 'desc',
                  groupValue: _sortOrder,
                  onChanged: (value) => setState(() => _sortOrder = value!),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onSort(_sortBy, _sortOrder);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
