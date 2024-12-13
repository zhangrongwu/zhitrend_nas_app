import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:synchronized/synchronized.dart';
import '../models/file_item.dart';
import 'api_service.dart';
import 'database_service.dart';

class SyncService extends ChangeNotifier {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  final Lock _lock = Lock();
  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  SyncService({
    required ApiService apiService,
    required DatabaseService databaseService,
  })  : _apiService = apiService,
        _databaseService = databaseService {
    _initSync();
  }

  bool get isSyncing => _isSyncing;

  Future<void> initialize() async {
    // 初始化时执行一次同步
    await syncAll();
  }

  void _initSync() {
    // 监听网络连接状态
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncAll();
      }
    });

    // 定期同步
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      syncAll();
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;

    await _lock.synchronized(() async {
      try {
        _isSyncing = true;
        notifyListeners();

        // 获取所有未同步的文件
        final unsyncedFiles = await _databaseService.getUnsyncedFiles();
        for (final file in unsyncedFiles) {
          await syncFile(file);
        }
      } finally {
        _isSyncing = false;
        notifyListeners();
      }
    });
  }

  Future<void> syncDirectory(String path) async {
    if (_isSyncing) return;

    await _lock.synchronized(() async {
      try {
        _isSyncing = true;
        notifyListeners();

        // 从服务器获取目录内容
        final serverFiles = await _apiService.listFiles(path);
        final localFiles = await _databaseService.getFiles(path);

        // 创建查找映射以提高效率
        final serverFileMap = {for (var file in serverFiles) file.path: file};
        final localFileMap = {for (var file in localFiles) file.path: file};

        // 更新或添加服务器上的文件
        for (final serverFile in serverFiles) {
          final localFile = localFileMap[serverFile.path];
          if (localFile == null) {
            // 新文件，添加到数据库
            await _databaseService.insertFile(serverFile);
          } else if (serverFile.modifiedTime != localFile.modifiedTime) {
            // 文件已更新，更新数据库
            final updatedFile = localFile.copyWith(
              modifiedTime: serverFile.modifiedTime,
              size: serverFile.size,
              isSynced: false,
            );
            await _databaseService.updateFile(updatedFile);
          }
        }

        // 删除已不存在的文件
        for (final localFile in localFiles) {
          if (!serverFileMap.containsKey(localFile.path)) {
            await _databaseService.deleteFile(localFile.path);
          }
        }

        // 如果是目录，递归同步子目录
        for (final file in serverFiles) {
          if (file.isDirectory) {
            await syncDirectory(file.path);
          }
        }
      } finally {
        _isSyncing = false;
        notifyListeners();
      }
    });
  }

  Future<void> syncFile(FileItem file) async {
    try {
      if (!file.isSynced) {
        final serverFile = await _apiService.getFileInfo(file.path);
        if (serverFile != null) {
          final updatedFile = file.copyWith(
            modifiedTime: serverFile.modifiedTime,
            size: serverFile.size,
            isSynced: true,
          );
          await _databaseService.updateFile(updatedFile);
        }
      }
    } catch (e) {
      debugPrint('Error syncing file ${file.path}: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
