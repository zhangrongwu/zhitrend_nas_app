import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'package:queue/queue.dart';
import 'dart:convert';
import 'api_service.dart';
import 'database_service.dart';

class BackupService extends ChangeNotifier {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  final Queue _uploadQueue = Queue();
  bool _isBackupEnabled = false;
  bool _isBackupRunning = false;
  DateTime? _lastBackupTime;
  String _backupFolder = '/backup/photos';
  
  BackupService({
    required ApiService apiService,
    required DatabaseService databaseService,
  })  : _apiService = apiService,
        _databaseService = databaseService;

  bool get isBackupEnabled => _isBackupEnabled;
  bool get isBackupRunning => _isBackupRunning;
  DateTime? get lastBackupTime => _lastBackupTime;
  String get backupFolder => _backupFolder;

  // 初始化服务
  Future<void> initialize() async {
    // 从数据库加载配置
    _isBackupEnabled = await _databaseService.getBackupEnabled() ?? false;
    _lastBackupTime = await _databaseService.getLastBackupTime();
    _backupFolder = await _databaseService.getBackupFolder() ?? '/backup/photos';
    
    if (_isBackupEnabled) {
      // 启动定期备份
      _startPeriodicBackup();
    }
  }

  // 设置备份开关
  Future<void> setBackupEnabled(bool enabled) async {
    _isBackupEnabled = enabled;
    await _databaseService.setBackupEnabled(enabled);
    if (enabled) {
      _startPeriodicBackup();
    }
    notifyListeners();
  }

  // 设置备份文件夹
  Future<void> setBackupFolder(String folder) async {
    _backupFolder = folder;
    await _databaseService.setBackupFolder(folder);
    notifyListeners();
  }

  // 开始备份
  Future<void> startBackup() async {
    if (_isBackupRunning) return;
    
    _isBackupRunning = true;
    notifyListeners();

    try {
      // 获取权限
      final permitted = await _requestPermission();
      if (!permitted) {
        throw Exception('未获得相册访问权限');
      }

      // 获取上次备份后的新照片
      final lastBackup = _lastBackupTime ?? DateTime(2000);
      final assets = await _getNewPhotos(lastBackup);
      
      // 开始上传
      for (final asset in assets) {
        final file = await asset.file;
        if (file == null) continue;
        
        // 计算文件哈希
        final hash = await _calculateFileHash(file);
        
        // 检查文件是否已存在
        if (await _databaseService.isFileBackedUp(hash)) {
          continue;
        }

        // 添加到上传队列
        _uploadQueue.add(() async {
          final fileName = path.basename(file.path);
          final targetPath = path.join(_backupFolder, fileName);
          
          await _apiService.uploadFile(
            file.path,
            targetPath,
            onProgress: (progress) {
              // 更新进度
              debugPrint('Backing up $fileName: $progress%');
            },
          );

          // 记录已备份
          await _databaseService.markFileAsBackedUp(hash, targetPath);
        });
      }

      // 更新最后备份时间
      _lastBackupTime = DateTime.now();
      await _databaseService.setLastBackupTime(_lastBackupTime!);
      
    } catch (e) {
      debugPrint('Backup failed: $e');
      rethrow;
    } finally {
      _isBackupRunning = false;
      notifyListeners();
    }
  }

  // 请求权限
  Future<bool> _requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  // 获取新照片
  Future<List<AssetEntity>> _getNewPhotos(DateTime since) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        createTimeCond: DateTimeCond(
          min: since,
          max: DateTime.now(),
        ),
      ),
    );

    final List<AssetEntity> assets = [];
    for (final album in albums) {
      final albumAssets = await album.getAssetListRange(start: 0, end: 1000000);
      assets.addAll(albumAssets);
    }
    
    return assets;
  }

  // 计算文件哈希
  Future<String> _calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  // 启动定期备份
  void _startPeriodicBackup() {
    // TODO: 使用 WorkManager 实现定期备份
  }
}
