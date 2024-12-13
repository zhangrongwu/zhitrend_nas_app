import 'package:flutter/foundation.dart';
import '../models/file_item.dart';

class SelectionManager extends ChangeNotifier {
  final Set<String> _selectedPaths = {};
  bool _isSelectionMode = false;

  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedPaths => Set.unmodifiable(_selectedPaths);
  int get selectedCount => _selectedPaths.length;

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedPaths.clear();
    }
    notifyListeners();
  }

  void toggleSelection(FileItem item) {
    if (_selectedPaths.contains(item.path)) {
      _selectedPaths.remove(item.path);
      if (_selectedPaths.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedPaths.add(item.path);
    }
    notifyListeners();
  }

  void selectAll(List<FileItem> items) {
    _selectedPaths.addAll(items.map((item) => item.path));
    _isSelectionMode = true;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPaths.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  bool isSelected(FileItem item) {
    return _selectedPaths.contains(item.path);
  }
}
