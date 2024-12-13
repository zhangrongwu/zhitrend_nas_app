import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'sync_service.dart';
import '../models/file_item.dart';

class FileManager extends ChangeNotifier {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  final SyncService _syncService;
  
  String _currentPath = '/';
  List<FileItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String _sortBy = 'name';
  String _sortOrder = 'asc';

  FileManager({
    required ApiService apiService,
    required DatabaseService databaseService,
    required SyncService syncService,
  }) : _apiService = apiService,
       _databaseService = databaseService,
       _syncService = syncService {
    refreshCurrentDirectory();
  }

  String get currentPath => _currentPath;
  List<FileItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  Future<void> navigateToDirectory(String path) async {
    await loadFiles(path);
  }

  Future<void> refreshCurrentDirectory() async {
    await loadFiles(_currentPath);
  }

  Future<void> loadFiles(String path) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First try to load from local database
      _items = await _databaseService.getFiles(path);
      _currentPath = path;
      notifyListeners();

      // Then try to sync with server
      if (!_syncService.isSyncing) {
        await _syncService.syncDirectory(path);
        // Reload from database after sync
        _items = await _databaseService.getFiles(path);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> navigateTo(String path) async {
    await loadFiles(path);
  }

  Future<void> navigateUp() async {
    if (_currentPath == '/') return;
    final parentPath = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
    await navigateTo(parentPath.isEmpty ? '/' : parentPath);
  }

  Future<void> createDirectory(String name) async {
    try {
      _error = null;
      notifyListeners();

      await _apiService.createDirectory(_currentPath, name);
      await refreshCurrentDirectory();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteItem(FileItem item) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteFile(item.path);
      await _databaseService.deleteFile(item.path);
      _items.removeWhere((f) => f.path == item.path);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadFile(File file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.uploadFile(_currentPath, file);
      await refreshCurrentDirectory();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadFiles(List<File> files) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      for (final file in files) {
        await _apiService.uploadFile(_currentPath, file);
        
        final fileItem = FileItem(
          name: file.path.split('/').last,
          path: '${_currentPath}/${file.path.split('/').last}',
          isDirectory: false,
          size: await file.length(),
          modifiedTime: await file.lastModified(),
          mimeType: 'application/octet-stream',
        );
        
        await _databaseService.saveFile(fileItem);
      }
      await refreshCurrentDirectory();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> moveItem(String sourcePath, String targetPath) async {
    try {
      _error = null;
      notifyListeners();

      await _apiService.moveItem(sourcePath, targetPath);
      await refreshCurrentDirectory();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> copyItem(String sourcePath, String targetPath) async {
    try {
      _error = null;
      notifyListeners();

      await _apiService.copyItem(sourcePath, targetPath);
      await refreshCurrentDirectory();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setSort(String by, String order) {
    _sortBy = by;
    _sortOrder = order;
    _sortItems();
    notifyListeners();
  }

  void _sortItems() {
    _items.sort((a, b) {
      // Directories always come first
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }

      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'size':
          comparison = a.size.compareTo(b.size);
          break;
        case 'modified':
          comparison = a.modifiedTime.compareTo(b.modifiedTime);
          break;
        default:
          comparison = 0;
      }

      return _sortOrder == 'asc' ? comparison : -comparison;
    });
  }

  Future<FileItem> getFile(String path) async {
    try {
      final file = await _apiService.getFileInfo(path);
      if (file != null) {
        await _databaseService.saveFile(file);
        return file;
      }
      final localFile = await _databaseService.getFile(path);
      if (localFile != null) {
        return localFile;
      }
      throw Exception('File not found: $path');
    } catch (e) {
      debugPrint('Error getting file: $e');
      final localFile = await _databaseService.getFile(path);
      if (localFile != null) {
        return localFile;
      }
      throw Exception('File not found: $path');
    }
  }
}
