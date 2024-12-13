import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/search_service.dart';
import '../widgets/file_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FileItem> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  List<String> _selectedFileTypes = [];
  DateTime? _startDate;
  DateTime? _endDate;
  int? _minSize;
  int? _maxSize;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final searchService = context.read<SearchService>();
      final results = await searchService.searchFiles(
        query: _searchController.text,
        fileTypes: _selectedFileTypes.isNotEmpty ? _selectedFileTypes : null,
        startDate: _startDate,
        endDate: _endDate,
        minSize: _minSize,
        maxSize: _maxSize,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Filters'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFileTypeFilter(),
              const SizedBox(height: 16),
              _buildDateFilter(),
              const SizedBox(height: 16),
              _buildSizeFilter(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTypeFilter() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('Images'),
          selected: _selectedFileTypes.contains('image'),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedFileTypes.add('image');
              } else {
                _selectedFileTypes.remove('image');
              }
            });
          },
        ),
        FilterChip(
          label: const Text('Videos'),
          selected: _selectedFileTypes.contains('video'),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedFileTypes.add('video');
              } else {
                _selectedFileTypes.remove('video');
              }
            });
          },
        ),
        FilterChip(
          label: const Text('Documents'),
          selected: _selectedFileTypes.contains('document'),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedFileTypes.add('document');
              } else {
                _selectedFileTypes.remove('document');
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _startDate = date);
              }
            },
            child: Text(_startDate?.toString().split(' ')[0] ?? 'Start Date'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _endDate = date);
              }
            },
            child: Text(_endDate?.toString().split(' ')[0] ?? 'End Date'),
          ),
        ),
      ],
    );
  }

  Widget _buildSizeFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Min Size (MB)',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _minSize = int.tryParse(value)?.toInt();
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Max Size (MB)',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _maxSize = int.tryParse(value)?.toInt();
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search files...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ),
          onSubmitted: (_) => _performSearch(),
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading)
            const LinearProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return FileListItem(
                    file: _searchResults[index],
                    onTap: () {
                      // Handle file tap
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
